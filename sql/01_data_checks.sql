-- Basic checks before trusting any numbers.
SELECT 'rows' AS check_name, COUNT(*) AS value FROM process_events
UNION ALL
SELECT 'orders', COUNT(DISTINCT OrderID) FROM process_events
UNION ALL
SELECT 'delivered orders', COUNT(*) FROM complete_orders
UNION ALL
SELECT 'orders still in flight',
       (SELECT COUNT(DISTINCT OrderID) FROM process_events) - (SELECT COUNT(*) FROM complete_orders)
UNION ALL
SELECT 'stages with no end time', COUNT(*) FROM process_events WHERE StageEndTime IS NULL
UNION ALL
SELECT 'negative durations', COUNT(*) FROM stage_durations WHERE duration_min < 0
UNION ALL
SELECT 'duplicate order-stage rows', COUNT(*) FROM (
    SELECT OrderID, Stage FROM process_events GROUP BY OrderID, Stage HAVING COUNT(*) > 1)
UNION ALL
-- each stage should start exactly when the previous one ended
SELECT 'stage gaps or overlaps', COUNT(*) FROM (
    SELECT StageStartTime,
           LAG(StageEndTime) OVER (PARTITION BY OrderID ORDER BY stage_order) AS prev_end
    FROM stage_durations)
WHERE prev_end IS NOT NULL AND prev_end <> StageStartTime;
