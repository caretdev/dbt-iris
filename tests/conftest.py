# in order to call dbt's internal profile rendering, we need to set the
# flags global. This is a bit of a hack, but it's the best way to do it.
from dbt.flags import set_from_args
from argparse import Namespace

set_from_args(Namespace(), None)

pytest_plugins = "dbt.tests.fixtures.project"


def pytest_addoption(parser):
    group = parser.getgroup("iris")

    group.addoption(
        "--container",
        action="store",
        default=None,
        type=str,
        help="Docker image with IRIS",
    )
