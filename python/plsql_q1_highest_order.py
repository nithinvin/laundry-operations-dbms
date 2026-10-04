"""PL/SQL Q1 equivalent: find the order with the highest total cost.

PL/SQL concepts shown: variables, SELECT ... INTO, MAX, subquery.
"""

from db import get_driver

QUERY = """
MATCH (o:LaundryOrder)
WITH max(o.totalAmount) AS maxAmount
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)-[:USES_SERVICE]->(sv:Service)
WHERE o.totalAmount = maxAmount
RETURN o.orderId AS orderId, s.studentId AS studentId,
       sv.serviceId AS serviceId, o.totalAmount AS totalAmount
"""


def run(session):
    # SELECT ... INTO v_order_id, v_student_id, ... (exactly one row expected)
    record = session.run(QUERY).single(strict=True)
    v_order_id = record["orderId"]
    v_student_id = record["studentId"]
    v_service_id = record["serviceId"]
    v_total_amount = record["totalAmount"]

    print(f"Order ID: {v_order_id}")
    print(f"Student ID: {v_student_id}")
    print(f"Service ID: {v_service_id}")
    print(f"Highest Total Amount: {v_total_amount:g}")


if __name__ == "__main__":
    with get_driver() as driver, driver.session() as session:
        run(session)
