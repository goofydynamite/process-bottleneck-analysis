-- When does an order reach the packing bench, and how long is it there?
-- Windows line up with the packing shift pattern (benches staffed 06:00-22:00).
SELECT
    CASE
        WHEN CAST(strftime('%H', StageStartTime) AS INT) < 6  THEN '1. 00-06 (no shift)'
        WHEN CAST(strftime('%H', StageStartTime) AS INT) < 10 THEN '2. 06-10'
        WHEN CAST(strftime('%H', StageStartTime) AS INT) < 14 THEN '3. 10-14'
        WHEN CAST(strftime('%H', StageStartTime) AS INT) < 18 THEN '4. 14-18'
        WHEN CAST(strftime('%H', StageStartTime) AS INT) < 22 THEN '5. 18-22'
        ELSE '6. 22-24 (no shift)'
    END AS arrival_window,
    COUNT(*)                                                             AS orders,
    ROUND(AVG(duration_min), 1)                                          AS avg_pack_min,
    ROUND(AVG(CASE WHEN WarehouseID = 'WH03'  THEN duration_min END), 1) AS wh03_avg_pack_min,
    ROUND(AVG(CASE WHEN WarehouseID <> 'WH03' THEN duration_min END), 1) AS others_avg_pack_min,
    ROUND(100.0 * AVG(duration_min > 240), 1)                            AS pct_over_4h
FROM stage_durations
WHERE Stage = 'Packed'
GROUP BY arrival_window
ORDER BY arrival_window;
