#!/usr/bin/env python
from setuptools import find_namespace_packages, setup

from pathlib import Path

package_name = "dbt-iris"
description = """The InterSystems IRIS adapter plugin for dbt"""

# used for this adapter's version and in determining the compatible dbt-core version
VERSION = Path(__file__).parent / "dbt/adapters/iris/__version__.py"


def _dbt_iris_version() -> str:
    """
    Pull the package version from the main package version file
    """
    attributes = {}
    exec(VERSION.read_text(), attributes)
    return attributes["version"]


setup(
    name=package_name,
    version=_dbt_iris_version(),
    description=description,
    long_description=description,
    license="MIT",
    author="CaretDev",
    author_email="info@caretdev.com",
    url="https://github.com/caretdev/dbt-iris",
    packages=find_namespace_packages(
        include=[
            "dbt",
            "dbt.*",
            "iris",
            "intersystems_iris",
            "intersystems_iris.*",
            "irisnative",
        ]
    ),
    include_package_data=True,
    install_requires=[
        "dbt-adapters>=1.1.1,<2.0",
        # add dbt-core to ensure backwards compatibility of installation, this is not a functional dependency
        "dbt-core>=1.8.0",
        "dbt-common>=1.0.4,<2.0",
    ],
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">3.7,<3.12",
)
