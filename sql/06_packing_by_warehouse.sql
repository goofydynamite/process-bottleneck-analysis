-- Packing performance by warehouse, next to each warehouse's end-to-end time.
WITH pack AS (
    SELECT WarehouseID, duration_min,
           ROW_NUMBER() OVER (PARTITION BY WarehouseID ORDER BY duration_min) AS rn,
           COUNT(*)     OVER (PARTITION BY WarehouseID)                       AS n
    FROM stage_durations
    WHERE Stage = 'Packed'
),
pack_stats AS (
    SELECT WarehouseID,
           MAX(n)                      AS packed_orders,
           ROUND(AVG(duration_min), 1) AS avg_pack_min,
           MAX(CASE WHEN rn = CAST(0.5*n AS INT) + (0.5*n > CAST(0.5*n AS INT)) THEN duration_min END) AS p50_pack_min,
           MAX(CASE WHEN rn = CAST(0.9*n AS INT) + (0.9*n > CAST(0.9*n AS INT)) THEN duration_min END) AS p90_pack_min,
           ROUND(100.0 * AVG(duration_min > 240), 1) AS pct_pack_over_4h
    FROM pack
    GROUP BY WarehouseID
)
SELECT p.*,
       ROUND(AVG(o.cycle_hours), 2)              AS avg_cycle_hours,
       ROUND(100.0 * AVG(o.cycle_hours > 12), 1) AS pct_cycle_over_12h
FROM pack_stats p
JOIN order_cycle o ON o.WarehouseID = p.WarehouseID
GROUP BY p.WarehouseID
ORDER BY p.avg_pack_min DESC;
