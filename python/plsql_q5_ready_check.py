"""PL/SQL Q5 equivalent: check whether an order is ready for pickup.

PL/SQL concepts shown: SELECT ... INTO, IF-ELSE.
Usage: python python/plsql_q5_ready_check.py [ORDER_ID]   (default O001)
"""

import sys

from db import get_driver

QUERY = "MATCH (o:LaundryOrder {orderId: $orderId}) RETURN o.status AS status"


def run(session, order_id="O001"):
    record = session.run(QUERY, orderId=order_id).single()
    if record is None:
        # PL/SQL would raise NO_DATA_FOUND here
        print(f"Order {order_id} does not exist.")
        return
    v_status = record["status"]

    if v_status == "Ready for Pickup":
        print(f"Order {order_id} is ready for pickup.")
    else:
        print(f"Order {order_id} is not ready for pickup.")


if __name__ == "__main__":
    with get_driver() as driver, driver.session() as session:
        run(session, sys.argv[1] if len(sys.argv) > 1 else "O001")
