"""Configuration management with Pydantic models."""
import os
from pathlib import Path
from typing import Optional

import yaml
from pydantic import BaseModel, field_validator


class OracleConfig(BaseModel):
    host: str
    port: int = 1521
    sid: str
    user: str
    password: str
    mode: Optional[str] = None

    @field_validator("password", mode="before")
    @classmethod
    def resolve_env_var(cls, v):
        if isinstance(v, str) and v.startswith("${") and v.endswith("}"):
            env_key = v[2:-1]
            return os.environ.get(env_key, v)
        return v

    @property
    def dsn(self) -> str:
        return f"{self.host}:{self.port}/{self.sid}"


class MssqlConfig(BaseModel):
    host: str
    port: int = 1433
    database: str
    user: str
    password: str
    driver: str = "ODBC Driver 17 for SQL Server"

    @field_validator("password", mode="before")
    @classmethod
    def resolve_env_var(cls, v):
        if isinstance(v, str) and v.startswith("${") and v.endswith("}"):
            env_key = v[2:-1]
            return os.environ.get(env_key, v)
        return v

    @property
    def connection_string(self) -> str:
        return (
            f"DRIVER={{{self.driver}}};"
            f"SERVER={self.host},{self.port};"
            f"DATABASE={self.database};"
            f"UID={self.user};"
            f"PWD={self.password};"
            f"TrustServerCertificate=yes"
        )


class ConversionConfig(BaseModel):
    source_schemas: list[str] = ["HRP"]
    schema_mapping: dict[str, str] = {}
    skip_objects: list[str] = []
    include_objects: list[str] = []
    output_dir: str = "output"


class TestingConfig(BaseModel):
    mode: str = "syntax"
    max_compare_rows: int = 1000


class AppConfig(BaseModel):
    oracle: OracleConfig
    mssql: MssqlConfig
    conversion: ConversionConfig = ConversionConfig()
    testing: TestingConfig = TestingConfig()


def load_config(config_path: str = "config.yaml") -> AppConfig:
    """Load configuration from YAML file."""
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {config_path}")

    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    return AppConfig(**data)
