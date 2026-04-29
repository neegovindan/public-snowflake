================================================================================
SENSOR PIPELINE - INFRASTRUCTURE SETUP
================================================================================

-- Create JSON file format
CREATE OR REPLACE FILE FORMAT A_database.T_SCH.SENSOR_JSON_FORMAT
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE
  STRIP_NULL_VALUES = TRUE;

-- Create internal stage
CREATE OR REPLACE STAGE A_database.T_SCH.SENSOR_RAW_STAGE
  FILE_FORMAT = A_database.T_SCH.SENSOR_JSON_FORMAT;

-- Generate sample electrical meter sensor data (2,500 records, 5 sensors)
CREATE OR REPLACE TEMPORARY TABLE A_database.T_SCH.TEMP_SENSOR_DATA AS
WITH sensors AS (
    SELECT column1 AS sensor_id, column2 AS location, column3 AS meter_type
    FROM VALUES
        ('EM-001', 'Building-A-Floor1', 'single_phase'),
        ('EM-002', 'Building-A-Floor2', 'three_phase'),
        ('EM-003', 'Building-B-Floor1', 'single_phase'),
        ('EM-004', 'Building-B-Floor2', 'three_phase'),
        ('EM-005', 'Building-C-Floor1', 'single_phase')
),
time_series AS (
    SELECT DATEADD('minute', -15 * SEQ4(), CURRENT_TIMESTAMP()) AS reading_ts
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT OBJECT_CONSTRUCT(
    'sensor_id', s.sensor_id,
    'reading_timestamp', TO_VARCHAR(t.reading_ts, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"'),
    'voltage', ROUND(220 + UNIFORM(-15, 15, RANDOM()) + (CASE WHEN UNIFORM(0, 100, RANDOM()) < 3 THEN UNIFORM(-50, 50, RANDOM()) ELSE 0 END), 2),
    'current_amp', ROUND(5 + UNIFORM(-2, 8, RANDOM())::FLOAT / 10 + (CASE WHEN UNIFORM(0, 100, RANDOM()) < 3 THEN UNIFORM(10, 20, RANDOM()) ELSE 0 END), 3),
    'power_watts', ROUND((220 + UNIFORM(-10, 10, RANDOM())) * (5 + UNIFORM(-2, 5, RANDOM())::FLOAT / 10) * (0.85 + UNIFORM(-5, 10, RANDOM())::FLOAT / 100), 2),
    'energy_kwh', ROUND(UNIFORM(50, 500, RANDOM())::FLOAT / 10, 3),
    'power_factor', ROUND(0.85 + UNIFORM(-10, 14, RANDOM())::FLOAT / 100, 3),
    'frequency_hz', ROUND(50 + UNIFORM(-5, 5, RANDOM())::FLOAT / 100, 2),
    'location', s.location,
    'meter_type', s.meter_type
) AS json_data
FROM sensors s
CROSS JOIN time_series t;

-- Export sample data to stage
COPY INTO @A_database.T_SCH.SENSOR_RAW_STAGE/electrical_meter_readings
FROM (SELECT json_data FROM A_database.T_SCH.TEMP_SENSOR_DATA)
FILE_FORMAT = (TYPE = 'JSON')
OVERWRITE = TRUE;
-- Result: 2,500 rows unloaded


