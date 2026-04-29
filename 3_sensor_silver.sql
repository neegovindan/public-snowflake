================================================================================
SENSOR PIPELINE - SILVER LAYER
================================================================================

-- Create Silver typed table
CREATE OR REPLACE TABLE A_database.T_SCH.SILVER_SENSOR_READINGS (
    READING_ID          VARCHAR DEFAULT UUID_STRING(),
    SENSOR_ID           VARCHAR     NOT NULL,
    READING_TIMESTAMP   TIMESTAMP_NTZ NOT NULL,
    VOLTAGE             FLOAT,
    CURRENT_AMP         FLOAT,
    POWER_WATTS         FLOAT,
    ENERGY_KWH          FLOAT,
    POWER_FACTOR        FLOAT,
    FREQUENCY_HZ        FLOAT,
    LOCATION            VARCHAR,
    METER_TYPE          VARCHAR,
    SOURCE_FILE         VARCHAR,
    LOADED_AT           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Create scheduled task: Bronze stream -> Silver
CREATE OR REPLACE TASK A_database.T_SCH.TASK_BRONZE_TO_SILVER
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = '5 MINUTE'
WHEN
  SYSTEM$STREAM_HAS_DATA('A_database.T_SCH.BRONZE_SENSOR_STREAM')
AS
INSERT INTO A_database.T_SCH.SILVER_SENSOR_READINGS (
    SENSOR_ID, READING_TIMESTAMP, VOLTAGE, CURRENT_AMP,
    POWER_WATTS, ENERGY_KWH, POWER_FACTOR, FREQUENCY_HZ,
    LOCATION, METER_TYPE, SOURCE_FILE
)
SELECT
    RAW_DATA:sensor_id::VARCHAR,
    TRY_TO_TIMESTAMP_NTZ(RAW_DATA:reading_timestamp::VARCHAR),
    RAW_DATA:voltage::FLOAT,
    RAW_DATA:current_amp::FLOAT,
    RAW_DATA:power_watts::FLOAT,
    RAW_DATA:energy_kwh::FLOAT,
    RAW_DATA:power_factor::FLOAT,
    RAW_DATA:frequency_hz::FLOAT,
    RAW_DATA:location::VARCHAR,
    RAW_DATA:meter_type::VARCHAR,
    SOURCE_FILE
FROM A_database.T_SCH.BRONZE_SENSOR_STREAM
WHERE RAW_DATA:sensor_id IS NOT NULL
  AND RAW_DATA:reading_timestamp IS NOT NULL;

-- Initial load (since stream was created after bronze load)
INSERT INTO A_database.T_SCH.SILVER_SENSOR_READINGS (
    SENSOR_ID, READING_TIMESTAMP, VOLTAGE, CURRENT_AMP,
    POWER_WATTS, ENERGY_KWH, POWER_FACTOR, FREQUENCY_HZ,
    LOCATION, METER_TYPE, SOURCE_FILE
)
SELECT
    RAW_DATA:sensor_id::VARCHAR,
    TRY_TO_TIMESTAMP_NTZ(RAW_DATA:reading_timestamp::VARCHAR),
    RAW_DATA:voltage::FLOAT,
    RAW_DATA:current_amp::FLOAT,
    RAW_DATA:power_watts::FLOAT,
    RAW_DATA:energy_kwh::FLOAT,
    RAW_DATA:power_factor::FLOAT,
    RAW_DATA:frequency_hz::FLOAT,
    RAW_DATA:location::VARCHAR,
    RAW_DATA:meter_type::VARCHAR,
    SOURCE_FILE
FROM A_database.T_SCH.BRONZE_SENSOR_RAW
WHERE RAW_DATA:sensor_id IS NOT NULL
  AND RAW_DATA:reading_timestamp IS NOT NULL;
-- Result: 2,500 rows inserted

-- Create CDC stream on Silver
CREATE OR REPLACE STREAM A_database.T_SCH.SILVER_SENSOR_STREAM
  ON TABLE A_database.T_SCH.SILVER_SENSOR_READINGS
  APPEND_ONLY = TRUE;