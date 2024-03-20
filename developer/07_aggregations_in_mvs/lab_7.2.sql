--Step 2:
CREATE TABLE uk_prices_aggs_dest (
    month Date,
    min_price SimpleAggregateFunction(min, UInt32),
    max_price SimpleAggregateFunction(max, UInt32),
    volume AggregateFunction(count, UInt32),
    avg_price AggregateFunction(avg, UInt32)
)
ENGINE = AggregatingMergeTree
PRIMARY KEY month;

CREATE MATERIALIZED VIEW uk_prices_aggs_view
TO uk_prices_aggs_dest
AS
    WITH
        toStartOfMonth(date) AS month
    SELECT
        month,
        minSimpleState(price) AS min_price,
        maxSimpleState(price) AS max_price,
        countState(price) AS volume,
        avgState(price) AS avg_price
    FROM uk_price_paid
    GROUP BY month;

INSERT INTO uk_prices_aggs_dest
    WITH
        toStartOfMonth(date) AS month
    SELECT
        month,
        minSimpleState(price) AS min_price,
        maxSimpleState(price) AS max_price,
        countState(price) AS volume,
        avgState(price) AS avg_price
    FROM uk_price_paid
    WHERE date < toDate('2024-01-01')
    GROUP BY month;

--Step 4:
SELECT
    month,
    min(min_price),
    max(max_price)
FROM uk_prices_aggs_dest
WHERE
    month >= (toStartOfMonth(now()) - (INTERVAL 12 MONTH))
    AND month < toStartOfMonth(now())
GROUP BY month
ORDER BY month DESC;

--Step 5:
SELECT
    month,
    avgMerge(avg_price)
FROM uk_prices_aggs_dest
WHERE
    month >= (toStartOfMonth(now()) - (INTERVAL 2 YEAR))
    AND month < toStartOfMonth(now())
GROUP BY month
ORDER BY month DESC;

--Step 6:
SELECT
    countMerge(volume)
FROM uk_prices_aggs_dest
WHERE toYear(month) = '2020';