"""Run all 5 PL/SQL-equivalent scripts, one after another.

Usage: python python/run_plsql_equivalents.py [--show] [--pause]
    --show   also print the Cypher query each script sends to Neo4j
    --pause  wait for Enter after each script (q + Enter to stop)
"""

import argparse

import plsql_q1_highest_order
import plsql_q2_total_revenue
import plsql_q3_student_orders
import plsql_q4_pending_orders
import plsql_q5_ready_check
from db import get_driver
from run_cypher import bold, dim, pause

PROGRAMS = [
    ("Q1. Find order with highest total cost", plsql_q1_highest_order),
    ("Q2. Calculate total revenue from paid orders", plsql_q2_total_revenue),
    ("Q3. Display each student and order count", plsql_q3_student_orders),
    ("Q4. Display pending laundry orders", plsql_q4_pending_orders),
    ("Q5. Check whether an order is ready for pickup", plsql_q5_ready_check),
]


def description(module):
    """The docstring lines after the first one, without the Usage line."""
    lines = (module.__doc__ or "").strip().splitlines()[1:]
    return [line for line in lines if line.strip() and not line.startswith("Usage:")]


def main():
    parser = argparse.ArgumentParser(description="Run the 5 PL/SQL-equivalent scripts.")
    parser.add_argument("--show", action="store_true", help="print the Cypher query of each script")
    parser.add_argument("--pause", action="store_true", help="wait for Enter after each script")
    args = parser.parse_args()

    with get_driver() as driver, driver.session() as session:
        for number, (title, program) in enumerate(PROGRAMS, start=1):
            print(bold("=" * 78))
            print(bold(title))
            for line in description(program):
                print(line)
            print(f"Script: python/{program.__name__}.py")
            print(bold("=" * 78))
            if args.show:
                print(dim("Cypher:"))
                for name, value in getattr(program, "BROWSER_PARAMS", {}).items():
                    print(f":param {name} => '{value}';")
                print(program.QUERY.strip() + ";")
                print()
                print(dim("Output:"))
            program.run(session)
            print()
            if args.pause and number < len(PROGRAMS) and not pause():
                break


if __name__ == "__main__":
    main()
