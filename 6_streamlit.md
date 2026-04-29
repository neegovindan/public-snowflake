================================================================================
STREAMLIT DASHBOARD
================================================================================

--------------------------------------------------------------------------------
-- FILE: pyproject.toml
--------------------------------------------------------------------------------
[project]
name = "sensor_dashboard"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
  "streamlit[snowflake]==1.50.0",
  "plotly>=5.0.0",
  "pandas>=2.0.0"
]

--------------------------------------------------------------------------------
-- FILE: sensor_dashboard.py
--------------------------------------------------------------------------------
import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

st.set_page_config(page_title="Sensor Dashboard", layout="wide")
st.title("Electrical Meter Sensor Dashboard")

conn = st.connection("snowflake")

summary_df = conn.query("SELECT * FROM A_database.T_SCH.AGG_SENSOR_SUMMARY ORDER BY SENSOR_ID")
hourly_df = conn.query("SELECT * FROM A_database.T_SCH.AGG_SENSOR_HOURLY ORDER BY READING_DATE, READING_HOUR")
daily_df = conn.query("SELECT * FROM A_database.T_SCH.AGG_SENSOR_DAILY ORDER BY READING_DATE")

st.sidebar.header("Filters")
all_sensors = sorted(summary_df["SENSOR_ID"].unique())
selected_sensors = st.sidebar.multiselect("Sensor ID", all_sensors, default=all_sensors)

all_locations = sorted(summary_df["LOCATION"].unique())
selected_locations = st.sidebar.multiselect("Location", all_locations, default=all_locations)

if daily_df["READING_DATE"].dtype == "object":
    daily_df["READING_DATE"] = pd.to_datetime(daily_df["READING_DATE"])
if hourly_df["READING_DATE"].dtype == "object":
    hourly_df["READING_DATE"] = pd.to_datetime(hourly_df["READING_DATE"])

min_date = daily_df["READING_DATE"].min()
max_date = daily_df["READING_DATE"].max()
date_range = st.sidebar.date_input("Date Range", value=(min_date, max_date), min_value=min_date, max_value=max_date)

if len(date_range) == 2:
    start_date, end_date = date_range
else:
    start_date, end_date = min_date, max_date

f_summary = summary_df[
    (summary_df["SENSOR_ID"].isin(selected_sensors)) &
    (summary_df["LOCATION"].isin(selected_locations))
]
f_hourly = hourly_df[
    (hourly_df["SENSOR_ID"].isin(selected_sensors)) &
    (hourly_df["LOCATION"].isin(selected_locations)) &
    (hourly_df["READING_DATE"] >= pd.Timestamp(start_date)) &
    (hourly_df["READING_DATE"] <= pd.Timestamp(end_date))
]
f_daily = daily_df[
    (daily_df["SENSOR_ID"].isin(selected_sensors)) &
    (daily_df["LOCATION"].isin(selected_locations)) &
    (daily_df["READING_DATE"] >= pd.Timestamp(start_date)) &
    (daily_df["READING_DATE"] <= pd.Timestamp(end_date))
]

st.header("Overview")
k1, k2, k3, k4, k5 = st.columns(5)
k1.metric("Total Sensors", len(f_summary))
k2.metric("Total Readings", int(f_summary["TOTAL_READINGS"].sum()) if len(f_summary) > 0 else 0)
anomaly_rate = round(f_summary["TOTAL_ANOMALIES"].sum() / f_summary["TOTAL_READINGS"].sum() * 100, 2) if len(f_summary) > 0 and f_summary["TOTAL_READINGS"].sum() > 0 else 0
k3.metric("Anomaly Rate", f"{anomaly_rate}%")
k4.metric("Avg Power (W)", round(f_summary["AVG_POWER_WATTS"].mean(), 1) if len(f_summary) > 0 else 0)
healthy_count = len(f_summary[f_summary["HEALTH_STATUS"] == "HEALTHY"])
k5.metric("Healthy Sensors", f"{healthy_count}/{len(f_summary)}")

st.divider()

col1, col2 = st.columns(2)

with col1:
    st.subheader("Hourly Avg Voltage by Sensor")
    if len(f_hourly) > 0:
        hourly_viz = f_hourly.copy()
        hourly_viz["HOUR_LABEL"] = hourly_viz["READING_DATE"].dt.strftime("%m-%d") + " H" + hourly_viz["READING_HOUR"].astype(str)
        fig_volt = px.line(
            hourly_viz, x="HOUR_LABEL", y="AVG_VOLTAGE", color="SENSOR_ID",
            title="Voltage Trends (Hourly)"
        )
        fig_volt.add_hline(y=200, line_dash="dash", line_color="red", annotation_text="Low Threshold")
        fig_volt.add_hline(y=250, line_dash="dash", line_color="red", annotation_text="High Threshold")
        fig_volt.update_layout(xaxis_title="Time", yaxis_title="Voltage (V)", height=400)
        st.plotly_chart(fig_volt, use_container_width=True)
    else:
        st.info("No data for selected filters")

with col2:
    st.subheader("Hourly Avg Power by Sensor")
    if len(f_hourly) > 0:
        hourly_viz = f_hourly.copy()
        hourly_viz["HOUR_LABEL"] = hourly_viz["READING_DATE"].dt.strftime("%m-%d") + " H" + hourly_viz["READING_HOUR"].astype(str)
        fig_power = px.line(
            hourly_viz, x="HOUR_LABEL", y="AVG_POWER_WATTS", color="SENSOR_ID",
            title="Power Consumption Trends (Hourly)"
        )
        fig_power.update_layout(xaxis_title="Time", yaxis_title="Power (W)", height=400)
        st.plotly_chart(fig_power, use_container_width=True)
    else:
        st.info("No data for selected filters")

st.divider()

col3, col4 = st.columns(2)

with col3:
    st.subheader("Daily Energy Consumption")
    if len(f_daily) > 0:
        fig_energy = px.bar(
            f_daily, x="READING_DATE", y="TOTAL_ENERGY_KWH", color="SENSOR_ID",
            title="Daily Energy (kWh)", barmode="group"
        )
        fig_energy.update_layout(xaxis_title="Date", yaxis_title="Energy (kWh)", height=400)
        st.plotly_chart(fig_energy, use_container_width=True)
    else:
        st.info("No data for selected filters")

with col4:
    st.subheader("Daily Anomaly Count")
    if len(f_daily) > 0:
        fig_anomaly = px.bar(
            f_daily, x="READING_DATE", y="ANOMALY_COUNT", color="SENSOR_ID",
            title="Anomalies per Day", barmode="stack"
        )
        fig_anomaly.update_layout(xaxis_title="Date", yaxis_title="Anomaly Count", height=400)
        st.plotly_chart(fig_anomaly, use_container_width=True)
    else:
        st.info("No data for selected filters")

st.divider()

st.subheader("Sensor Health Summary")
if len(f_summary) > 0:
    health_display = f_summary[[
        "SENSOR_ID", "LOCATION", "METER_TYPE", "TOTAL_READINGS", "TOTAL_ENERGY_KWH",
        "AVG_VOLTAGE", "AVG_CURRENT", "AVG_POWER_WATTS", "AVG_POWER_FACTOR",
        "TOTAL_ANOMALIES", "ANOMALY_RATE_PCT", "AVG_UPTIME_PCT", "HEALTH_STATUS"
    ]].copy()

    def color_health(val):
        if val == "HEALTHY":
            return "background-color: #d4edda"
        elif val == "WARNING":
            return "background-color: #fff3cd"
        else:
            return "background-color: #f8d7da"

    styled = health_display.style.applymap(color_health, subset=["HEALTH_STATUS"])
    st.dataframe(styled, use_container_width=True, hide_index=True)
else:
    st.info("No data for selected filters")

--------------------------------------------------------------------------------
-- Streamlit Deployment SQL
--------------------------------------------------------------------------------

-- Create PyPI External Access Integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION PYPI_ACCESS_INTEGRATION
  ALLOWED_NETWORK_RULES = (snowflake.external_access.pypi_rule)
  ENABLED = TRUE;

-- Create stage for Streamlit files
CREATE STAGE IF NOT EXISTS A_database.T_SCH.STREAMLIT_STAGE;

-- Upload files to stage
COPY FILES INTO @A_database.T_SCH.STREAMLIT_STAGE/
  FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live'
  FILES=('sensor_dashboard.py', 'pyproject.toml');

-- Create Streamlit app
CREATE OR REPLACE STREAMLIT A_database.T_SCH.SENSOR_DASHBOARD
  FROM '@A_database.T_SCH.STREAMLIT_STAGE'
  MAIN_FILE = 'sensor_dashboard.py'
  RUNTIME_NAME = 'SYSTEM$ST_CONTAINER_RUNTIME_PY3_11'
  COMPUTE_POOL = SYSTEM_COMPUTE_POOL_CPU
  QUERY_WAREHOUSE = COMPUTE_WH
  EXTERNAL_ACCESS_INTEGRATIONS = (PYPI_ACCESS_INTEGRATION);

-- Deploy live version
ALTER STREAMLIT A_database.T_SCH.SENSOR_DASHBOARD ADD LIVE VERSION FROM LAST;

-- Dashboard Features:
--   - KPIs: Total Sensors, Total Readings, Anomaly Rate, Avg Power, Healthy Sensors
--   - Hourly Voltage Trends (line chart with threshold lines)
--   - Hourly Power Consumption Trends (line chart)
--   - Daily Energy Consumption (grouped bar chart)
--   - Daily Anomaly Count (stacked bar chart)
--   - Sensor Health Summary Table (color-coded by HEALTHY/WARNING/CRITICAL)
--   - Sidebar Filters: Sensor ID, Location, Date Range