"""Run the integrity checks in cypher/04_validation.cypher.

Each check is a Cypher query that returns the rows breaking a rule.
No rows means PASS. The script exits with status 1 if any check fails.

Usage: python python/validate.py
"""

import re
import sys

from db import REPO_ROOT, get_driver

VALIDATION_FILE = REPO_ROOT / "cypher" / "04_validation.cypher"
HEADER = re.compile(r"^// (V-[A-Za-z0-9_-]+): (.*)$")


def load_checks(path):
    """Split the file into (name, description, query) tuples using the // V-... headers."""
    checks = []
    current = None
    for line in path.read_text().splitlines():
        match = HEADER.match(line)
        if match:
            current = [match.group(1), match.group(2), []]
            checks.append(current)
        elif current is not None and line.strip() and not line.lstrip().startswith("//"):
            current[2].append(line)
    return [(name, desc, "\n".join(lines).rstrip().rstrip(";")) for name, desc, lines in checks]


def main():
    checks = load_checks(VALIDATION_FILE)
    failed = 0
    with get_driver() as driver:
        for name, desc, query in checks:
            records = driver.execute_query(query).records
            if records:
                failed += 1
                print(f"FAIL  {name:32} {desc}  ({len(records)} rows)")
                for record in records:
                    print(f"        {dict(record)}")
            else:
                print(f"PASS  {name:32} {desc}")

    print()
    print(f"{len(checks) - failed}/{len(checks)} checks passed.")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
