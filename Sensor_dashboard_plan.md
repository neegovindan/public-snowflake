================================================================================
  SENSOR DASHBOARD PROJECT - COMPLETE DOCUMENTATION
  Generated: April 29, 2026
  Account: xyxyzz | User: a_user | Database: A_database | Schema: T_SCH
================================================================================


================================================================================
TABLE OF CONTENTS
================================================================================
  1. Project Overview & Architecture
  2. Plan (Original Approved Plan)
  3. Conversation Summary
  4. Phase 4: Sensor Pipeline - Infrastructure Setup
  5. Phase 5: Sensor Pipeline - Bronze Layer
  6. Phase 6: Sensor Pipeline - Silver Layer
  7. Phase 7: Sensor Pipeline - Gold Layer
  8. Phase 8: dbt Aggregation Layer (Full Project)
  9. Phase 9: Streamlit Dashboard
 10. All Snowflake Objects Created
 11. Troubleshooting Notes


================================================================================
1. PROJECT OVERVIEW & ARCHITECTURE
================================================================================

This project implements a full end-to-end sensor data pipeline for electrical
meter readings in Snowflake, along with a Security & Compliance Agent and
a Streamlit dashboard for visualization.

Architecture Diagram:

  JSON File --> @SENSOR_RAW_STAGE --> [COPY INTO]
                                          |
                              BRONZE_SENSOR_RAW (VARIANT)
                                          |
                                   (stream + task, 5 min)
                                          |
                              SILVER_SENSOR_READINGS (typed, cleansed)
                                          |
                                   (stream + chained task)
                                          |
                              GOLD_SENSOR_METRICS (enriched + anomaly flags)
                                          |
                                        (dbt)
                                          |
                 AGG_SENSOR_HOURLY / AGG_SENSOR_DAILY / AGG_SENSOR_SUMMARY
                                          |
                              SENSOR_DASHBOARD (Streamlit)

Sensor Data:
  - 5 sensors: EM-001 to EM-005
  - Locations: Building-A-Floor1/2, Building-B-Floor1/2, Building-C-Floor1
  - Meter types: single_phase, three_phase
  - Readings: voltage, current, power, energy, power_factor, frequency
  - Anomaly thresholds: voltage <200 or >250V, current <0 or >15A, power_factor <0.7
  - 2,500 sample records, 104 anomalies (~4.16%)


================================================================================
2. PLAN (ORIGINAL APPROVED PLAN)
================================================================================

Step 1: Setup - Stage & File Format
  - Create internal stage SENSOR_RAW_STAGE for JSON file uploads
  - Create JSON file format SENSOR_JSON_FORMAT
  - Generate sample JSON sensor data (electrical meter readings) and load

Step 2: Bronze Layer - Raw Ingestion
  - Create BRONZE_SENSOR_RAW table with VARIANT column + metadata
  - COPY INTO from stage to bronze (raw JSON, no transformation)
  - Create stream BRONZE_SENSOR_STREAM for CDC

Step 3: Silver Layer - Cleansed & Typed
  - Create SILVER_SENSOR_READINGS table with typed columns
  - Create task that reads from bronze stream, parses JSON, inserts into silver
  - Create stream SILVER_SENSOR_STREAM on silver table

Step 4: Gold Layer - Enriched & Curated
  - Create GOLD_SENSOR_METRICS table with derived columns and anomaly flags
  - Create chained task from silver stream to gold

Step 5: dbt Project - Aggregation Layer
  - Build dbt project with models:
    - stg_sensor_metrics (staging view)
    - agg_sensor_hourly (hourly averages)
    - agg_sensor_daily (daily averages + uptime)
    - agg_sensor_summary (overall health scores)
  - Include dbt tests

Step 6: Streamlit Dashboard
  - Build Streamlit app reading from dbt aggregate tables
  - KPIs, hourly trends, daily summary, sensor health, filters
