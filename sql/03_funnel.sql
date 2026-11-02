-- 03: Strict view -> cart -> purchase funnel at the session x product level.
-- A cart counts only if it follows a view of that product in the same session, and a purchase
-- only if it follows such a cart.

-- Price tiers: quartiles of a product's average price within its top-level category
CREATE OR REPLACE TABLE product_tiers AS
SELECT product_id, category, avg_price,
    ntile(4) OVER (PARTITION BY category ORDER BY avg_price, product_id) AS price_tier
FROM (
    SELECT product_id, any_value(category) AS category, avg(price) AS avg_price
    FROM events_s GROUP BY product_id
);

CREATE OR REPLACE TABLE sp_funnel AS
WITH v AS (
    SELECT *,
        min(CASE WHEN event_type = 'view' THEN event_time END)
            OVER (PARTITION BY session_id, product_id) AS first_view
    FROM events_s
), c AS (
    SELECT *,
        min(CASE WHEN event_type = 'cart' AND event_time >= first_view THEN event_time END)
            OVER (PARTITION BY session_id, product_id) AS first_cart
    FROM v
)
SELECT
    session_id, any_value(user_id) AS user_id, product_id,
    min(event_time) AS first_event,
    min(first_view) AS first_view,
    min(first_cart) AS first_cart,
    min(CASE WHEN event_type = 'purchase' AND event_time >= first_cart THEN event_time END) AS first_purchase,
    max(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS any_purchase,
    max(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS any_cart,
    avg(CASE WHEN event_type = 'cart' THEN price END) AS cart_price,
    avg(CASE WHEN event_type = 'purchase' THEN price END) AS purchase_price
FROM c
GROUP BY session_id, product_id;

-- First purchase per user, to split first-time from returning buyers (October history only)
CREATE OR REPLACE TABLE user_first_purchase AS
SELECT user_id, min(event_time) AS first_purchase_time
FROM events_s WHERE event_type = 'purchase' GROUP BY user_id;

CREATE OR REPLACE TABLE funnel_sp AS
SELECT f.*, t.category, t.price_tier,
    first_view IS NOT NULL AS viewed,
    first_cart IS NOT NULL AS carted,
    first_purchase IS NOT NULL AS purchased,
    any_purchase = 1 AND first_purchase IS NULL AS purchase_skipped_step,
    coalesce(u.first_purchase_time < f.first_event, false) AS is_returning
FROM sp_funnel f
JOIN product_tiers t USING (product_id)
LEFT JOIN user_first_purchase u USING (user_id);
DROP TABLE sp_funnel;

-- Session-level funnel: did the session view anything, cart after a view, purchase after a cart
CREATE OR REPLACE TABLE funnel_session AS
SELECT session_id, any_value(user_id) AS user_id,
    bool_or(viewed) AS viewed, bool_or(carted) AS carted, bool_or(purchased) AS purchased,
    bool_or(any_purchase = 1) AS any_purchase
FROM funnel_sp GROUP BY session_id;

-- Category x price tier: cart -> purchase conversion and the value of carts left behind
CREATE OR REPLACE TABLE segment_funnel AS
SELECT category, price_tier,
    count(*) FILTER (WHERE viewed) AS viewed,
    count(*) FILTER (WHERE carted) AS carted,
    count(*) FILTER (WHERE purchased) AS purchased,
    count(*) FILTER (WHERE purchased) / nullif(count(*) FILTER (WHERE carted), 0) AS cart_to_purchase,
    sum(cart_price) FILTER (WHERE carted AND NOT purchased) AS abandoned_value,
    sum(purchase_price) FILTER (WHERE purchased) AS purchased_value
FROM funnel_sp
GROUP BY category, price_tier;
