#!/usr/bin/env python
from setuptools import find_namespace_packages, setup

package_name = "dbt-iris"
# make sure this always matches dbt/adapters/{adapter}/__version__.py
package_version = "1.3.0b1"
description = """The InterSystems IRIS adapter plugin for dbt"""

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=description,
    license='MIT',
    author="CaretDev",
    author_email="info@caretdev.com",
    url="https://github.com/caretdev/dbt-iris",
    packages=find_namespace_packages(include=["dbt", "dbt.*"]),
    include_package_data=True,
    install_requires=[
        "dbt-core~=1.3.0",
    ],
    classifiers=[
        'Development Status :: 3 - Alpha',

        'License :: OSI Approved :: MIT License'
        
        'Operating System :: OS Independent'

        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
    ],
    python_requires=">3.7,<=3.10",
)
