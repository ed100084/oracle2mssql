"""Dependency analysis and topological sort for deployment ordering."""
import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

import networkx as nx

from .config import AppConfig
from .extractor import load_manifest
from .utils import ensure_dir, write_file, sanitize_name

logger = logging.getLogger("ora2mssql")


@dataclass
class DeployItem:
    wave: int
    owner: str
    name: str
    object_type: str
    target_schema: str
    target_name: str
    is_stub: bool = False


@dataclass
class AnalysisResult:
    deploy_order: list[DeployItem] = field(default_factory=list)
    cycles: list[list[str]] = field(default_factory=list)
    schemas_needed: set[str] = field(default_factory=set)
    errors: list[str] = field(default_factory=list)


def build_dependency_graph(manifest: dict) -> nx.DiGraph:
    """Build directed dependency graph from manifest data."""
    G = nx.DiGraph()

    # Add nodes for all objects
    for obj in manifest["objects"]:
        node_id = f"{obj['owner']}.{obj['name']}.{obj['type']}"
        G.add_node(node_id, **obj)

    # PACKAGE BODY always depends on its PACKAGE (spec)
    objects_by_key = {}
    for obj in manifest["objects"]:
        key = (obj["owner"], obj["name"])
        objects_by_key.setdefault(key, []).append(obj["type"])

    for (owner, name), types in objects_by_key.items():
        if "PACKAGE" in types and "PACKAGE BODY" in types:
            spec_id = f"{owner}.{name}.PACKAGE"
            body_id = f"{owner}.{name}.PACKAGE BODY"
            G.add_edge(body_id, spec_id)  # body depends on spec

    # Add dependency edges
    for dep in manifest["dependencies"]:
        src = f"{dep['owner']}.{dep['name']}.{dep['object_type']}"
        tgt = f"{dep['referenced_owner']}.{dep['referenced_name']}.{dep['referenced_type']}"
        if src in G and tgt in G and src != tgt:
            G.add_edge(src, tgt)  # src depends on tgt

    logger.info(f"Dependency graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")
    return G


def detect_cycles(G: nx.DiGraph) -> list[list[str]]:
    """Detect circular dependencies."""
    cycles = list(nx.simple_cycles(G))
    if cycles:
        logger.warning(f"Found {len(cycles)} circular dependencies")
        for i, cycle in enumerate(cycles[:10]):
            logger.warning(f"  Cycle {i+1}: {' -> '.join(cycle)}")
    else:
        logger.info("No circular dependencies found")
    return cycles


def resolve_cycles(G: nx.DiGraph, cycles: list[list[str]]) -> nx.DiGraph:
    """Break cycles by removing BODY->BODY edges (use stub pattern).

    Returns a modified copy of the graph.
    """
    G2 = G.copy()
    edges_removed = set()

    for cycle in cycles:
        # Find an edge between two BODY nodes to break
        for i in range(len(cycle)):
            src = cycle[i]
            tgt = cycle[(i + 1) % len(cycle)]
            if "PACKAGE BODY" in src and G2.has_edge(src, tgt):
                edge_key = (src, tgt)
                if edge_key not in edges_removed:
                    G2.remove_edge(src, tgt)
                    edges_removed.add(edge_key)
                    logger.info(f"Broke cycle: removed edge {src} -> {tgt}")
                    break

    return G2


def compute_deploy_order(
    G: nx.DiGraph, manifest: dict, schema_mapping: dict[str, str]
) -> list[DeployItem]:
    """Compute deployment order using topological sort."""
    deploy_items = []

    # Collect all schemas needed
    schemas_needed = set()

    # Topological sort (reversed because edges point to dependencies)
    try:
        sorted_nodes = list(reversed(list(nx.topological_sort(G))))
    except nx.NetworkXUnfeasible:
        logger.error("Graph has unresolvable cycles after cycle breaking!")
        sorted_nodes = list(G.nodes())

    # Wave 0: CREATE SCHEMA statements (derived from package names)
    for obj in manifest["objects"]:
        if obj["type"] in ("PACKAGE", "PACKAGE BODY"):
            pkg_name = obj["name"]
            schema = schema_mapping.get(pkg_name, sanitize_name(pkg_name))
            schemas_needed.add(schema)

    for schema in sorted(schemas_needed):
        deploy_items.append(DeployItem(
            wave=0, owner="", name="", object_type="SCHEMA",
            target_schema=schema, target_name=schema,
        ))

    # Wave 1: Stubs (for all procedures/functions from packages)
    for node_id in sorted_nodes:
        parts = node_id.split(".", 2)
        owner, name, obj_type = parts[0], parts[1], parts[2]

        if obj_type == "PACKAGE BODY":
            schema = schema_mapping.get(name, sanitize_name(name))
            deploy_items.append(DeployItem(
                wave=1, owner=owner, name=name, object_type=obj_type,
                target_schema=schema, target_name=name,
                is_stub=True,
            ))

    # Wave 2+: Real bodies in topological order
    wave = 2
    for node_id in sorted_nodes:
        parts = node_id.split(".", 2)
        owner, name, obj_type = parts[0], parts[1], parts[2]

        # Skip PACKAGE specs (they are structural, not deployed separately)
        if obj_type == "PACKAGE":
            continue

        if obj_type == "PACKAGE BODY":
            schema = schema_mapping.get(name, sanitize_name(name))
        else:
            schema = "dbo"

        deploy_items.append(DeployItem(
            wave=wave, owner=owner, name=name, object_type=obj_type,
            target_schema=schema, target_name=name,
            is_stub=False,
        ))

    return deploy_items


def run_analyze(config: AppConfig) -> AnalysisResult:
    """Run dependency analysis pipeline."""
    result = AnalysisResult()
    output_dir = Path(config.conversion.output_dir)

    try:
        manifest = load_manifest(output_dir)
    except FileNotFoundError as e:
        result.errors.append(str(e))
        logger.error(str(e))
        return result

    # Build graph
    G = build_dependency_graph(manifest)

    # Detect cycles
    result.cycles = detect_cycles(G)

    # Break cycles if any
    if result.cycles:
        G = resolve_cycles(G, result.cycles)

    # Compute deploy order
    result.deploy_order = compute_deploy_order(
        G, manifest, config.conversion.schema_mapping
    )

    # Collect schemas
    result.schemas_needed = {
        item.target_schema for item in result.deploy_order if item.object_type == "SCHEMA"
    }

    # Save deploy order
    analysis_dir = ensure_dir(output_dir / "analysis")
    deploy_data = {
        "deploy_order": [
            {
                "wave": item.wave,
                "owner": item.owner,
                "name": item.name,
                "object_type": item.object_type,
                "target_schema": item.target_schema,
                "target_name": item.target_name,
                "is_stub": item.is_stub,
            }
            for item in result.deploy_order
        ],
        "cycles_found": len(result.cycles),
        "cycles": [list(c) for c in result.cycles[:20]],
        "schemas_needed": sorted(result.schemas_needed),
    }
    deploy_path = analysis_dir / "deploy_order.json"
    write_file(deploy_path, json.dumps(deploy_data, indent=2, ensure_ascii=False))
    logger.info(f"Deploy order saved to {deploy_path}")
    logger.info(f"Total deploy items: {len(result.deploy_order)}, Schemas: {len(result.schemas_needed)}")

    return result
