"""MySQL configuration read from environment variables."""
import os


def database_config():
    return {
        "host": os.getenv("MYSQL_HOST", "127.0.0.1"),
        "port": int(os.getenv("MYSQL_PORT", "3307")),
        "user": os.getenv("MYSQL_USER", "lab_api"),
        "password": os.getenv("MYSQL_PASSWORD", "lab_api_dev"),
        "database": os.getenv("MYSQL_DATABASE", "student_reg_db"),
        "connection_timeout": 5,
    }
