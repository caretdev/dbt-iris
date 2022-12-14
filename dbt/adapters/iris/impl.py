from typing import Optional, List
import agate
from dbt.exceptions import invalid_type_error
from dbt.exceptions import RuntimeException
from dbt.adapters.base.relation import BaseRelation  # type: ignore

from dbt.adapters.sql import SQLAdapter  # type: ignore
from dbt.events import AdapterLogger

from dbt.adapters.iris import IRISConnectionManager
from dbt.adapters.iris import IRISColumn
from dbt.adapters.iris import IRISRelation

LIST_SCHEMAS_MACRO_NAME = "list_schemas"
LIST_RELATIONS_MACRO_NAME = "list_relations_without_caching"

logger = AdapterLogger("iris")


class IRISAdapter(SQLAdapter):
    """
    Controls actual implmentation of adapter, and ability to override certain methods.
    """

    Relation = IRISRelation
    Column = IRISColumn
    ConnectionManager = IRISConnectionManager

    @classmethod
    def date_function(cls):
        """
        Returns canonical date func
        """
        return "datenow()"

    @classmethod
    def convert_text_type(cls, agate_table, col_idx):
        column = agate_table.columns[col_idx]
        lens = (len(d.encode("utf-8")) for d in column.values_without_nulls())
        max_len = max(lens) if lens else 64
        length = max_len if max_len > 16 else 16
        return "varchar({})".format(length)

    @classmethod
    def convert_boolean_type(cls, agate_table: agate.Table, col_idx: int) -> str:
        return "bit"

    @classmethod
    def convert_datetime_type(cls, agate_table: agate.Table, col_idx: int) -> str:
        return "timestamp"

    def timestamp_add_sql(self, add_to: str, number: int = 1, interval: str = "hour") -> str:
        return f"dateadd('{interval}', {number}, {add_to})"

    def create_schema(self, schema_relation: BaseRelation) -> None:
        self.execute_macro("create_function_hash", kwargs={})

    def drop_schema(self, schema_relation) -> None:
        try:
            relations = self.list_relations_without_caching(schema_relation)
            for relation in relations:
                self.drop_relation(relation)
            self.commit_if_has_connection()
            self.cache.drop_schema(schema_relation.database, schema_relation.schema)
        except Exception:
            raise

    def check_schema_exists(self, database, schema):
        results = self.execute_macro(LIST_SCHEMAS_MACRO_NAME, kwargs={"database": database})

        exists = True if schema in [row[0] for row in results] else False
        return exists

    def list_relations_without_caching(self, schema_relation: IRISRelation) -> List[IRISRelation]:  # type: ignore
        kwargs = {"schema_relation": schema_relation}
        try:
            results = self.execute_macro(LIST_RELATIONS_MACRO_NAME, kwargs=kwargs)
        except RuntimeException as e:
            errmsg = getattr(e, "msg", "")
            if f"IRIS schema '{schema_relation}' not found" in errmsg:
                return []
            else:
                description = "Error while retrieving information about"
                logger.debug(f"{description} {schema_relation}: {e.msg}")
                return []

        relations = []
        for row in results:
            if len(row) != 4:
                raise RuntimeException(
                    "Invalid value from "
                    f'"iris__list_relations_without_caching({kwargs})", '
                    f"got {len(row)} values, expected 4"
                )
            _, name, _schema, relation_type = row
            relation = self.Relation.create(schema=_schema, identifier=name, type=relation_type)
            relations.append(relation)
        return relations

    def get_rows_different_sql(
        self,
        relation_a: BaseRelation,
        relation_b: BaseRelation,
        column_names: Optional[List[str]] = None,
        except_operator: str = "EXCEPT",
    ) -> str:
        # TODO: IRIS does not support WITH and EXCEPT, no idea how to implement it, yet
        return "SELECT 0,0"

    def get_relation(self, database: str, schema: str, identifier: str) -> Optional[IRISRelation]:  # type: ignore
        if not self.Relation.include_policy.database:
            database = None  # type: ignore

        relation = super().get_relation(database, schema, identifier)
        return relation

    def get_missing_columns(
        self, from_relation: IRISRelation, to_relation: IRISRelation
    ) -> List[IRISColumn]:
        """Returns a list of Columns in from_relation that are missing from
        to_relation.
        """
        if not isinstance(from_relation, self.Relation):
            invalid_type_error(
                method_name="get_missing_columns",
                arg_name="from_relation",
                got_value=from_relation,
                expected_type=self.Relation,
            )

        if not isinstance(to_relation, self.Relation):
            invalid_type_error(
                method_name="get_missing_columns",
                arg_name="to_relation",
                got_value=to_relation,
                expected_type=self.Relation,
            )

        from_columns = {
            col.name.lower(): col for col in self.get_columns_in_relation(from_relation)
        }

        to_columns = {col.name.lower(): col for col in self.get_columns_in_relation(to_relation)}

        missing_columns = set(from_columns.keys()) - set(to_columns.keys())

        return [
            col for (col_name, col) in from_columns.items() if col_name.lower() in missing_columns
        ]
