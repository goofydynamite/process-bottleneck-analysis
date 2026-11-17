-- For slow orders, which stage is eating the time?
-- Splits delivered orders into cycle-time bands and shows each stage's share.
SELECT
    CASE WHEN cycle_hours > 24 THEN '3. over 24h'
         WHEN cycle_hours > 12 THEN '2. 12-24h'
         ELSE '1. under 12h' END AS cycle_band,
    COUNT(*)                     AS orders,
    ROUND(AVG(cycle_hours), 1)   AS avg_cycle_hours,
    ROUND(100.0 * SUM(order_placed_min) / SUM(cycle_hours * 60), 1) AS pct_order_placed,
    ROUND(100.0 * SUM(picked_min)       / SUM(cycle_hours * 60), 1) AS pct_picked,
    ROUND(100.0 * SUM(packed_min)       / SUM(cycle_hours * 60), 1) AS pct_packed,
    ROUND(100.0 * SUM(dispatched_min)   / SUM(cycle_hours * 60), 1) AS pct_dispatched,
    ROUND(100.0 * SUM(delivered_min)    / SUM(cycle_hours * 60), 1) AS pct_delivered
FROM order_cycle
GROUP BY cycle_band
ORDER BY cycle_band;
