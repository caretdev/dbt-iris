from dataclasses import dataclass
from typing import TypeVar, Optional, ClassVar, Dict, Any

from dbt.adapters.base.column import Column

Self = TypeVar("Self", bound="IRISColumn")


@dataclass
class IRISColumn(Column):
    TYPE_LABELS: ClassVar[Dict[str, str]] = {
        "STRING": "VARCHAR('')",
        "TIMESTAMP": "TIMESTAMP",
        "FLOAT": "FLOAT",
        "INTEGER": "INTEGER",
        "BOOLEAN": "BIT",
    }

    table_database: Optional[str] = None
    table_schema: Optional[str] = None
    table_name: Optional[str] = None
    table_type: Optional[str] = None
    table_owner: Optional[str] = None
    table_stats: Optional[Dict[str, Any]] = None
    column_index: Optional[int] = None

    @property
    def quoted(self) -> str:
        return "`{}`".format(self.column)

    def __repr__(self) -> str:
        return "<IRISColumn {} ({})>".format(self.name, self.data_type)
