#!/usr/bin/env python
from setuptools import find_namespace_packages, setup
import os

package_name = "dbt-iris"
# make sure this always matches dbt/adapters/{adapter}/__version__.py
package_version = "1.3.2"
description = """The InterSystems IRIS adapter plugin for dbt"""

thelibFolder = os.path.dirname(os.path.realpath(__file__))
requirementPath = thelibFolder + "/requirements.txt"

requirements = []
if os.path.isfile(requirementPath):
    with open("./requirements.txt") as f:
        for line in f.read().splitlines():
            requirements.append(line)

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=description,
    license="MIT",
    author="CaretDev",
    author_email="info@caretdev.com",
    url="https://github.com/caretdev/dbt-iris",
    packages=find_namespace_packages(
        include=["dbt", "dbt.*", "iris", "intersystems_iris.*", "irisnative"]
    ),
    include_package_data=True,
    install_requires=requirements,
    classifiers=[
        "Development Status :: 3 - Alpha",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
    python_requires=">3.7,<3.11",
)
