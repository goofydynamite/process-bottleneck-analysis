-- Time spent at each stage, per order. The full table (about 500k rows) is
-- the stage_durations view; this exports the first 20 delivered orders as a
-- readable sample.
SELECT s.OrderID, s.Stage, s.stage_order, s.WarehouseID, s.Region,
       s.StageStartTime, s.StageEndTime, s.duration_min
FROM stage_durations s
JOIN (SELECT OrderID FROM complete_orders ORDER BY OrderID LIMIT 20) c ON c.OrderID = s.OrderID
ORDER BY s.OrderID, s.stage_order;
