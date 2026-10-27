from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import re
import threading
import time

import mysql.connector
import pytest

from conftest import sql_statements

pytestmark = pytest.mark.integration


@pytest.mark.parametrize("statement,errno", [
    ("INSERT INTO enrollments(student_id,section_id) VALUES(1,1)", 1062),
    ("INSERT INTO enrollments(student_id,section_id) VALUES(999,1)", 1452),
    ("UPDATE enrollments SET final_grade=11 WHERE enrollment_id=1", 3819),
    ("UPDATE courses SET credit_hours=0 WHERE course_id=1", 3819),
    ("UPDATE students SET status='bad' WHERE student_id=1", 3819),
    ("UPDATE semesters SET end_date=DATE_SUB(start_date, INTERVAL 1 DAY) WHERE semester_id=1", 3819),
    ("DELETE FROM departments WHERE department_id=1", 1451),
    ("UPDATE course_sections SET capacity=1 WHERE section_id=1", 1644),
])
def test_mysql_constraints(mysql_db, statement, errno):
    connection = mysql.connector.connect(**mysql_db)
    try:
        with pytest.raises(mysql.connector.Error) as caught, connection.cursor() as cur:
            cur.execute(statement)
        assert caught.value.errno == errno
    finally:
        connection.rollback()
        connection.close()


def test_concurrent_last_seat(mysql_db):
    with mysql.connector.connect(**mysql_db) as connection, connection.cursor() as cur:
        cur.execute("UPDATE course_sections SET capacity=3 WHERE section_id=1")
        connection.commit()
    barrier = threading.Barrier(2)

    def enroll(student_id):
        connection = mysql.connector.connect(**mysql_db)
        try:
            barrier.wait(timeout=10)
            with connection.cursor() as cur:
                cur.execute("INSERT INTO enrollments(student_id,section_id) VALUES(%s,1)", (student_id,))
                time.sleep(0.15)
            connection.commit()
            return "created"
        except mysql.connector.Error as exc:
            connection.rollback()
            if exc.errno == 1644:
                return "full"
            raise
        finally:
            connection.close()

    with ThreadPoolExecutor(max_workers=2) as pool:
        assert sorted(pool.map(enroll, [3, 4])) == ["created", "full"]


def test_erd_matches_mysql(mysql_db):
    source = (Path(__file__).resolve().parents[1] / "docs/erd_student_course_registration.mmd").read_text(encoding="utf-8")
    blocks = dict(re.findall(r"^    (\w+) \{\n(.*?)^    \}", source, re.M | re.S))
    connection = mysql.connector.connect(**mysql_db)
    try:
        with connection.cursor() as cur:
            cur.execute("""SELECT table_name,column_name FROM information_schema.columns
                           WHERE table_schema=%s AND table_name NOT LIKE 'v\\_%'""", (mysql_db["database"],))
            actual = set(cur.fetchall())
            diagram = {(table, match[1]) for table, body in blocks.items()
                       for match in re.findall(r"^\s+(\S+) (\w+)", body, re.M)}
            assert diagram == actual
            cur.execute("""SELECT COUNT(*) FROM information_schema.table_constraints
                           WHERE constraint_schema=%s AND constraint_type='FOREIGN KEY'""", (mysql_db["database"],))
            assert source.count("||..o{") == cur.fetchone()[0] == 9
    finally:
        connection.close()


def test_all_sample_queries_execute(mysql_db):
    root = Path(__file__).resolve().parents[1]
    connection = mysql.connector.connect(**mysql_db)
    try:
        with connection.cursor() as cur:
            for statement in sql_statements((root / "sql/03_sample_queries.sql").read_text(encoding="utf-8")):
                cur.execute(statement)
                if cur.with_rows:
                    cur.fetchall()
                try:
                    while cur.nextset():
                        if cur.with_rows:
                            cur.fetchall()
                except mysql.connector.InterfaceError as exc:
                    if exc.errno != 2053:
                        raise
    finally:
        connection.close()


def test_database_comments_and_objects(mysql_db):
    connection = mysql.connector.connect(**mysql_db)
    try:
        with connection.cursor() as cur:
            cur.execute("""SELECT COUNT(*) FROM information_schema.columns
                           WHERE table_schema=%s AND table_name NOT LIKE 'v!_%%' ESCAPE '!'
                             AND column_comment=''""", (mysql_db["database"],))
            assert cur.fetchone()[0] == 0
            cur.execute("SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema=%s", (mysql_db["database"],))
            assert cur.fetchone()[0] == 3
            cur.execute("SELECT COUNT(*) FROM information_schema.views WHERE table_schema=%s", (mysql_db["database"],))
            assert cur.fetchone()[0] == 1
            cur.execute("SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema=%s", (mysql_db["database"],))
            assert cur.fetchone()[0] == 1
    finally:
        connection.close()
