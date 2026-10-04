"""Shared Neo4j connection helper.

Reads the connection settings from the .env file in the repo root:
NEO4J_URI, NEO4J_USER and NEO4J_PASSWORD.
"""

import os
from pathlib import Path

from dotenv import load_dotenv
from neo4j import GraphDatabase

REPO_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(REPO_ROOT / ".env")


def get_driver():
    """Return a Neo4j driver. Use it in a `with` block so it gets closed."""
    password = os.getenv("NEO4J_PASSWORD")
    if not password:
        raise SystemExit("NEO4J_PASSWORD is not set. Copy .env.example to .env and set it.")
    return GraphDatabase.driver(
        os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        auth=(os.getenv("NEO4J_USER", "neo4j"), password),
    )


if __name__ == "__main__":
    # Smoke test: python python/db.py
    with get_driver() as driver:
        driver.verify_connectivity()
        record = driver.execute_query("RETURN 1 AS ok").records[0]
        print(f"Connected to Neo4j, RETURN 1 -> {record['ok']}")
