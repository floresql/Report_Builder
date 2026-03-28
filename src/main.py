from snowflake_handler import SnowflakeSQLRunner
from excel_export import export_to_excel
from config import Config, SQL_DIR, PROCESSED_DATA_DIR
from loguru import logger
import sys
import os
from pathlib import WindowsPath


# Generates a list of file paths based on schemas and file type
# ---------------------------------------------------------------
def get_file_paths(base_path, file_types):
    paths = []
    for file_type in file_types:
        paths.append(f"{base_path}{file_type}.xlsx")
    return paths

# Function to run the Snowflake SQL execution process
# ---------------------------------------------------------------
def main():
    """ Main function that sets up the snowflake SnowflakeSQLRunner class to
    run queries and export_to_excel function to output results in Excel. """

    # List of schemas to loop through
    schemas_to_process = ['OPS$CNE', 'OPS$EA2', 'OPS$MAN'] 
    sql_directory = SQL_DIR
    queries_to_run = {}

    # Ensure the directory exists
    if os.path.exists(sql_directory) and os.path.isdir(sql_directory):
        # Loop through all items in the directory
        for filename in os.listdir(sql_directory):
            # Check if the file is a SQL file
            if filename.endswith('.sql'):
                # The key is the filename without the .sql extension
                key = os.path.splitext(filename)[0]
                # The value is the full filename
                queries_to_run[key] = filename
    else:
        print(f"Directory not found: {sql_directory}")
        # You might want to handle this case differently, such as exiting or raising an error
        return
    
    # A list to store the dataframes from each loop iteration
    all_dfs = []

    # Process each query type
    for query_name, sql_file_name in queries_to_run.items():
        sql_file_path = os.path.join(SQL_DIR, sql_file_name)
        excel_file_paths = rf"{PROCESSED_DATA_DIR}\{query_name}.xlsx"

        # Loop through different schemas
        for schema, excel_file_path in zip(schemas_to_process, excel_file_paths):
            try:
                with SnowflakeSQLRunner(
                    key_file=Config.RSA_KEY_FILE,
                    account=Config.SNOWFLAKE_ACCOUNT,
                    user=Config.SNOWFLAKE_USER,
                    warehouse=Config.SNOWFLAKE_WAREHOUSE,
                    database=Config.SNOWFLAKE_DATABASE,
                    schema=schema,
                    role=Config.SNOWFLAKE_ROLE
                ) as runner:
                    # Execute the SQL query and capture the result in a DataFrame
                    df_result = runner.execute_query(sql_file_path)

                    if df_result is not None:
                        # Capitalize all column names in the DataFrame
                        df_result.columns = df_result.columns.str.upper()
                        # Define default columns based on the query name
                        DEFAULT_COLUMNS = df_result.columns.tolist()
                        try:
                            if not df_result.empty:
                                # Reindex to ensure consistent column order
                                df_to_export = df_result.reindex(columns=DEFAULT_COLUMNS)
                                # Append the non-empty dataframe to the list
                                all_dfs.append(df_to_export)
                        except Exception as e:
                            logger.error(f"Failed to process DataFrame: {e}")       
            except Exception as e:
                logger.error(f"An unexpected error occurred in the main block: {e}")
                sys.exit(1)

        # Export all three queries to one excel file
        export_to_excel(all_dfs, excel_file_paths, "Sheet1", DEFAULT_COLUMNS)
        # Clear dataframes for next loop iteration
        all_dfs = []

# Launch main function
# ---------------------------------------------------------------
if __name__ == "__main__":
    main()