-- getting familiar with data
SELECT *
FROM subscriptions
LIMIT 10;

-- all different segments
SELECT DISTINCT segment
FROM subscriptions;
-- distribution of segments
SELECT segment, COUNT(*) AS count
FROM subscriptions
GROUP BY 1;

-- period of available data
SELECT 
  MIN(subscription_start) AS first_date,
  MAX(subscription_end) AS last_date
FROM subscriptions;

-- create a table for dates
WITH months AS(
  SELECT
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
  UNION
  SELECT
    '2017-02-01' AS first_day,
    '2017-02-28' AS last_day
  UNION
  SELECT
    '2017-03-01' AS first_day,
    '2017-03-31' AS last_day
),
-- merge the dates table with the subscriptions table
cross_join AS(
  SELECT *
  FROM subscriptions
  CROSS JOIN months
),
-- four columns for activity status by segment for each month
status AS(
  SELECT
    id,
    first_day AS month, 
    CASE
      WHEN (subscription_start < first_day)
      AND ((subscription_end > first_day)
        OR (subscription_end IS NULL)) 
        AND (segment = 87) THEN 1
      ELSE 0
    END AS is_active_87,
    CASE
      WHEN (subscription_start < first_day)
      AND ((subscription_end > first_day)
        OR (subscription_end IS NULL)) 
        AND (segment = 30) THEN 1
      ELSE 0
    END AS is_active_30,
    CASE
      WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment=87) THEN 1
      ELSE 0
    END AS is_canceled_87,
    CASE
      WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment=30) THEN 1
      ELSE 0
    END AS is_canceled_30
  FROM cross_join
),
-- total number of active/cancelled subscriptions monthly
status_aggregate AS(
  SELECT 
    month,
    SUM(is_active_87) AS sum_active_87,
    SUM(is_active_30) AS sum_active_30,
    SUM(is_canceled_87) AS sum_canceled_87, SUM(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY month
)
-- calculating segmented user churn rate
SELECT
 STRFTIME('%m', month) AS month,
 ROUND(1.0 * sum_canceled_87 / sum_active_87, 2) AS chrune_87,
 ROUND(1.0 * sum_canceled_30 / sum_active_30, 2) AS chrune_30
FROM status_aggregate;

-- calculating overall churn rate
SELECT 
  STRFTIME('%m', month) AS month,
  ROUND(1.0 * (sum_canceled_87 + sum_canceled_30) / (sum_active_87 + sum_active_30), 2) AS overall_churn
FROM status_aggregate;
