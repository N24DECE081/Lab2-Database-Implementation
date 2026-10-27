import mysql.connector
import pytest

from app.cli import import_students

pytestmark = pytest.mark.integration
HEADER = "class_id,student_code,first_name,last_name,email,enrollment_year,status\n"


def test_csv_import_persists_and_is_repeatable(mysql_db, tmp_path):
    path = tmp_path / "students.csv"
    path.write_text(HEADER + "1,NEW001,Test,User,new@example.org,2026,active\n", encoding="utf-8")
    assert import_students(path)["inserted"] == 1
    assert import_students(path)["skipped_existing_code"] == 1
    with mysql.connector.connect(**mysql_db) as connection, connection.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM students WHERE student_code='NEW001'")
        assert cur.fetchone()[0] == 1


def test_csv_import_rolls_back_all_on_late_fk_error(mysql_db, tmp_path):
    path = tmp_path / "students.csv"
    path.write_text(HEADER + "1,NEW001,Test,User,new@example.org,2026,active\n999,NEW002,Other,User,other@example.org,2026,active\n", encoding="utf-8")
    with pytest.raises(mysql.connector.Error) as caught:
        import_students(path)
    assert caught.value.errno == 1452
    with mysql.connector.connect(**mysql_db) as connection, connection.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM students WHERE student_code LIKE 'NEW%'")
        assert cur.fetchone()[0] == 0
