import pytest
from pydantic import ValidationError
from app.models import Course, Enrollment, GradeUpdate, Semester, Student


@pytest.mark.parametrize("grade", [-1, 10.1, "NaN", "Infinity", 8.55])
def test_invalid_grades(grade):
    with pytest.raises(ValidationError):
        Enrollment(student_id=1, section_id=1, final_grade=grade)


@pytest.mark.parametrize("grade", [None, 0, 10, 8.5])
def test_valid_grades(grade):
    Enrollment(student_id=1, section_id=1, final_grade=grade)


def test_grade_patch_requires_explicit_value():
    with pytest.raises(ValidationError):
        GradeUpdate()
    assert GradeUpdate(final_grade=None).final_grade is None


def test_semester_dates():
    with pytest.raises(ValidationError):
        Semester(semester_name="test", start_date="2026-12-31", end_date="2026-01-01")
    with pytest.raises(ValidationError):
        Semester(semester_name="test", start_date="nonsense", end_date="2026-01-01")


@pytest.mark.parametrize("credits", [0, 11])
def test_course_credits(credits):
    with pytest.raises(ValidationError):
        Course(department_id=1, course_code="TEST", course_name="Test", credit_hours=credits)


@pytest.mark.parametrize("change", [{"status": "unknown"}, {"class_id": 0}, {"email": "invalid"}, {"first_name": "   "}, {"student_id": 1}])
def test_student_validation(change):
    payload = dict(class_id=1, student_code="TEST1", first_name="An", last_name="Nguyen", email="an@example.org", enrollment_year=2026)
    payload.update(change)
    with pytest.raises(ValidationError):
        Student(**payload)
