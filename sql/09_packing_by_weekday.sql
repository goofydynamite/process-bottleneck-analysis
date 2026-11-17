-- Packing time by the day the order reached packing.
-- WH02 and WH03 have no Sunday packing shift; WH01 and WH04 do.
SELECT
    CAST(strftime('%w', StageStartTime) AS INT) AS weekday_num,
    CASE strftime('%w', StageStartTime)
        WHEN '0' THEN 'Sun' WHEN '1' THEN 'Mon' WHEN '2' THEN 'Tue' WHEN '3' THEN 'Wed'
        WHEN '4' THEN 'Thu' WHEN '5' THEN 'Fri' ELSE 'Sat' END AS weekday,
    COUNT(*) AS orders,
    ROUND(AVG(CASE WHEN WarehouseID IN ('WH02', 'WH03') THEN duration_min END), 1) AS no_sunday_shift_avg_min,
    ROUND(AVG(CASE WHEN WarehouseID IN ('WH01', 'WH04') THEN duration_min END), 1) AS sunday_shift_avg_min
FROM stage_durations
WHERE Stage = 'Packed'
GROUP BY weekday_num
ORDER BY weekday_num;
