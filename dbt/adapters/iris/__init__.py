from dbt.adapters.iris.connections import IRISConnectionManager  # noqa
from dbt.adapters.iris.connections import IRISCredentials
from dbt.adapters.iris.relation import IRISRelation  # noqa
from dbt.adapters.iris.column import IRISColumn  # noqa
from dbt.adapters.iris.impl import IRISAdapter

from dbt.adapters.base import AdapterPlugin  # type: ignore
from dbt.include import iris  # type: ignore


Plugin = AdapterPlugin(
    adapter=IRISAdapter, credentials=IRISCredentials, include_path=iris.PACKAGE_PATH  # type: ignore
)
