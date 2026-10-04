"""PL/SQL Q2 equivalent: total revenue from paid orders.

PL/SQL concepts shown: variable, SELECT ... INTO, SUM, NVL (coalesce in Cypher).
"""

from db import get_driver

QUERY = """
MATCH (p:Payment {paymentStatus: 'Paid'})
RETURN coalesce(sum(p.amount), 0) AS revenue
"""


def run(session):
    v_revenue = session.run(QUERY).single(strict=True)["revenue"]
    print(f"Total Revenue from Paid Orders: {v_revenue:g}")


if __name__ == "__main__":
    with get_driver() as driver, driver.session() as session:
        run(session)
