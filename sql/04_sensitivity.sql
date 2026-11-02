-- 04: Sessionization sensitivity. Recompute the strict cart -> purchase rate by category
-- under 10, 30 and 60 minute gaps to check that the segment ranking does not depend on the gap.

CREATE OR REPLACE TABLE sensitivity AS
WITH long AS (
    SELECT 10 AS gap_minutes, session_10 AS sess, product_id, category, event_type, event_time FROM events_s
    UNION ALL SELECT 30, session_id, product_id, category, event_type, event_time FROM events_s
    UNION ALL SELECT 60, session_60, product_id, category, event_type, event_time FROM events_s
), v AS (
    SELECT *, min(CASE WHEN event_type = 'view' THEN event_time END)
        OVER (PARTITION BY gap_minutes, sess, product_id) AS first_view
    FROM long
), c AS (
    SELECT *, min(CASE WHEN event_type = 'cart' AND event_time >= first_view THEN event_time END)
        OVER (PARTITION BY gap_minutes, sess, product_id) AS first_cart
    FROM v
), sp AS (
    SELECT gap_minutes, sess, product_id, any_value(category) AS category,
        min(first_cart) IS NOT NULL AS carted,
        min(CASE WHEN event_type = 'purchase' AND event_time >= first_cart THEN event_time END) IS NOT NULL AS purchased
    FROM c GROUP BY gap_minutes, sess, product_id
)
SELECT gap_minutes, category,
    count(*) FILTER (WHERE carted) AS carted,
    count(*) FILTER (WHERE purchased) AS purchased,
    count(*) FILTER (WHERE purchased) / nullif(count(*) FILTER (WHERE carted), 0) AS cart_to_purchase
FROM sp GROUP BY gap_minutes, category;
