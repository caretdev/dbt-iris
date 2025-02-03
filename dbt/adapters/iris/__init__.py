from dbt.adapters.iris.connections import IRISConnectionManager  # noqa
from dbt.adapters.iris.connections import IRISCredentials
from dbt.adapters.iris.relation import IRISRelation  # noqa
from dbt.adapters.iris.column import IRISColumn  # noqa
from dbt.adapters.iris.impl import IRISAdapter

from dbt.adapters.base import AdapterPlugin
from dbt.include import iris


Plugin = AdapterPlugin(
    adapter=IRISAdapter,  # type: ignore
    credentials=IRISCredentials,
    include_path=iris.PACKAGE_PATH,
)
