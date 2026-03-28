# ----------------------------------------------------------
# import packages
# ----------------------------------------------------------
import subprocess
from pathlib import Path
from loguru import logger
try:
    # Prefer package-style import when running inside the project
    from config import Config, EXTERNAL_DATA_DIR
except Exception:
    # Fallback so this file can be executed directly (python external_data.py)
    import sys
    from pathlib import Path as _Path

    _repo_root = _Path(__file__).resolve().parents[1]
    if str(_repo_root) not in sys.path:
        sys.path.insert(0, str(_repo_root))
    from config import Config, EXTERNAL_DATA_DIR
import os

# ----------------------------------------------------------
# Function downloads an Excel file using PowerShell.
# ----------------------------------------------------------
def download_excel_file(destination_file: Path):
    """ Function downloads external data from FOA for Drop Bury report."""
    LOG_FILE_PATH = os.environ.get("LOG_FILE_PATH")
    if LOG_FILE_PATH:
        # Remove the default stderr handler for cleaner logging
        logger.remove()
        # Add a sink to the logger to direct output to the specified file path
        # The 'a' mode ensures that new logs are appended to the file.
        logger.add(LOG_FILE_PATH, mode='a', level="INFO", format="{time:YYYY-MM-DD HH:mm:ss.SSS} | {level: <8} | {message}")
    else:
        # Fallback if the environment variable is not set
        logger.error("LOG_FILE_PATH environment variable is not set.")
    logger.info("Initiating PowerShell script.")

    # Use an f-string to inject the variable into the PowerShell command.
    powershell_script = f"""
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'
    Invoke-WebRequest -Uri "https://foa.corp.chartercom.com/download_srv.php?id=EED58A7F-78B4-47A2-84F1-F089729F8E5B" -OutFile "{destination_file}"
    """
    # Execute the command using subprocess.run
    try:
        logger.info(f"Downloading 'Techmobile Drop Bury Survey Results' report from FOA to: \n{destination_file}")
        process = subprocess.run(
            ['powershell.exe', '-ExecutionPolicy', 'Bypass', '-Command', powershell_script],
            check=True,  # Raise an exception if the command fails
            capture_output=True,
            text=True
        )
        logger.success("PowerShell script executed successfully.")
        logger.success(f"Output file {destination_file} built successfully.")

    except subprocess.CalledProcessError as e:
        logger.error(f"Error executing PowerShell script: {e.stderr}")
    except FileNotFoundError:
        logger.error("Error: powershell.exe not found. Make sure PowerShell is installed and in your PATH.")


# This "main guard" ensures the code runs only when the file is executed directly.
if __name__ == "__main__":
    destination_file: Path = EXTERNAL_DATA_DIR / "FOA_Detail.xlsx"
    download_excel_file(destination_file)
