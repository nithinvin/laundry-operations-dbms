"""PL/SQL Q4 equivalent: display pending laundry orders.

Question: which orders have not been picked up yet, and by whom, with which service?
PL/SQL concepts shown: cursor, FOR loop, multiple joins, filtering.
Expected: O001, O002, O003, O005 (O004 is already picked up)
"""

from db import get_driver

# CURSOR pending_orders IS ...
QUERY = """
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)-[:USES_SERVICE]->(sv:Service)
WHERE o.status <> 'Picked Up'
RETURN o.orderId AS orderId, s.studentName AS studentName,
       sv.serviceName AS serviceName, o.status AS status
ORDER BY o.orderId
"""


def run(session):
    for rec in session.run(QUERY):
        print(
            f"Order: {rec['orderId']}"
            f" | Student: {rec['studentName']}"
            f" | Service: {rec['serviceName']}"
            f" | Status: {rec['status']}"
        )


if __name__ == "__main__":
    with get_driver() as driver, driver.session() as session:
        run(session)
