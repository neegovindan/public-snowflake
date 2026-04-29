================================================================================
SENSOR PIPELINE - BRONZE LAYER
================================================================================

-- Create Bronze raw table
CREATE OR REPLACE TABLE A_database.T_SCH.BRONZE_SENSOR_RAW (
    RAW_DATA        VARIANT     NOT NULL,
    SOURCE_FILE     VARCHAR,
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Load data from stage into Bronze
COPY INTO A_database.T_SCH.BRONZE_SENSOR_RAW (RAW_DATA, SOURCE_FILE)
FROM (
    SELECT $1, METADATA$FILENAME
    FROM @A_database.T_SCH.SENSOR_RAW_STAGE
)
FILE_FORMAT = A_database.T_SCH.SENSOR_JSON_FORMAT;
-- Result: 2,500 rows loaded

-- Create CDC stream on Bronze
CREATE OR REPLACE STREAM A_database.T_SCH.BRONZE_SENSOR_STREAM
  ON TABLE A_database.T_SCH.BRONZE_SENSOR_RAW
  APPEND_ONLY = TRUE;