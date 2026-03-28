# config.py
from pathlib import Path
import os
import sys
from loguru import logger
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Directory Variables
PROJ_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = PROJ_ROOT / "src"
REPORT_DIR = PROJ_ROOT / "reports" / os.environ.get("REPORT_NAME")
SQL_DIR = REPORT_DIR / "sql"
RAW_DATA_DIR = REPORT_DIR / "data/raw"
PROCESSED_DATA_DIR = REPORT_DIR / "data/processed"
EXTERNAL_DATA_DIR = REPORT_DIR / "data/external"

# Ensure directories exist
for p in [SQL_DIR, RAW_DATA_DIR, PROCESSED_DATA_DIR, EXTERNAL_DATA_DIR, REPORT_DIR]:
    p.mkdir(parents=True, exist_ok=True)

# --- Logging Configuration ---
# Check if tqdm is installed and configure loguru to use tqdm.write
try:
    from tqdm import tqdm
    logger.remove(0) # Remove default handler
    logger.add(lambda msg: tqdm.write(msg, end=""), colorize=True)
except ModuleNotFoundError:
    pass

# Class to hold centralized application settings
class Config:
    # Environment variables
    SNOWFLAKE_ACCOUNT = os.getenv("SNOWFLAKE_ACCOUNT")
    SNOWFLAKE_USER = os.getenv("SNOWFLAKE_USER")
    SNOWFLAKE_WAREHOUSE = os.getenv("SNOWFLAKE_WAREHOUSE")
    SNOWFLAKE_DATABASE = os.getenv("SNOWFLAKE_DATABASE")
    SNOWFLAKE_ROLE = os.getenv("SNOWFLAKE_ROLE")
    RSA_KEY_FILE: Path = os.getenv("RSA_KEY_PATH")
    LOG_FILE_PATH = os.environ.get("LOG_FILE_PATH")
    
    @staticmethod
    def setup_logging():
        # Remove the default loguru handler (which logs to stderr)
        logger.remove()

        # Define a consistent format for both the file and console logs
        log_format = (
            "<white>{time:YYYY-MM-DD HH:mm:ss.SSS}</white> | "
            "<level>{level: <8}</level> | "
            "<cyan>{name}</cyan>:<cyan><b>{function}</b></cyan>:<yellow>{line}</yellow> - <white>{message}</white>"
        )
        file_format = "{time:YYYY-MM-DD HH:mm:ss.SSS} | {level: <8} | {message}"

        # Add a sink for console output (with colorization)
        logger.add(sys.stderr, level="INFO", format=log_format, colorize=True)

        # Add a sink for file output if the LOG_FILE_PATH is set
        if Config.LOG_FILE_PATH:
            logger.add(
                Config.LOG_FILE_PATH,
                mode='a',
                level="INFO",
                format=file_format # No color tags needed for the file
            )
        else:
            logger.error("LOG_FILE_PATH environment variable is not set. Only logging to stderr.")


# Set up logging at module load
Config.setup_logging()
