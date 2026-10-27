from datetime import date
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

PositiveId = Annotated[int, Field(gt=0, le=2147483647)]
Name = Annotated[str, Field(min_length=1, max_length=50)]
Email = Annotated[str, Field(max_length=150, pattern=r"^[^\s@]+@[^\s@]+\.[^\s@]+$")]


class InputModel(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True, allow_inf_nan=False)


class Department(InputModel):
    department_code: str = Field(min_length=2, max_length=20)
    department_name: str = Field(min_length=2, max_length=150)
    description: str | None = None


class AdministrativeClass(InputModel):
    department_id: PositiveId
    class_name: str = Field(min_length=1, max_length=100)
    academic_year: int = Field(ge=2000, le=2100)
    section_label: str = Field(default="A", min_length=1, max_length=20)


class Student(InputModel):
    class_id: PositiveId
    student_code: str = Field(min_length=3, max_length=30)
    first_name: Name
    last_name: Name
    email: Email
    enrollment_year: int = Field(ge=2000, le=2100)
    status: Literal["active", "inactive", "graduated", "on_leave"] = "active"


class Lecturer(InputModel):
    department_id: PositiveId
    first_name: Name
    last_name: Name
    email: Email
    title: str = Field(min_length=1, max_length=80)


class Course(InputModel):
    department_id: PositiveId
    course_code: str = Field(min_length=2, max_length=20)
    course_name: str = Field(min_length=1, max_length=150)
    credit_hours: int = Field(ge=1, le=10)
    description: str | None = None


class Semester(InputModel):
    semester_name: str = Field(min_length=3, max_length=60)
    start_date: date
    end_date: date

    @model_validator(mode="after")
    def ordered_dates(self):
        if self.end_date < self.start_date:
            raise ValueError("end_date must be on or after start_date")
        return self


class CourseSection(InputModel):
    course_id: PositiveId
    semester_id: PositiveId
    lecturer_id: PositiveId
    section_number: str = Field(min_length=1, max_length=10)
    room_number: str = Field(min_length=1, max_length=30)
    schedule_text: str = Field(min_length=3, max_length=200)
    capacity: int = Field(gt=0, le=32767)


class Enrollment(InputModel):
    student_id: PositiveId
    section_id: PositiveId
    final_grade: Decimal | None = Field(default=None, ge=0, le=10, decimal_places=1)


class GradeUpdate(InputModel):
    final_grade: Decimal | None = Field(ge=0, le=10, decimal_places=1)
