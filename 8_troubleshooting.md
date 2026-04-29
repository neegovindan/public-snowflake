================================================================================
14. TROUBLESHOOTING NOTES
================================================================================

Issue 1: Agent missing warehouse
  - Error: "The Analyst tool orders_analyst is missing an execution environment"
  - Fix: Added execution_environment with type "warehouse" to tool_resources

Issue 2: pyproject.toml missing
  - Error: Streamlit container runtime requires pyproject.toml
  - Fix: Created pyproject.toml with project dependencies

Issue 3: TOML parse error (dependencies as map)
  - Error: "invalid type: map, expected a sequence" on [project.dependencies]
  - Fix: Changed from TOML map format to list format:
    dependencies = ["streamlit>=1.48.0", "plotly", ...]

Issue 4: PyPI DNS resolution failure
  - Error: "failed to lookup address information: Name does not resolve"
  - Fix: Created PYPI_ACCESS_INTEGRATION using snowflake.external_access.pypi_rule

Issue 5: Streamlit version too old
  - Error: "Failed to get the version of the Streamlit library. >=1.48.0"
  - Fix: Changed to streamlit[snowflake]==1.50.0 (includes Snowpark)

================================================================================
END OF DOCUMENTATION
================================================================================
