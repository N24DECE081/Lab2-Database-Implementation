"""Whitelisted, parameterized MySQL queries; every operation closes its connection."""
from contextlib import contextmanager

import mysql.connector

from app.config import database_config

RESOURCES = {
    "departments": ("departments", "department_id", ("department_code",)),
    "administrative-classes": ("administrative_classes", "class_id", ("department_id",)),
    "students": ("students", "student_id", ("class_id", "student_code", "status")),
    "lecturers": ("lecturers", "lecturer_id", ("department_id",)),
    "courses": ("courses", "course_id", ("department_id", "course_code")),
    "semesters": ("semesters", "semester_id", ()),
    "course-sections": ("course_sections", "section_id", ("course_id", "semester_id", "lecturer_id")),
    "enrollments": ("enrollments", "enrollment_id", ("student_id", "section_id")),
}


@contextmanager
def connection():
    conn = mysql.connector.connect(**database_config())
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def query(statement, params=(), *, one=False):
    with connection() as conn, conn.cursor(dictionary=True) as cur:
        cur.execute(statement, params)
        if cur.description is None:
            return None
        if one:
            return cur.fetchone()
        return cur.fetchall()


def list_rows(resource, limit, offset, filters):
    table, pk, allowed = RESOURCES[resource]
    clauses, values = [], []
    for field in allowed:
        if field in filters:
            clauses.append(f"`{field}` = %s")
            values.append(filters[field])
    where = " WHERE " + " AND ".join(clauses) if clauses else ""
    statement = f"SELECT * FROM `{table}`{where} ORDER BY `{pk}` LIMIT %s OFFSET %s"
    return query(statement, [*values, limit, offset])


def get_row(resource, item_id):
    table, pk, _ = RESOURCES[resource]
    return query(f"SELECT * FROM `{table}` WHERE `{pk}` = %s", (item_id,), one=True)


def save_row(resource, data, item_id=None):
    table, pk, _ = RESOURCES[resource]
    fields = list(data)
    with connection() as conn, conn.cursor(dictionary=True) as cur:
        if item_id is None:
            columns = ", ".join(f"`{field}`" for field in fields)
            placeholders = ", ".join("%s" for _ in fields)
            cur.execute(f"INSERT INTO `{table}` ({columns}) VALUES ({placeholders})", list(data.values()))
            item_id = cur.lastrowid
        else:
            assignments = ", ".join(f"`{field}` = %s" for field in fields)
            cur.execute(f"UPDATE `{table}` SET {assignments} WHERE `{pk}` = %s", [*data.values(), item_id])
            if cur.rowcount == 0:
                cur.execute(f"SELECT 1 FROM `{table}` WHERE `{pk}` = %s", (item_id,))
                if cur.fetchone() is None:
                    return None
        cur.execute(f"SELECT * FROM `{table}` WHERE `{pk}` = %s", (item_id,))
        return cur.fetchone()


def delete_row(resource, item_id):
    table, pk, _ = RESOURCES[resource]
    with connection() as conn, conn.cursor(dictionary=True) as cur:
        cur.execute(f"SELECT * FROM `{table}` WHERE `{pk}` = %s", (item_id,))
        row = cur.fetchone()
        if row is None:
            return None
        cur.execute(f"DELETE FROM `{table}` WHERE `{pk}` = %s", (item_id,))
        return row


def call_transcript(student_id):
    with connection() as conn, conn.cursor(dictionary=True) as cur:
        cur.callproc("student_transcript", (student_id,))
        result_sets = list(cur.stored_results())
        return result_sets[0].fetchall() if result_sets else []
