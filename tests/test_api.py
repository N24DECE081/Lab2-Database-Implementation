import mysql.connector
import pytest
from fastapi.testclient import TestClient
from app import db
from app.main import app

pytestmark = pytest.mark.integration


@pytest.mark.parametrize("resource", list(db.RESOURCES))
def test_crud_every_resource(client, resource):
    pk = db.RESOURCES[resource][1]
    original = client.get(f"/{resource}").json()[0]
    payload = {key: value for key, value in original.items() if key not in {pk, "created_at", "registration_date"}}
    changes = {
        "departments": {"department_code": "TEST", "department_name": "Test Department"},
        "administrative-classes": {"class_name": "TEST"},
        "students": {"student_code": "TEST001", "email": "test@example.org"},
        "lecturers": {"email": "lecturer@example.org"},
        "courses": {"course_code": "TEST101"},
        "semesters": {"semester_name": "Test semester"},
        "course-sections": {"section_number": "TEST"},
        "enrollments": {"student_id": 5, "section_id": 1, "final_grade": None},
    }
    payload.update(changes[resource])
    response = client.post(f"/{resource}", json=payload)
    assert response.status_code == 201, response.text
    item_id = response.json()[pk]
    assert client.get(f"/{resource}/{item_id}").status_code == 200
    response = client.put(f"/{resource}/{item_id}", json=payload)
    assert response.status_code == 200, response.text
    assert client.delete(f"/{resource}/{item_id}").status_code == 204
    assert client.get(f"/{resource}/{item_id}").status_code == 404
    assert client.put(f"/{resource}/{item_id}", json=payload).status_code == 404
    assert client.delete(f"/{resource}/{item_id}").status_code == 404


def test_database_readiness_and_reports(client):
    assert client.get("/ready").json()["database"] == "connected"
    assert client.get("/health").status_code == 200
    assert "Use /docs" in client.get("/").json()["message"]
    assert client.get("/reports/section-occupancy").json()[0]["enrolled"] == 2
    assert client.get("/reports/students/1/transcript").json()[0]["final_grade"] == 8.5
    assert client.get("/reports/students/999/transcript").status_code == 404


def test_filters_and_pagination(client):
    assert len(client.get("/students?class_id=1").json()) == 2
    assert len(client.get("/students?limit=2&offset=2").json()) == 2
    for query in ["limit=0", "offset=-1", "class_id=abc", "class_id=0", "class_id=999999999999999", "unknown=1"]:
        assert client.get(f"/students?{query}").status_code == 422
    assert client.get("/students?student_code=' OR 1=1 --").json() == []


def test_duplicate_fk_delete_and_invalid_inputs(client):
    assert client.post("/enrollments", json={"student_id": 1, "section_id": 1}).status_code == 409
    assert client.post("/enrollments", json={"student_id": 999, "section_id": 1}).status_code == 409
    assert client.delete("/departments/1").status_code == 409
    assert client.post("/enrollments", json={"student_id": 1, "section_id": 1, "final_grade": 11}).status_code == 422
    assert client.get("/students/0").status_code == 422


def test_grade_update_and_clear(client):
    assert client.patch("/enrollments/2/grade", json={"final_grade": 9.5}).status_code == 200
    assert client.get("/enrollments/2").json()["final_grade"] == 9.5
    assert client.patch("/enrollments/2/grade", json={"final_grade": None}).json()["final_grade"] is None
    assert client.patch("/enrollments/2/grade", json={}).status_code == 422


def test_writes_are_persisted(client, mysql_db):
    response = client.post("/departments", json={"department_code": "DB", "department_name": "Persisted"})
    with mysql.connector.connect(**mysql_db) as conn, conn.cursor() as cur:
        cur.execute("SELECT department_name FROM departments WHERE department_id=%s", (response.json()["department_id"],))
        assert cur.fetchone() == ("Persisted",)


def test_database_down_has_no_fake_fallback(mysql_db, monkeypatch):
    monkeypatch.setenv("MYSQL_HOST", "127.0.0.1")
    monkeypatch.setenv("MYSQL_PORT", "1")
    monkeypatch.setenv("MYSQL_USER", "invalid")
    monkeypatch.setenv("MYSQL_PASSWORD", "invalid")
    with TestClient(app) as client:
        assert client.get("/students").status_code == 503
        assert client.get("/ready").status_code == 503
        assert client.get("/health").status_code == 200


def test_openapi_request_bodies(client):
    schema = client.get("/openapi.json").json()
    for resource in db.RESOURCES:
        assert "requestBody" in schema["paths"][f"/{resource}"]["post"]
