-- Views everything else builds on. process_events is loaded from
-- data/process_events.csv by src/run_sql.py.

DROP VIEW IF EXISTS stage_durations;
DROP VIEW IF EXISTS complete_orders;
DROP VIEW IF EXISTS order_cycle;

-- One row per order per stage, with the time spent in that stage.
-- Stages still in progress (no end time) are left out.
CREATE VIEW stage_durations AS
SELECT
    OrderID,
    Stage,
    CASE Stage
        WHEN 'Order Placed' THEN 1
        WHEN 'Picked'       THEN 2
        WHEN 'Packed'       THEN 3
        WHEN 'Dispatched'   THEN 4
        WHEN 'Delivered'    THEN 5
    END AS stage_order,
    WarehouseID,
    Region,
    StageStartTime,
    StageEndTime,
    ROUND((julianday(StageEndTime) - julianday(StageStartTime)) * 24 * 60, 1) AS duration_min
FROM process_events
WHERE StageEndTime IS NOT NULL;

-- Orders that made it all the way to Delivered.
CREATE VIEW complete_orders AS
SELECT OrderID
FROM stage_durations
GROUP BY OrderID
HAVING COUNT(*) = 5;

-- One row per delivered order: total cycle time plus minutes per stage.
CREATE VIEW order_cycle AS
SELECT
    s.OrderID,
    MAX(s.WarehouseID)    AS WarehouseID,
    MAX(s.Region)         AS Region,
    MIN(s.StageStartTime) AS placed_at,
    MAX(s.StageEndTime)   AS delivered_at,
    SUM(CASE WHEN s.Stage = 'Order Placed' THEN s.duration_min END) AS order_placed_min,
    SUM(CASE WHEN s.Stage = 'Picked'       THEN s.duration_min END) AS picked_min,
    SUM(CASE WHEN s.Stage = 'Packed'       THEN s.duration_min END) AS packed_min,
    SUM(CASE WHEN s.Stage = 'Dispatched'   THEN s.duration_min END) AS dispatched_min,
    SUM(CASE WHEN s.Stage = 'Delivered'    THEN s.duration_min END) AS delivered_min,
    ROUND((julianday(MAX(s.StageEndTime)) - julianday(MIN(s.StageStartTime))) * 24, 2) AS cycle_hours
FROM stage_durations s
JOIN complete_orders c ON c.OrderID = s.OrderID
GROUP BY s.OrderID;
