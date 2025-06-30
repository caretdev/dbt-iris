from dataclasses import dataclass
from typing import TypeVar, Optional, ClassVar, Dict, Any
from dbt_common.exceptions import DbtRuntimeError
from dbt.adapters.base.column import Column

Self = TypeVar("Self", bound="IRISColumn")


@dataclass
class IRISColumn(Column):
    TYPE_LABELS: ClassVar[Dict[str, str]] = {
        "STRING": "VARCHAR(65535)",
        "FLOAT": "DOUBLE",
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

    # def string_size(self) -> int:
    #     if not self.is_string():
    #         raise DbtRuntimeError("Called string_size() on non-string field!")

    #     if self.dtype == "text" or not self.char_size:
    #         return 65535
    #     else:
    #         return int(self.char_size)

    # @property
    # def data_type(self):
    #     print("!!!! data_type", self.dtype, self.char_size)
    #     return super().data_type
