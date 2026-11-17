-- Variance check: average minutes per stage for every warehouse x region
-- combination. If only Packing moves between warehouses, the problem is
-- inside the building, not the delivery geography.
SELECT
    WarehouseID,
    Region,
    COUNT(DISTINCT OrderID) AS orders,
    ROUND(AVG(CASE WHEN Stage = 'Order Placed' THEN duration_min END), 1) AS order_placed_min,
    ROUND(AVG(CASE WHEN Stage = 'Picked'       THEN duration_min END), 1) AS picked_min,
    ROUND(AVG(CASE WHEN Stage = 'Packed'       THEN duration_min END), 1) AS packed_min,
    ROUND(AVG(CASE WHEN Stage = 'Dispatched'   THEN duration_min END), 1) AS dispatched_min,
    ROUND(AVG(CASE WHEN Stage = 'Delivered'    THEN duration_min END), 1) AS delivered_min
FROM stage_durations
GROUP BY WarehouseID, Region
ORDER BY WarehouseID, Region;
