================================================================================
ALL SNOWFLAKE OBJECTS CREATED
================================================================================

-- Semantic Views
A_database.T_SCH.ORDERS_SV                     -- Semantic view on ORDERS table
A_database.T_SCH.SECURITY_COMPLIANCE_SV        -- Semantic view on secured ACCOUNT_USAGE views

-- Agents
A_database.T_SCH.SECURITY_DATA_AGENT           -- Cortex Agent (orders + security analyst)

-- Row-Level Security
A_database.T_SCH.TEAM_ACCESS_MAP               -- Team/role access mapping table
A_database.T_SCH.V_SECURE_LOGIN_HISTORY        -- Secure view (LOGIN_HISTORY + RLS)
A_database.T_SCH.V_SECURE_QUERY_HISTORY        -- Secure view (QUERY_HISTORY + RLS)
A_database.T_SCH.V_SECURE_GRANTS_TO_ROLES      -- Secure view (GRANTS_TO_ROLES + RLS)

-- Sensor Pipeline - Infrastructure
A_database.T_SCH.SENSOR_JSON_FORMAT            -- JSON file format
A_database.T_SCH.SENSOR_RAW_STAGE              -- Internal stage

-- Sensor Pipeline - Bronze
A_database.T_SCH.BRONZE_SENSOR_RAW             -- Raw VARIANT table
A_database.T_SCH.BRONZE_SENSOR_STREAM          -- CDC stream on bronze

-- Sensor Pipeline - Silver
A_database.T_SCH.SILVER_SENSOR_READINGS        -- Typed/cleansed table
A_database.T_SCH.SILVER_SENSOR_STREAM          -- CDC stream on silver
A_database.T_SCH.TASK_BRONZE_TO_SILVER         -- Scheduled task (5 min)

-- Sensor Pipeline - Gold
A_database.T_SCH.GOLD_SENSOR_METRICS           -- Enriched table with anomaly flags
A_database.T_SCH.TASK_SILVER_TO_GOLD           -- Chained task

-- dbt Aggregation (materialized in A_database.T_SCH)
A_database.T_SCH.STG_SENSOR_METRICS            -- View (staging)
A_database.T_SCH.AGG_SENSOR_HOURLY             -- Table (hourly aggregates)
A_database.T_SCH.AGG_SENSOR_DAILY              -- Table (daily aggregates)
A_database.T_SCH.AGG_SENSOR_SUMMARY            -- Table (sensor health summary)

-- Streamlit
A_database.T_SCH.STREAMLIT_STAGE               -- Stage for app files
A_database.T_SCH.SENSOR_DASHBOARD              -- Streamlit app
PYPI_ACCESS_INTEGRATION                        -- External access integration for PyPI
