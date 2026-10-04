"""PL/SQL Q3 equivalent: display each student and their order count.

PL/SQL concepts shown: cursor, FOR loop, LEFT JOIN (OPTIONAL MATCH), COUNT.
"""

from db import get_driver

# CURSOR student_orders IS ...
QUERY = """
MATCH (s:Student)
OPTIONAL MATCH (s)-[:PLACED]->(o:LaundryOrder)
RETURN s.studentId AS studentId, s.studentName AS studentName, count(o) AS orderCount
ORDER BY studentId
"""


def run(session):
    # FOR rec IN student_orders LOOP ... END LOOP;
    for rec in session.run(QUERY):
        print(f"Student: {rec['studentName']} | Orders: {rec['orderCount']}")


if __name__ == "__main__":
    with get_driver() as driver, driver.session() as session:
        run(session)
