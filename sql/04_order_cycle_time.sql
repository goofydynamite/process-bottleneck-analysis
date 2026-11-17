-- End-to-end cycle time for delivered orders, same nearest-rank percentiles.
WITH ranked AS (
    SELECT cycle_hours,
           ROW_NUMBER() OVER (ORDER BY cycle_hours) AS rn,
           COUNT(*) OVER () AS n
    FROM order_cycle
)
SELECT
    MAX(n)                     AS delivered_orders,
    ROUND(AVG(cycle_hours), 2) AS avg_hours,
    MAX(CASE WHEN rn = CAST(0.50*n AS INT) + (0.50*n > CAST(0.50*n AS INT)) THEN cycle_hours END) AS p50_hours,
    MAX(CASE WHEN rn = CAST(0.90*n AS INT) + (0.90*n > CAST(0.90*n AS INT)) THEN cycle_hours END) AS p90_hours,
    MAX(CASE WHEN rn = CAST(0.95*n AS INT) + (0.95*n > CAST(0.95*n AS INT)) THEN cycle_hours END) AS p95_hours,
    MAX(cycle_hours)           AS max_hours,
    SUM(cycle_hours > 12)      AS orders_over_12h,
    SUM(cycle_hours > 24)      AS orders_over_24h
FROM ranked;
