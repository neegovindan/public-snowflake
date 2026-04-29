================================================================================
DBT AGGREGATION LAYER (FULL PROJECT)
================================================================================

-- Project location: /sensor_analytics/ in Workspaces

--------------------------------------------------------------------------------
-- FILE: sensor_analytics/profiles.yml
--------------------------------------------------------------------------------
default:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: GTB47925
      user: GOVINDAN
      role: ACCOUNTADMIN
      database: A_database
      warehouse: COMPUTE_WH
      schema: T_SCH
      threads: 4

--------------------------------------------------------------------------------
-- FILE: sensor_analytics/dbt_project.yml
--------------------------------------------------------------------------------
name: 'sensor_analytics'
version: '1.0.0'

profile: 'default'

model-paths: ["models"]
test-paths: ["tests"]
macro-paths: ["macros"]
seed-paths: ["seeds"]

clean-targets:
  - "target"
  - "dbt_packages"

models:
  sensor_analytics:
    staging:
      +materialized: view
    aggregation:
      +materialized: table

--------------------------------------------------------------------------------
-- FILE: sensor_analytics/models/staging/sources.yml
--------------------------------------------------------------------------------
version: 2

sources:
  - name: sensor_data
    database: A_database
    schema: T_SCH
    tables:
      - name: GOLD_SENSOR_METRICS
        description: "Enriched sensor readings with anomaly flags from the Gold layer"
        columns:
          - name: READING_ID
            tests:
              - not_null
          - name: SENSOR_ID
            tests:
              - not_null
          - name: READING_TIMESTAMP
            tests:
              - not_null

--------------------------------------------------------------------------------
-- FILE: sensor_analytics/models/staging/stg_sensor_metrics.sql
--------------------------------------------------------------------------------
SELECT
    READING_ID,
    SENSOR_ID,
    READING_TIMESTAMP,
    READING_DATE,
    READING_HOUR,
    VOLTAGE,
    CURRENT_AMP,
    POWER_WATTS,
    ENERGY_KWH,
    POWER_FACTOR,
    FREQUENCY_HZ,
    LOCATION,
    METER_TYPE,
    IS_VOLTAGE_ANOMALY,
    IS_CURRENT_ANOMALY,
    IS_POWER_FACTOR_ANOMALY,
    IS_ANOMALY,
    ANOMALY_REASON,
    ENRICHED_AT
FROM {{ source('sensor_data', 'GOLD_SENSOR_METRICS') }}

--------------------------------------------------------------------------------
-- FILE: sensor_analytics/models/aggregation/agg_sensor_hourly.sql
--------------------------------------------------------------------------------
SELECT
    SENSOR_ID,
    READING_DATE,
    READING_HOUR,
    LOCATION,
    METER_TYPE,
    COUNT(*) AS READING_COUNT,
    ROUND(AVG(VOLTAGE), 2) AS AVG_VOLTAGE,
    ROUND(MIN(VOLTAGE), 2) AS MIN_VOLTAGE,
    ROUND(MAX(VOLTAGE), 2) AS MAX_VOLTAGE,
    ROUND(AVG(CURRENT_AMP), 3) AS AVG_CURRENT,
    ROUND(MIN(CURRENT_AMP), 3) AS MIN_CURRENT,
    ROUND(MAX(CURRENT_AMP), 3) AS MAX_CURRENT,
    ROUND(AVG(POWER_WATTS), 2) AS AVG_POWER_WATTS,
    ROUND(MIN(POWER_WATTS), 2) AS MIN_POWER_WATTS,
    ROUND(MAX(POWER_WATTS), 2) AS MAX_POWER_WATTS,
    ROUND(SUM(ENERGY_KWH), 3) AS TOTAL_ENERGY_KWH,
    ROUND(AVG(POWER_FACTOR), 3) AS AVG_POWER_FACTOR,
    ROUND(AVG(FREQUENCY_HZ), 2) AS AVG_FREQUENCY_HZ,
    SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) AS ANOMALY_COUNT,
    ROUND(SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ANOMALY_RATE_PCT
FROM {{ ref('stg_sensor_metrics') }}
GROUP BY
    SENSOR_ID, READING_DATE, READING_HOUR, LOCATION, METER_TYPE

--------------------------------------------------------------------------------
-- FILE: sensor_analytics/models/aggregation/agg_sensor_daily.sql
--------------------------------------------------------------------------------
SELECT
    SENSOR_ID,
    READING_DATE,
    LOCATION,
    METER_TYPE,
    COUNT(*) AS READING_COUNT,
    ROUND(AVG(VOLTAGE), 2) AS AVG_VOLTAGE,
    ROUND(MIN(VOLTAGE), 2) AS MIN_VOLTAGE,
    ROUND(MAX(VOLTAGE), 2) AS MAX_VOLTAGE,
    ROUND(AVG(CURRENT_AMP), 3) AS AVG_CURRENT,
    ROUND(MIN(CURRENT_AMP), 3) AS MIN_CURRENT,
    ROUND(MAX(CURRENT_AMP), 3) AS MAX_CURRENT,
    ROUND(AVG(POWER_WATTS), 2) AS AVG_POWER_WATTS,
    ROUND(MIN(POWER_WATTS), 2) AS MIN_POWER_WATTS,
    ROUND(MAX(POWER_WATTS), 2) AS MAX_POWER_WATTS,
    ROUND(SUM(ENERGY_KWH), 3) AS TOTAL_ENERGY_KWH,
    ROUND(AVG(ENERGY_KWH), 3) AS AVG_ENERGY_KWH,
    ROUND(AVG(POWER_FACTOR), 3) AS AVG_POWER_FACTOR,
    ROUND(MIN(POWER_FACTOR), 3) AS MIN_POWER_FACTOR,
    ROUND(AVG(FREQUENCY_HZ), 2) AS AVG_FREQUENCY_HZ,
    SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) AS ANOMALY_COUNT,
    ROUND(SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ANOMALY_RATE_PCT,
    24 AS EXPECTED_HOURS,
    COUNT(DISTINCT READING_HOUR) AS ACTIVE_HOURS,
    ROUND(COUNT(DISTINCT READING_HOUR) * 100.0 / 24, 2) AS UPTIME_PCT,
    24 - COUNT(DISTINCT READING_HOUR) AS MISSING_HOURS
FROM {{ ref('stg_sensor_metrics') }}
GROUP BY
    SENSOR_ID, READING_DATE, LOCATION, METER_TYPE

--------------------------------------------------------------------------------
-- FILE: sensor_analytics/models/aggregation/agg_sensor_summary.sql
--------------------------------------------------------------------------------
SELECT
    SENSOR_ID,
    LOCATION,
    METER_TYPE,
    COUNT(*) AS TOTAL_READINGS,
    COUNT(DISTINCT READING_DATE) AS ACTIVE_DAYS,
    MIN(READING_TIMESTAMP) AS FIRST_READING,
    MAX(READING_TIMESTAMP) AS LAST_READING,
    ROUND(AVG(VOLTAGE), 2) AS AVG_VOLTAGE,
    ROUND(MIN(VOLTAGE), 2) AS MIN_VOLTAGE,
    ROUND(MAX(VOLTAGE), 2) AS MAX_VOLTAGE,
    ROUND(STDDEV(VOLTAGE), 2) AS STDDEV_VOLTAGE,
    ROUND(AVG(CURRENT_AMP), 3) AS AVG_CURRENT,
    ROUND(MIN(CURRENT_AMP), 3) AS MIN_CURRENT,
    ROUND(MAX(CURRENT_AMP), 3) AS MAX_CURRENT,
    ROUND(AVG(POWER_WATTS), 2) AS AVG_POWER_WATTS,
    ROUND(MIN(POWER_WATTS), 2) AS MIN_POWER_WATTS,
    ROUND(MAX(POWER_WATTS), 2) AS MAX_POWER_WATTS,
    ROUND(SUM(ENERGY_KWH), 3) AS TOTAL_ENERGY_KWH,
    ROUND(AVG(POWER_FACTOR), 3) AS AVG_POWER_FACTOR,
    ROUND(MIN(POWER_FACTOR), 3) AS MIN_POWER_FACTOR,
    ROUND(AVG(FREQUENCY_HZ), 2) AS AVG_FREQUENCY_HZ,
    SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) AS TOTAL_ANOMALIES,
    ROUND(SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ANOMALY_RATE_PCT,
    SUM(CASE WHEN IS_VOLTAGE_ANOMALY THEN 1 ELSE 0 END) AS VOLTAGE_ANOMALIES,
    SUM(CASE WHEN IS_CURRENT_ANOMALY THEN 1 ELSE 0 END) AS CURRENT_ANOMALIES,
    SUM(CASE WHEN IS_POWER_FACTOR_ANOMALY THEN 1 ELSE 0 END) AS POWER_FACTOR_ANOMALIES,
    ROUND(COUNT(DISTINCT READING_HOUR) * 100.0 / (COUNT(DISTINCT READING_DATE) * 24), 2) AS AVG_UPTIME_PCT,
    CASE
        WHEN SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) * 100.0 / COUNT(*) < 2
            AND COUNT(DISTINCT READING_HOUR) * 100.0 / (COUNT(DISTINCT READING_DATE) * 24) > 90
        THEN 'HEALTHY'
        WHEN SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) * 100.0 / COUNT(*) < 5
            AND COUNT(DISTINCT READING_HOUR) * 100.0 / (COUNT(DISTINCT READING_DATE) * 24) > 70
        THEN 'WARNING'
        ELSE 'CRITICAL'
    END AS HEALTH_STATUS
FROM {{ ref('stg_sensor_metrics') }}
GROUP BY
    SENSOR_ID, LOCATION, METER_TYPE

--------------------------------------------------------------------------------
-- FILE: sensor_analytics/models/schema.yml
--------------------------------------------------------------------------------
version: 2

models:
  - name: stg_sensor_metrics
    description: "Staging view over the Gold sensor metrics table"
    columns:
      - name: READING_ID
        tests:
          - not_null
      - name: SENSOR_ID
        tests:
          - not_null
      - name: READING_TIMESTAMP
        tests:
          - not_null
      - name: METER_TYPE
        tests:
          - accepted_values:
              values: ['single_phase', 'three_phase']

  - name: agg_sensor_hourly
    description: "Hourly aggregated sensor metrics with anomaly rates"
    columns:
      - name: SENSOR_ID
        tests:
          - not_null
      - name: READING_DATE
        tests:
          - not_null
      - name: READING_HOUR
        tests:
          - not_null
      - name: READING_COUNT
        tests:
          - not_null

  - name: agg_sensor_daily
    description: "Daily aggregated sensor metrics with uptime and health indicators"
    columns:
      - name: SENSOR_ID
        tests:
          - not_null
      - name: READING_DATE
        tests:
          - not_null
      - name: READING_COUNT
        tests:
          - not_null
      - name: UPTIME_PCT
        tests:
          - not_null

  - name: agg_sensor_summary
    description: "Overall sensor summary with health status and anomaly rates"
    columns:
      - name: SENSOR_ID
        tests:
          - not_null
          - unique
      - name: HEALTH_STATUS
        tests:
          - not_null
          - accepted_values:
              values: ['HEALTHY', 'WARNING', 'CRITICAL']
      - name: TOTAL_READINGS
        tests:
          - not_null

--------------------------------------------------------------------------------
-- DBT RUN RESULTS
--------------------------------------------------------------------------------
-- dbt run: PASS=4 WARN=0 ERROR=0 SKIP=0 TOTAL=4
--   1. stg_sensor_metrics (view) ......... SUCCESS in 0.81s
--   2. agg_sensor_daily (table) .......... SUCCESS in 1.63s
--   3. agg_sensor_hourly (table) ......... SUCCESS in 1.67s
--   4. agg_sensor_summary (table) ........ SUCCESS in 1.64s

-- dbt test: PASS=20 WARN=0 ERROR=0 SKIP=0 TOTAL=20
--   All not_null, unique, and accepted_values tests passed.
