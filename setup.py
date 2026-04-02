from setuptools import setup, find_packages

setup(
    name="ora2mssql",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "oracledb>=2.0.0",
        "pyodbc>=5.0",
        "click>=8.1",
        "pydantic>=2.0",
        "pyyaml>=6.0",
        "rich>=13.0",
        "jinja2>=3.1",
        "sqlparse>=0.5",
        "networkx>=3.0",
    ],
    entry_points={
        "console_scripts": [
            "ora2mssql=ora2mssql.cli:main",
        ],
    },
)
