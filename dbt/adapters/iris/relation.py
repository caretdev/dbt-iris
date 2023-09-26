from typing import Optional
from dataclasses import dataclass, field

from dbt.adapters.base.relation import BaseRelation, Policy
from dbt.contracts.relation import ComponentName
from dbt.utils import filter_null_values
import dbt.exceptions


@dataclass
class IRISQuotePolicy(Policy):
    database: bool = False
    schema: bool = True
    identifier: bool = True


@dataclass
class IRISIncludePolicy(Policy):
    database: bool = False
    schema: bool = True
    identifier: bool = True


@dataclass(frozen=True, eq=False, repr=False)
class IRISRelation(BaseRelation):
    quote_policy: Policy = field(default_factory=lambda: IRISQuotePolicy())
    include_policy: Policy = field(default_factory=lambda: IRISIncludePolicy())

    def matches(
        self,
        database: Optional[str] = None,
        schema: Optional[str] = None,
        identifier: Optional[str] = None,
    ) -> bool:
        search = filter_null_values(
            {
                ComponentName.Database: database,
                ComponentName.Schema: schema,
                ComponentName.Identifier: identifier,
            }
        )

        if not search:
            # nothing was passed in
            raise dbt.exceptions.DbtRuntimeError(
                "Tried to match relation, but no search path was passed!"
            )

        exact_match = True
        approximate_match = True

        for k, v in search.items():
            if not self._is_exactish_match(k, v):
                exact_match = False
            if str(self.path.get_lowered_part(k)).strip(self.quote_character) != v.lower().strip(
                self.quote_character
            ):
                approximate_match = False

        # if approximate_match and not exact_match:
        #     target = self.create(database=database, schema=schema, identifier=identifier)
        #     dbt.exceptions.approximate_relation_match(target, self)

        return exact_match or approximate_match
