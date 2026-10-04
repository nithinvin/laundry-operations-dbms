// 00_reset.cypher
// Deletes every node and relationship. Constraints and indexes are kept.
MATCH (n) DETACH DELETE n;
