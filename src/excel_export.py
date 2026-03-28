import pandas as pd
import numpy as np
from loguru import logger
from snowflake_handler import SnowflakeSQLRunner

def export_to_excel(all_dfs, excel_file, sheet_name, DEFAULT_COLUMNS):
    """Method to export a DataFrame to a macro-enabled Excel file (.xlsm)."""
    logger.info(f"Exporting data to Excel file.")
    if not all_dfs:
        try:
            # Handle the case where all loops resulted in an empty DataFrame
            num_columns = len(DEFAULT_COLUMNS)
            plus_columns = num_columns - 1
            df_to_export = pd.DataFrame(
                data=[['** No Records **'] + [np.nan] * plus_columns],
                columns=DEFAULT_COLUMNS
            )
            # Use 'openpyxl' engine to write to .xlsm
            df_to_export.to_excel(excel_file, index=False, sheet_name=sheet_name, engine='openpyxl')
            logger.info(f"No data found. Exported 'No Records' to Excel: {excel_file}.")
        except Exception as e:
            logger.error(f"Failed to export 'No Records' message to Excel: {e}")
    else:
        try:
            combined_df = pd.concat(all_dfs, ignore_index=True)
            # Use 'openpyxl' engine to write to .xlsm
            combined_df.to_excel(excel_file, index=False, sheet_name=sheet_name, engine='openpyxl')
            logger.success(f"All DataFrames combined and exported to Excel: {excel_file} on sheet: {sheet_name}")
        except Exception as e:
            logger.error(f"Failed to export combined DataFrame to Excel: {e}")

