// 03_queries.cypher
// The 5 "advanced SQL" queries from the Oracle version, written in Cypher.
// Expected outputs are listed in docs/queries.md (Part A).

// A1. Student with the most expensive order
// SQL: WHERE totalamount = (SELECT max(totalamount) FROM laundry_order)
MATCH (o:LaundryOrder)
WITH max(o.totalAmount) AS maxAmount
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)
WHERE o.totalAmount = maxAmount
RETURN s.studentId, s.studentName, o.orderId, o.totalAmount;

// A2. Services whose average order amount is above the overall average
// SQL: GROUP BY ... HAVING avg(totalamount) > (SELECT avg(totalamount) ...)
MATCH (o:LaundryOrder)
WITH avg(o.totalAmount) AS overallAvg
MATCH (o:LaundryOrder)-[:USES_SERVICE]->(sv:Service)
WITH sv, overallAvg, avg(o.totalAmount) AS averageAmount
WHERE averageAmount > overallAvg
RETURN sv.serviceId, sv.serviceName, averageAmount
ORDER BY sv.serviceId;

// A3. Students with more than one order
// Expected: no rows (each student has exactly one order), same as Oracle.
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)
WITH s, count(o) AS orderCount
WHERE orderCount > 1
RETURN s.studentId, s.studentName, orderCount;

// A4. Garment types appearing in more than one order
MATCH (o:LaundryOrder)-[:CONTAINS]->(g:GarmentType)
WITH g, count(DISTINCT o) AS orderCount
WHERE orderCount > 1
RETURN g.garmentTypeId, g.garmentName, orderCount
ORDER BY g.garmentTypeId;

// A5. Orders whose payment amount matches the order amount
MATCH (o:LaundryOrder)-[:HAS_PAYMENT]->(p:Payment)
WHERE p.amount = o.totalAmount
RETURN o.orderId, o.totalAmount, p.amount, p.paymentStatus
ORDER BY o.orderId;
