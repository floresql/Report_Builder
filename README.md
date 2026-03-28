# Report Builder

A structured Python framework designed to automate the end-to-end lifecycle of data reporting, from Snowflake extraction to Excel distribution.

## Project Structure

Report Builder/
├── .archive/               # Old files/processes no longer in use
├── .logs/                  # Logs of the backup and push to PROD process
├── reference/              # Data dictionaries, manuals, etc.
├── reports/                # Individual reports folder
│   └── Report_Name/        # Content specific to a single report
│       ├── data/
│       │   ├── external/   # Third party sources (e.g., FOA)
│       │   ├── processed/  # Final, canonical data sets
│       │   └── raw/        # Original, immutable data
│       ├── email/          # Scripts/files for distribution
│       ├── logs/           # Project run and error logs
│       ├── macros/         # Scripts to format processed data
│       ├── Report_Name.xlsx
│       └── start_process.bat
├── src/                    # Source code package
│   ├── sql/                # SQL files for main.py to execute
│   ├── __init__.py
│   ├── config.py           # Variables and configuration
│   ├── excel_export.py     # Exports results to Excel
│   ├── external_data.py    # Scripts for external data fetching
│   ├── main.py             # Main entry point
│   └── snowflake_handler.py
├── .env                    # Environment variables
├── .gitignore              # Git exclusion rules
├── README.md               # Top-level documentation
└── requirements.txt        # Dependencies

## Overview
This project automates the execution of SQL queries across multiple schemas, processes the results, and generates formatted Excel reports. It features a modular architecture where adding a new report is managed by placing SQL files into the source directory and configuring the execution flow via the central engine.

## Key Components
* main.py: The central orchestrator that manages the flow from data fetch to final export.
* snowflake_handler.py: A dedicated class to manage secure connections and query execution in Snowflake.
* external_data.py: Scripts to download or generate data from third-party sources (e.g., FOA).
* excel_export.py: Exports query results to Excel within the processed data folders.

## Getting Started

### Prerequisites
* Python 3.x
* Snowflake account credentials (configured in config.py/env)

### Installation
1. Clone the repository.
2. Install dependencies:
   pip install -r requirements.txt
3. Update src/config.py with your environment variables and database settings.

## Usage: Adding a New Report
To add a new report to the pipeline:
1. Create a new directory within /reports/ following the "Report_Name" template.
2. Ensure the sub-folder structure (data/raw, data/processed, etc.) is present.
3. Drop the required SQL script into src/sql/.
4. The main.py engine will detect the new SQL file, execute it against Snowflake, and route the output to the corresponding processed data folder.

### Running the Pipeline
To execute a report, run the batch file:
Start_Process.bat

This triggers the SQL queries, processes the data, generates the Excel reports, and prepares them for email distribution.
***Note: Reports are currently scheduled via Windows Task Scheduler to avoid manual report runs.*** 

## Data Lifecycle
1. Raw: Original, immutable data dumps from the source.
2. External: Supporting data from third-party providers.
3. Processed: The final, canonical datasets used for the finished report.
