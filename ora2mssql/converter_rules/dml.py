"""DML/DDL-specific transformation rules."""
import re
from ..converter import ConversionRule, ConversionContext, MANUAL_REVIEW_TAG


class DmlRule(ConversionRule):
    name = "dml"
    order = 70

    def apply(self, source: str, ctx: ConversionContext) -> str:
        result = source

        # FROM DUAL → remove (T-SQL doesn't need FROM for scalar SELECT)
        result = re.sub(r'\s+FROM\s+DUAL\b', '', result, flags=re.IGNORECASE)

        # Sequence: seq.NEXTVAL → NEXT VALUE FOR seq
        result = re.sub(
            r'\b(\w+)\.NEXTVAL\b',
            r'NEXT VALUE FOR \1',
            result, flags=re.IGNORECASE
        )

        # Sequence: seq.CURRVAL → @seq_currval (needs variable)
        result = self._convert_currval(result, ctx)

        # RETURNING ... INTO → OUTPUT ... INTO
        result = self._convert_returning_into(result, ctx)

        # MERGE: Oracle MERGE is mostly compatible but check ON clause
        # No changes needed for basic MERGE

        # COMMIT / ROLLBACK - pass through but note implicit transactions
        if re.search(r'\bCOMMIT\b', result, re.IGNORECASE):
            ctx.add_warning("Explicit COMMIT found - verify transaction boundaries in MSSQL context")

        # SAVEPOINT name → SAVE TRANSACTION name
        result = re.sub(
            r'\bSAVEPOINT\s+(\w+)\s*;',
            r'SAVE TRANSACTION \1;',
            result, flags=re.IGNORECASE
        )

        # ROLLBACK TO SAVEPOINT name → ROLLBACK TRANSACTION name
        result = re.sub(
            r'\bROLLBACK\s+TO\s+(?:SAVEPOINT\s+)?(\w+)\s*;',
            r'ROLLBACK TRANSACTION \1;',
            result, flags=re.IGNORECASE
        )

        # DBMS_LOB operations → T-SQL equivalents
        result = self._convert_dbms_lob(result, ctx)

        # DBMS_LOCK.SLEEP → WAITFOR DELAY
        result = re.sub(
            r'\bDBMS_LOCK\.SLEEP\s*\(\s*(\d+)\s*\)\s*;',
            lambda m: f"WAITFOR DELAY '{self._seconds_to_delay(int(m.group(1)))}';",
            result, flags=re.IGNORECASE
        )

        # UTL_FILE operations → flag for manual review
        if re.search(r'\bUTL_FILE\b', result, re.IGNORECASE):
            ctx.add_manual_review("UTL_FILE operations need manual conversion (use xp_cmdshell or OPENROWSET)")

        # AUTONOMOUS_TRANSACTION → flag
        if re.search(r'\bAUTONOMOUS_TRANSACTION\b', result, re.IGNORECASE):
            ctx.add_manual_review(
                "PRAGMA AUTONOMOUS_TRANSACTION - no direct equivalent. "
                "Consider: linked server loopback, Service Broker, or restructure logic."
            )

        # DBMS_SQL → sp_executesql
        result = re.sub(
            r'\bDBMS_SQL\b',
            f'/* {MANUAL_REVIEW_TAG} DBMS_SQL → sp_executesql */ sp_executesql',
            result, flags=re.IGNORECASE
        )

        # Oracle outer-join syntax: table.col (+) → remove (+), flag for manual review.
        # Cannot auto-convert to LEFT JOIN without full SQL parse; mark for manual fix.
        result = re.sub(
            r'\(\s*\+\s*\)',
            f'/* {MANUAL_REVIEW_TAG} (+) outer join — convert to LEFT JOIN manually */',
            result, flags=re.IGNORECASE
        )

        return result

    def _convert_currval(self, source: str, ctx: ConversionContext) -> str:
        """Convert seq.CURRVAL to local variable pattern."""
        pattern = re.compile(r'\b(\w+)\.CURRVAL\b', re.IGNORECASE)

        found_seqs = set()
        def replace_currval(m):
            seq_name = m.group(1)
            found_seqs.add(seq_name)
            return f"@{seq_name}_currval"

        result = pattern.sub(replace_currval, source)

        if found_seqs:
            ctx.add_warning(
                f"CURRVAL used for sequences: {', '.join(found_seqs)}. "
                f"Store NEXT VALUE FOR result in @variable before referencing."
            )

        return result

    def _convert_returning_into(self, source: str, ctx: ConversionContext) -> str:
        """Convert INSERT...RETURNING col INTO var → INSERT...OUTPUT INSERTED.col."""
        pattern = re.compile(
            r'\bRETURNING\s+(.+?)\s+INTO\s+(.+?)\s*;',
            re.IGNORECASE
        )

        def replace_returning(m):
            columns = m.group(1).strip()
            variables = m.group(2).strip()

            # Convert column references to INSERTED.col
            output_cols = ", ".join(
                f"INSERTED.{c.strip()}" for c in columns.split(",")
            )

            ctx.add_manual_review(
                f"RETURNING INTO → OUTPUT clause. Variables: {variables}"
            )

            return (
                f"OUTPUT {output_cols} INTO @output_table;\n"
                f"    SELECT {variables} = /* read from @output_table */;"
            )

        return pattern.sub(replace_returning, source)

    def _convert_dbms_lob(self, source: str, ctx: ConversionContext) -> str:
        """Convert common DBMS_LOB operations."""
        # DBMS_LOB.GETLENGTH → DATALENGTH or LEN
        result = re.sub(
            r'\bDBMS_LOB\.GETLENGTH\s*\((.+?)\)',
            r'DATALENGTH(\1)',
            source, flags=re.IGNORECASE
        )

        # DBMS_LOB.SUBSTR → SUBSTRING
        result = re.sub(
            r'\bDBMS_LOB\.SUBSTR\s*\((.+?),\s*(.+?),\s*(.+?)\)',
            r'SUBSTRING(\1, \3, \2)',
            result, flags=re.IGNORECASE
        )

        # DBMS_LOB.INSTR → CHARINDEX
        result = re.sub(
            r'\bDBMS_LOB\.INSTR\s*\((.+?),\s*(.+?)\)',
            r'CHARINDEX(\2, \1)',
            result, flags=re.IGNORECASE
        )

        # DBMS_LOB.APPEND → += or SET @lob = @lob + @chunk
        result = re.sub(
            r'\bDBMS_LOB\.APPEND\s*\((.+?),\s*(.+?)\)\s*;',
            r'SET \1 = \1 + \2;',
            result, flags=re.IGNORECASE
        )

        # Other DBMS_LOB operations → flag
        if re.search(r'\bDBMS_LOB\.\w+', result, re.IGNORECASE):
            ctx.add_manual_review("DBMS_LOB operation - verify conversion")

        return result

    def _seconds_to_delay(self, seconds: int) -> str:
        """Convert seconds to HH:MM:SS format for WAITFOR DELAY."""
        h = seconds // 3600
        m = (seconds % 3600) // 60
        s = seconds % 60
        return f"{h:02d}:{m:02d}:{s:02d}"
