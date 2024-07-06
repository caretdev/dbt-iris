import pytest
import os
from testcontainers.iris import IRISContainer

from tests.functional.projects import dbt_integration


@pytest.fixture(scope="class")
def dbt_integration_project():
    return dbt_integration()


# The profile dictionary, used to write out profiles.yml
@pytest.fixture(scope="class")
def dbt_profile_target(request):
    target = {
        "type": "iris",
        "hostname": os.getenv("DBT_IRIS_HOST", "localhost"),
        "port": int(os.getenv("DBT_IRIS_PORT", "1972")),
        "namespace": os.getenv("DBT_IRIS_NAMESPACE", "USER"),
        "username": os.getenv("DBT_IRIS_USER", "_SYSTEM"),
        "password": os.getenv("DBT_IRIS_PASS", "SYS"),
    }
    iris = request.config.iris
    if iris and iris._container:
        target["hostname"] = "localhost"
        target["port"] = int(iris.get_exposed_port(1972))
        target["namespace"] = iris.namespace
        target["username"] = iris.username
        target["password"] = iris.password
    return target


def pytest_configure(config):
    config.iris = None
    image = config.getoption("--container")
    if not image:
        return

    print("Starting IRIS container:", image)
    iris = IRISContainer(
        image,
        username="dbt",
        password="dbt",
        namespace="DBT",
        license_key="/Users/daimor/iris-community.key",
    )
    iris.with_exposed_ports(1972, 52773)
    iris.start()
    print("uri:", iris.get_connection_url())
    print(
        "SMP:",
        "http://localhost:%s/csp/sys/UtilHome.csp" % iris.get_exposed_port(52773),
    )
    config.iris = iris


def pytest_unconfigure(config):
    if config.iris and config.iris._container:
        print("Stopping IRIS container", config.iris)
        config.iris.stop()
