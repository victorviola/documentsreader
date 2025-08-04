import os
import pyodbc
from dotenv import load_dotenv

load_dotenv()
DB_CONN_STR = os.getenv("DB_CONN_STR")

def get_connection():
    return pyodbc.connect(DB_CONN_STR)
