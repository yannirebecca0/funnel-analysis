-- 01: Load October 2019 events, keep a 10% random user sample, clean, and log data quality.
-- Sample rule: all events of every user with hash(user_id) % 10 = 0.

-- Full-file size (one extra pass over the CSV, used for the README numbers)
CREATE OR REPLACE TABLE file_stats AS
SELECT count(*) AS n_events, count(DISTINCT user_id) AS n_users
FROM read_csv('data/raw/2019-Oct.csv.gz', header = true,
     columns = {'event_time': 'VARCHAR', 'event_type': 'VARCHAR', 'product_id': 'BIGINT',
                'category_id': 'BIGINT', 'category_code': 'VARCHAR', 'brand': 'VARCHAR',
                'price': 'DOUBLE', 'user_id': 'BIGINT', 'user_session': 'VARCHAR'});

CREATE OR REPLACE TABLE raw_sample AS
SELECT
    row_number() OVER () AS ev_id,  -- file order, used to break same-second ties
    strptime(replace(event_time, ' UTC', ''), '%Y-%m-%d %H:%M:%S') AS event_time,
    event_type, product_id, category_id, category_code, brand, price, user_id, user_session
FROM read_csv('data/raw/2019-Oct.csv.gz', header = true,
     columns = {'event_time': 'VARCHAR', 'event_type': 'VARCHAR', 'product_id': 'BIGINT',
                'category_id': 'BIGINT', 'category_code': 'VARCHAR', 'brand': 'VARCHAR',
                'price': 'DOUBLE', 'user_id': 'BIGINT', 'user_session': 'VARCHAR'})
WHERE hash(user_id) % 10 = 0;

-- Data quality checks: one row per check, with what was done about it
CREATE OR REPLACE TABLE dq_log AS
SELECT 1 AS step, 'Sampled rows' AS check_name, count(*) AS n_rows, 'kept' AS action FROM raw_sample
UNION ALL
SELECT 2, 'Exact duplicate events (same time, type, product, user, session)',
       count(*) - count(DISTINCT (event_time, event_type, product_id, user_id, user_session)), 'dropped'
FROM raw_sample
UNION ALL
SELECT 3, 'Price <= 0 or missing', count(*), 'dropped' FROM raw_sample WHERE price IS NULL OR price <= 0
UNION ALL
SELECT 4, 'Unknown event_type', count(*), 'dropped' FROM raw_sample WHERE event_type NOT IN ('view', 'cart', 'purchase')
UNION ALL
SELECT 5, 'Missing category_code', count(*), 'kept, labeled "unknown"' FROM raw_sample WHERE category_code IS NULL
UNION ALL
SELECT 6, 'Missing brand', count(*), 'kept' FROM raw_sample WHERE brand IS NULL
UNION ALL
SELECT 7, 'Missing user_session', count(*), 'kept (sessions are rebuilt in 02)' FROM raw_sample WHERE user_session IS NULL
UNION ALL
SELECT 8, 'Events outside 2019-10-01..2019-10-31', count(*), 'dropped'
FROM raw_sample WHERE event_time < TIMESTAMP '2019-10-01' OR event_time >= TIMESTAMP '2019-11-01';

CREATE OR REPLACE TABLE events AS
SELECT
    min(ev_id) AS ev_id, event_time, event_type, product_id,
    any_value(category_id) AS category_id,
    coalesce(split_part(any_value(category_code), '.', 1), 'unknown') AS category,
    any_value(category_code) AS category_code,
    any_value(brand) AS brand, any_value(price) AS price, user_id, user_session
FROM raw_sample
WHERE price > 0
  AND event_type IN ('view', 'cart', 'purchase')
  AND event_time >= TIMESTAMP '2019-10-01' AND event_time < TIMESTAMP '2019-11-01'
GROUP BY event_time, event_type, product_id, user_id, user_session;

INSERT INTO dq_log SELECT 9, 'Clean events after all checks', count(*), 'analysis table' FROM events;

DROP TABLE raw_sample;
