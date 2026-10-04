"""Run all 5 PL/SQL-equivalent scripts, one after another.

Usage: python python/run_plsql_equivalents.py
"""

import plsql_q1_highest_order
import plsql_q2_total_revenue
import plsql_q3_student_orders
import plsql_q4_pending_orders
import plsql_q5_ready_check
from db import get_driver

PROGRAMS = [
    ("Q1. Find order with highest total cost", plsql_q1_highest_order),
    ("Q2. Calculate total revenue from paid orders", plsql_q2_total_revenue),
    ("Q3. Display each student and order count", plsql_q3_student_orders),
    ("Q4. Display pending laundry orders", plsql_q4_pending_orders),
    ("Q5. Check whether an order is ready for pickup", plsql_q5_ready_check),
]


def main():
    with get_driver() as driver, driver.session() as session:
        for title, program in PROGRAMS:
            print(f"=== {title} ===")
            program.run(session)
            print()


if __name__ == "__main__":
    main()
