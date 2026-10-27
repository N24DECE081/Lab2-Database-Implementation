"""Each integration test uses an isolated MySQL database."""
import os
from pathlib import Path
from uuid import uuid4

import mysql.connector
import pytest
from fastapi.testclient import TestClient

from app.main import app

ROOT = Path(__file__).resolve().parents[1]


def sql_statements(text):
    delimiter, buffer = ";", []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.upper().startswith("DELIMITER "):
            delimiter = stripped.split(maxsplit=1)[1]
            continue
        if not stripped or stripped.startswith("--"):
            continue
        buffer.append(line)
        if stripped.endswith(delimiter):
            statement = "\n".join(buffer).rstrip()
            statement = statement[:-len(delimiter)].strip()
            if statement:
                yield statement
            buffer = []
    if buffer:
        raise ValueError("Unterminated SQL statement")


def execute_file(connection, path):
    with connection.cursor() as cur:
        for statement in sql_statements(path.read_text(encoding="utf-8")):
            cur.execute(statement)
            if cur.with_rows:
                cur.fetchall()
            while cur.nextset():
                if cur.with_rows:
                    cur.fetchall()
    connection.commit()


@pytest.fixture(scope="session")
def isolated_database():
    host = os.getenv("TEST_MYSQL_HOST")
    if not host:
        pytest.skip("Use: docker compose --profile test run --rm tests")
    admin = {
        "host": host,
        "port": int(os.getenv("TEST_MYSQL_PORT", "3306")),
        "user": os.getenv("TEST_MYSQL_USER", "root"),
        "password": os.getenv("TEST_MYSQL_PASSWORD", "mysql_dev"),
    }
    name = "lab_test_" + uuid4().hex
    maintenance = mysql.connector.connect(**admin)
    with maintenance.cursor() as cur:
        cur.execute(f"CREATE DATABASE `{name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci")
    config = {**admin, "database": name}
    try:
        connection = mysql.connector.connect(**config)
        try:
            for filename in ("01_schema.sql", "04_business_logic.sql"):
                execute_file(connection, ROOT / "sql" / filename)
        finally:
            connection.close()
        yield config
    finally:
        with maintenance.cursor() as cur:
            cur.execute(f"DROP DATABASE IF EXISTS `{name}`")
        maintenance.close()


@pytest.fixture
def mysql_db(isolated_database, monkeypatch):
    connection = mysql.connector.connect(**isolated_database)
    try:
        with connection.cursor() as cur:
            cur.execute("SET FOREIGN_KEY_CHECKS = 0")
            for table in ("enrollments", "course_sections", "semesters", "courses", "lecturers", "students", "administrative_classes", "departments"):
                cur.execute(f"TRUNCATE TABLE `{table}`")
            cur.execute("SET FOREIGN_KEY_CHECKS = 1")
        execute_file(connection, ROOT / "sql/02_seed_data.sql")
    finally:
        connection.close()
    for key, value in {
        "MYSQL_HOST": isolated_database["host"],
        "MYSQL_PORT": str(isolated_database["port"]),
        "MYSQL_USER": isolated_database["user"],
        "MYSQL_PASSWORD": isolated_database["password"],
        "MYSQL_DATABASE": isolated_database["database"],
    }.items():
        monkeypatch.setenv(key, value)
    return isolated_database


@pytest.fixture
def client(mysql_db):
    with TestClient(app) as test_client:
        yield test_client
