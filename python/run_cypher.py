"""Run a Cypher file one statement at a time, with a title before each query.

The comment lines directly above a statement (no blank line in between) are
used as its title and description. The first comment line is the title.

Usage:
    python python/run_cypher.py [--show] [--pause] FILE

    FILE     a file in cypher/ (e.g. 03_queries.cypher) or a path
    --show   also print the Cypher of each statement, ready to copy into
             Neo4j Browser
    --pause  wait for Enter after each statement (type q + Enter to stop)

Browser-style parameter lines such as  :param orderId => 'O002';  are
supported, so cypher/05_workflow.cypher works too.
"""

import argparse
import re
import sys
from pathlib import Path

from neo4j.graph import Node, Path as GraphPath, Relationship
from neo4j.time import Date, DateTime, Time

from db import REPO_ROOT, get_driver

PARAM_LINE = re.compile(r"^:param\s+(\w+)\s*=>\s*(.+?);?\s*$")
COLOR = sys.stdout.isatty()


def bold(text):
    return f"\033[1m{text}\033[0m" if COLOR else text


def dim(text):
    return f"\033[36m{text}\033[0m" if COLOR else text


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def parse_statements(text):
    """Return a list of (comments, kind, body). kind is 'cypher' or 'param'."""
    statements = []
    comments = []   # comment block directly above the current statement
    body = []       # lines of the current statement
    for line in text.splitlines():
        stripped = line.strip()
        if not body:
            if not stripped:
                comments = []            # blank line: comment block is a file/section header
                continue
            if stripped.startswith("//"):
                comments.append(stripped[2:].strip())
                continue
            if stripped.startswith(":param"):
                statements.append((comments, "param", stripped))
                comments = []
                continue
        body.append(line)
        if stripped.endswith(";"):
            statements.append((comments, "cypher", "\n".join(body).rstrip().rstrip(";")))
            comments, body = [], []
    if any(l.strip() for l in body):
        statements.append((comments, "cypher", "\n".join(body).rstrip()))
    return statements


# ---------------------------------------------------------------------------
# Formatting values and tables
# ---------------------------------------------------------------------------

def node_text(node):
    label = ":".join(sorted(node.labels))
    key = next((k for k in node.keys() if k.endswith("Id")), None)
    return f"(:{label} {node[key]})" if key else f"(:{label})"


def fmt(value):
    if value is None:
        return "null"
    if isinstance(value, float):
        return f"{value:.1f}" if value == int(value) else f"{value}"
    if isinstance(value, (DateTime, Date, Time)):
        return value.to_native().isoformat()
    if isinstance(value, Node):
        return node_text(value)
    if isinstance(value, Relationship):
        props = ", ".join(f"{k}: {fmt(v)}" for k, v in value.items())
        return f"[:{value.type}{' {' + props + '}' if props else ''}]"
    if isinstance(value, GraphPath):
        text = node_text(value.start_node)
        current = value.start_node
        for rel in value.relationships:
            forward = rel.start_node.element_id == current.element_id
            nxt = rel.end_node if forward else rel.start_node
            text += f"-{fmt(rel)}->" if forward else f"<-{fmt(rel)}-"
            text += node_text(nxt)
            current = nxt
        return text
    if isinstance(value, list):
        return "[" + ", ".join(fmt(v) for v in value) + "]"
    if isinstance(value, dict):
        return "{" + ", ".join(f"{k}: {fmt(v)}" for k, v in value.items()) + "}"
    return str(value)


def print_table(keys, rows):
    cells = [[fmt(r[k]) for k in keys] for r in rows]
    widths = [max([len(k)] + [len(row[i]) for row in cells]) for i, k in enumerate(keys)]
    line = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    print(line)
    print("| " + " | ".join(k.ljust(w) for k, w in zip(keys, widths)) + " |")
    print(line)
    for row in cells:
        print("| " + " | ".join(c.ljust(w) for c, w in zip(row, widths)) + " |")
    print(line)
    print(f"{len(rows)} row{'s' if len(rows) != 1 else ''}")


def print_counters(counters):
    changes = {k: v for k, v in vars(counters).items()
               if isinstance(v, int) and not isinstance(v, bool) and v and not k.startswith("_")}
    if changes:
        print("Changes: " + ", ".join(f"{k.replace('_', ' ')} {v}" for k, v in changes.items()))


# ---------------------------------------------------------------------------
# Running
# ---------------------------------------------------------------------------

def pause():
    try:
        answer = input(dim("Press Enter for the next query (q + Enter to stop)... "))
    except EOFError:
        return True
    return answer.strip().lower() != "q"


def main():
    parser = argparse.ArgumentParser(description="Run a Cypher file statement by statement.")
    parser.add_argument("file", help="file in cypher/ (e.g. 03_queries.cypher) or a path")
    parser.add_argument("--show", action="store_true", help="print the Cypher of each statement")
    parser.add_argument("--pause", action="store_true", help="wait for Enter after each statement")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        path = REPO_ROOT / "cypher" / args.file
    if not path.exists():
        raise SystemExit(f"File not found: {args.file}")

    statements = parse_statements(path.read_text())
    params = {}
    failed = 0

    with get_driver() as driver, driver.session() as session:
        for number, (comments, kind, body) in enumerate(statements, start=1):
            if kind == "param":
                if comments:
                    print()
                    print(bold(comments[0]))
                match = PARAM_LINE.match(body)
                if not match:
                    raise SystemExit(f"Cannot read parameter line: {body}")
                name, expression = match.groups()
                params[name] = session.run(f"RETURN {expression} AS value").single()["value"]
                print(dim(f"Parameter ${name} = {fmt(params[name])}"))
                if args.show:
                    print(body)
                continue

            title = comments[0] if comments else f"Statement {number}"
            print()
            print(bold("=" * 78))
            print(bold(title))
            for line in comments[1:]:
                print(line)
            print(bold("=" * 78))
            if args.show:
                print(dim("Cypher:"))
                print(body + ";")
                print()

            try:
                result = session.run(body, params)
                rows = list(result)
                summary = result.consume()
                if result.keys():
                    print_table(result.keys(), rows)
                print_counters(summary.counters)
            except Exception as error:  # show the error and carry on with the next query
                failed += 1
                print(f"ERROR: {getattr(error, 'message', None) or error}")

            is_last = number == len(statements)
            if args.pause and not is_last and not pause():
                break

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
