import pytest

import os

# import json

# Import the fuctional fixtures as a plugin
# Note: fixtures with session scope need to be local

pytest_plugins = ["dbt.tests.fixtures.project"]


# The profile dictionary, used to write out profiles.yml
@pytest.fixture(scope="class")
def dbt_profile_target():
    return {
        "type": "iris",
        "hostname": os.getenv("DBT_IRIS_HOST", "localhost"),
        "port": int(os.getenv("DBT_IRIS_PORT", "1972")),
        "namespace": os.getenv("DBT_IRIS_NAMESPACE", "USER"),
        "username": os.getenv("DBT_IRIS_USER", "_SYSTEM"),
        "password": os.getenv("DBT_IRIS_PASS", "SYS"),
    }
