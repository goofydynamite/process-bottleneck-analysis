-- 90-day trend: average minutes per stage by the week the order was placed
-- (weeks start Monday).
SELECT
    date(placed_at, '-' || ((CAST(strftime('%w', placed_at) AS INT) + 6) % 7) || ' days') AS week_start,
    COUNT(*)                        AS orders,
    ROUND(AVG(order_placed_min), 1) AS order_placed_min,
    ROUND(AVG(picked_min), 1)       AS picked_min,
    ROUND(AVG(packed_min), 1)       AS packed_min,
    ROUND(AVG(dispatched_min), 1)   AS dispatched_min,
    ROUND(AVG(delivered_min), 1)    AS delivered_min,
    ROUND(AVG(cycle_hours), 2)      AS avg_cycle_hours,
    ROUND(AVG(CASE WHEN WarehouseID = 'WH03'  THEN packed_min END), 1) AS wh03_packed_min,
    ROUND(AVG(CASE WHEN WarehouseID <> 'WH03' THEN packed_min END), 1) AS others_packed_min
FROM order_cycle
GROUP BY week_start
ORDER BY week_start;
