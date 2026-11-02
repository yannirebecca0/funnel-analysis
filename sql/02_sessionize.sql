-- 02: Rebuild sessions from inactivity gaps. A new session starts after more than N minutes
-- without an event from the same user. 30 minutes is the main definition; 10 and 60 are kept
-- for the sensitivity check in 04.

CREATE OR REPLACE TABLE events_s AS
WITH g AS (
    SELECT *,
        epoch(event_time) - epoch(lag(event_time) OVER w) AS gap_s
    FROM events
    WINDOW w AS (PARTITION BY user_id ORDER BY event_time, ev_id)
)
SELECT
    ev_id, event_time, event_type, product_id, category, category_code, brand, price, user_id,
    user_id::VARCHAR || '-' || sum(CASE WHEN gap_s IS NULL OR gap_s > 600  THEN 1 ELSE 0 END) OVER w AS session_10,
    user_id::VARCHAR || '-' || sum(CASE WHEN gap_s IS NULL OR gap_s > 1800 THEN 1 ELSE 0 END) OVER w AS session_id,
    user_id::VARCHAR || '-' || sum(CASE WHEN gap_s IS NULL OR gap_s > 3600 THEN 1 ELSE 0 END) OVER w AS session_60
FROM g
WINDOW w AS (PARTITION BY user_id ORDER BY event_time, ev_id ROWS UNBOUNDED PRECEDING);

CREATE OR REPLACE TABLE session_counts AS
SELECT 10 AS gap_minutes, count(DISTINCT session_10) AS n_sessions FROM events_s
UNION ALL SELECT 30, count(DISTINCT session_id) FROM events_s
UNION ALL SELECT 60, count(DISTINCT session_60) FROM events_s
ORDER BY gap_minutes;
