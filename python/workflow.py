"""Laundry order workflow: move orders through their statuses and notify students.

Allowed status path (same values as the Oracle CHECK constraint):
    Received -> Queued -> Processing -> Ready for Pickup -> Picked Up
    Cancelled is allowed from any status before Ready for Pickup.

Some status changes create a Notification for the student automatically.
Marking an order "Ready for Pickup" also records actualCompletion.

Usage:
    python python/workflow.py show    ORDER_ID
    python python/workflow.py advance ORDER_ID
    python python/workflow.py cancel  ORDER_ID
    python python/workflow.py remind            # pickup reminder for every order still waiting

These commands change the data. Run ./scripts/reset.sh to go back to the
original sample data.
"""

import sys

from db import get_driver

NEXT_STATUS = {
    "Received": "Queued",
    "Queued": "Processing",
    "Processing": "Ready for Pickup",
    "Ready for Pickup": "Picked Up",
}
CANCELLABLE = {"Received", "Queued", "Processing"}

# Notification created when an order enters this status: (type, message template)
NOTIFY_ON = {
    "Processing": ("Processing", "Your laundry order {id} is currently being processed."),
    "Ready for Pickup": ("Ready for Pickup", "Your laundry order {id} is ready for pickup."),
    "Picked Up": ("Pickup Confirmation", "Your laundry order {id} has been picked up."),
    "Cancelled": ("Order Cancelled", "Your laundry order {id} has been cancelled."),
}

GET_ORDER = """
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder {orderId: $orderId})
RETURN o.orderId AS orderId, o.status AS status, s.studentName AS student
"""

# Next ID = highest existing number + 1, e.g. N008 -> N009
NEXT_NOTIFICATION_ID = """
MATCH (n:Notification)
RETURN 'N' + right('000' + toString(coalesce(max(toInteger(substring(n.notificationId, 1))), 0) + 1), 3) AS nextId
"""

SET_STATUS = """
MATCH (o:LaundryOrder {orderId: $orderId})
SET o.status = $status
FOREACH (_ IN CASE WHEN $status = 'Ready for Pickup' THEN [1] ELSE [] END |
  SET o.actualCompletion = localdatetime.truncate('second', localdatetime()))
"""

CREATE_NOTIFICATION = """
MATCH (o:LaundryOrder {orderId: $orderId})
CREATE (o)-[:GENERATED]->(n:Notification {
  notificationId: $notificationId,
  notificationType: $type,
  message: $message,
  sentAt: localdatetime.truncate('second', localdatetime()),
  readStatus: 'Unread'
})
RETURN n.notificationId AS id
"""

WAITING_FOR_PICKUP = """
MATCH (o:LaundryOrder {status: 'Ready for Pickup'})
RETURN o.orderId AS orderId ORDER BY orderId
"""

SHOW_ORDER = """
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder {orderId: $orderId})
OPTIONAL MATCH (o)-[:GENERATED]->(n:Notification)
WITH s, o, n ORDER BY n.sentAt
RETURN o.orderId AS orderId, s.studentName AS student, o.status AS status,
       collect(n.notificationId + ' ' + n.notificationType + ' (' + n.readStatus + ')') AS notifications
"""


def get_order(tx, order_id):
    record = tx.run(GET_ORDER, orderId=order_id).single()
    if record is None:
        raise SystemExit(f"Order {order_id} does not exist.")
    return record


def notify(tx, order_id, notification_type, message):
    notification_id = tx.run(NEXT_NOTIFICATION_ID).single()["nextId"]
    tx.run(CREATE_NOTIFICATION, orderId=order_id, notificationId=notification_id,
           type=notification_type, message=message).consume()
    return notification_id


def change_status(tx, order_id, new_status):
    """Set the new status and create the matching notification, in one transaction."""
    tx.run(SET_STATUS, orderId=order_id, status=new_status).consume()
    if new_status in NOTIFY_ON:
        notification_type, template = NOTIFY_ON[new_status]
        return notify(tx, order_id, notification_type, template.format(id=order_id))
    return None


def advance(tx, order_id):
    order = get_order(tx, order_id)
    current = order["status"]
    if current not in NEXT_STATUS:
        raise SystemExit(f"Order {order_id} is '{current}'; it cannot move forward.")
    new_status = NEXT_STATUS[current]
    notification_id = change_status(tx, order_id, new_status)
    return current, new_status, notification_id


def cancel(tx, order_id):
    order = get_order(tx, order_id)
    current = order["status"]
    if current not in CANCELLABLE:
        raise SystemExit(f"Order {order_id} is '{current}'; it can no longer be cancelled.")
    notification_id = change_status(tx, order_id, "Cancelled")
    return current, "Cancelled", notification_id


def remind(tx):
    sent = []
    for record in list(tx.run(WAITING_FOR_PICKUP)):
        order_id = record["orderId"]
        message = f"Please collect your laundry order {order_id} to avoid congestion."
        sent.append((order_id, notify(tx, order_id, "Pickup Reminder", message)))
    return sent


def show(session, order_id):
    record = session.run(SHOW_ORDER, orderId=order_id).single()
    if record is None:
        raise SystemExit(f"Order {order_id} does not exist.")
    print(f"Order {record['orderId']} | Student: {record['student']} | Status: {record['status']}")
    for line in record["notifications"]:
        print(f"  {line}")


def main(argv):
    if len(argv) < 2 or argv[1] not in {"show", "advance", "cancel", "remind"}:
        raise SystemExit(__doc__)
    command = argv[1]
    if command != "remind" and len(argv) != 3:
        raise SystemExit(f"Usage: python python/workflow.py {command} ORDER_ID")

    with get_driver() as driver, driver.session() as session:
        if command == "show":
            show(session, argv[2])
        elif command == "remind":
            sent = session.execute_write(remind)
            if not sent:
                print("No orders are waiting for pickup.")
            for order_id, notification_id in sent:
                print(f"Reminder {notification_id} sent for order {order_id}.")
        else:
            action = advance if command == "advance" else cancel
            old, new, notification_id = session.execute_write(action, argv[2])
            print(f"Order {argv[2]}: {old} -> {new}")
            if notification_id:
                print(f"Notification {notification_id} created.")


if __name__ == "__main__":
    main(sys.argv)
