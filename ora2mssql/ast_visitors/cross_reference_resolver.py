"""Resolve cross-package calls: pkg_name.proc_name → [schema].[proc_name]"""
import re


class CrossReferenceResolver:
    """
    Rewrites package-qualified calls.

    Oracle:   EHRPHRA3_PKG.some_proc(...)
    T-SQL:    [EHRPHRA3_PKG].[some_proc](...)

    Also handles package-level constants/variables referenced as PKG.VAR.
    """

    def __init__(self, known_packages: list[str]):
        self.known_packages = {p.upper() for p in known_packages}

    def resolve(self, tsql: str) -> str:
        """Apply cross-reference rewrites to a T-SQL string."""

        def replace_pkg_ref(m: re.Match) -> str:
            pkg = m.group(1)
            obj = m.group(2)
            if pkg.upper() in self.known_packages:
                return f"[{pkg}].[{obj}]"
            return m.group(0)  # not a known package, leave as-is

        # Match IDENTIFIER.IDENTIFIER (not inside brackets already)
        pattern = r'\b([A-Za-z_][A-Za-z0-9_$#]*)\.([A-Za-z_][A-Za-z0-9_$#]*)\b'
        result = re.sub(pattern, replace_pkg_ref, tsql)
        return result
