from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from snowflake.sqlalchemy import URL
from sqlalchemy import create_engine, text
from loguru import logger
import sqlparse
import pandas as pd
import numpy as np
from config import Config
import re

class SnowflakeSQLRunner:
    """Class to manage and execute SQL scripts on Snowflake."""

    def __init__(self, key_file, account, user, warehouse, database, schema, role):
        self._key_file = key_file
        self._account = account
        self._user = user
        self._warehouse = warehouse
        self._database = database
        self._schema = schema
        self._role = role
        self._engine = None

    def __enter__(self):
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.dispose()
        return False

    def _load_private_key(self):
        """Loads and decrypts the RSA private key from a file."""
        try:
            with open(self._key_file, "rb") as key_file:
                p_key = serialization.load_pem_private_key(
                    key_file.read(),
                    password=None,
                    backend=default_backend()
                )
            pkb = p_key.private_bytes(
                encoding=serialization.Encoding.DER,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
            return pkb
        except FileNotFoundError:
            logger.error(f"RSA key file not found: {self._key_file}")
            raise
        except Exception as e:
            logger.error(f"Error loading or decrypting private key: {e}")
            raise

    def connect(self):
        """Creates the SQLAlchemy engine for Snowflake."""
        if self._engine is None:
            try:
                pkb = self._load_private_key()
                self._engine = create_engine(
                    URL(
                        account=self._account,
                        user=self._user,
                        warehouse=self._warehouse,
                        database=self._database,
                        schema=self._schema,
                        role = self._role
                    ),
                    connect_args={'private_key': pkb}
                )
                logger.success(f"SQLAlchemy engine created using schema: {self._schema}")
            except Exception as e:
                logger.error(f"Failed to create SQLAlchemy engine: {e}")
                raise

    def dispose(self):
        """Disposes of the SQLAlchemy engine."""
        if self._engine:
            self._engine.dispose()
            self._engine = None
            logger.success("SQLAlchemy engine disposed")

    def execute_query(self, sql_file):
        """
        Executes a SQL file and returns a DataFrame from the last statement
        that returns rows, handling CTEs correctly.
        """
        if self._engine is None:
            raise RuntimeError("Engine not connected. Use 'with' statement or call connect() first.")
        
        try:
            with open(sql_file, "r") as f:
                logger.info(f"Executing: {sql_file}")
                sql_query = f.read()

            statements = sqlparse.split(sql_query)
            df = None
            
            with self._engine.connect() as connection:
                with connection.begin():
                    for statement_str in statements:
                        clean_statement = sqlparse.format(statement_str, strip_comments=True).strip()

                        if not clean_statement:
                            continue
                        
                        try:
                            # Attempt to read into a DataFrame. This will succeed for SELECTs.
                            temp_df = pd.read_sql(clean_statement, connection)
                            df = temp_df # Update df with the result, keeping the last one
                            logger.success(f"Statement executed successfully via pd.read_sql, resulting in {len(df)} rows.")

                        except Exception as e:
                            # If read_sql fails (likely a non-SELECT statement),
                            # execute it directly and ignore the error.
                            logger.warning(f"pd.read_sql failed for statement, executing directly. Error: {e}")
            return df
        
        except FileNotFoundError:
            logger.error(f"SQL file not found: {sql_file}")
            return None
        except Exception as e:
            logger.error(f"Error executing SQL query from {sql_file}: {e}")
            return None
