-- Average vs median vs P90 vs P95 per stage.
-- SQLite has no PERCENTILE_CONT, so I use the nearest-rank method:
-- P90 = the smallest value with at least 90% of rows at or below it.
-- ceil(p * n) is written as CAST(p*n AS INT) + (p*n > CAST(p*n AS INT)).
WITH ranked AS (
    SELECT Stage, stage_order, duration_min,
           ROW_NUMBER() OVER (PARTITION BY Stage ORDER BY duration_min) AS rn,
           COUNT(*)     OVER (PARTITION BY Stage)                       AS n
    FROM stage_durations
),
ranks AS (
    SELECT DISTINCT Stage, n,
           CAST(0.50 * n AS INT) + (0.50 * n > CAST(0.50 * n AS INT)) AS r50,
           CAST(0.90 * n AS INT) + (0.90 * n > CAST(0.90 * n AS INT)) AS r90,
           CAST(0.95 * n AS INT) + (0.95 * n > CAST(0.95 * n AS INT)) AS r95
    FROM ranked
)
SELECT
    r.Stage,
    k.n                                                 AS orders,
    ROUND(AVG(r.duration_min), 1)                       AS avg_min,
    MAX(CASE WHEN r.rn = k.r50 THEN r.duration_min END) AS p50_min,
    MAX(CASE WHEN r.rn = k.r90 THEN r.duration_min END) AS p90_min,
    MAX(CASE WHEN r.rn = k.r95 THEN r.duration_min END) AS p95_min,
    MAX(r.duration_min)                                 AS max_min,
    ROUND(MAX(CASE WHEN r.rn = k.r90 THEN r.duration_min END) / AVG(r.duration_min), 1) AS p90_to_avg,
    ROUND(100.0 * SUM(r.duration_min) / (SELECT SUM(duration_min) FROM stage_durations), 1) AS pct_of_total_time
FROM ranked r
JOIN ranks k ON k.Stage = r.Stage
GROUP BY r.Stage
ORDER BY MIN(r.stage_order);
