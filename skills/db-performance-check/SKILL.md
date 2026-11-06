---
name: db-performance-check
description: Finds why database queries are slow and measures fixes before and after. Use when a query or endpoint is slow, before merging a change to queries or indexes, or for a periodic database check. Works with any database that can show a query plan.
---

# DB Performance Check

Find the real cause of a slow query, with numbers to back it up.

## Input

- A slow query, endpoint, or code change. If none is given, start with the database's slow query log or statistics.
- A test database with realistic data. A plan from a few rows tells you little, so say so if the data is small.

## Safety

- Run plans that execute the query, such as `EXPLAIN ANALYZE`, on a test database only. They really run, so an `UPDATE` or `DELETE` changes data.
- Never create indexes or change schema without approval.

## Workflow

1. **Pick targets.** Take at most 5 queries, ordered by total time, not by the slowest single run.
2. **Get the plan.** Use the plan command for this database. Keep only the steps that take the most time, plus estimated and actual row counts.
3. **Find the cause.** Look for:
   - full scans on large tables, or a missing index
   - indexes the query cannot use, such as a function on the column
   - N+1 queries from ORM code
   - fetching more rows or columns than needed
   - estimates far from actual rows, which points to stale statistics
   - time spent waiting on locks
4. **Propose one fix per cause.** Include what it costs too, such as slower writes for a new index.
5. **Measure again.** Apply the fix on the test database and run the same query on the same data, three times. Report the median.

## Output

Keep it under 15 lines, biggest gain first.

```text
`GET /orders` is slow because `orders.customer_id` has no index.

Before  840 ms, full scan of 1.2M rows
After   6 ms, with the index below
Cost    slightly slower inserts on `orders`

CREATE INDEX idx_orders_customer_id ON orders (customer_id);

Not checked: lock time while building the index on production.
```

If you did not measure it, write "expected" and do not give a number.

## How to write

Write like a teammate leaving a note on a PR. Lead with the cause, name real tables and queries, and skip intros and recaps. Do not say "optimized" without numbers.
