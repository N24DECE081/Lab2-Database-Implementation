-- MySQL 8.4 schema for student course registration.
-- Parent tables are created before child tables so every foreign key is valid.
-- Every table and column carries a MySQL COMMENT. Constraint and index names
-- are deliberately semantic; their complete purpose and columns are documented
-- in docs/ddd.md (sections 7 and 8), because MySQL has no COMMENT ON
-- CONSTRAINT or COMMENT ON INDEX statement.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS departments (
    department_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate department identifier',
    department_code VARCHAR(20) NOT NULL COMMENT 'Unique short code such as CS',
    department_name VARCHAR(150) NOT NULL COMMENT 'Official department name',
    description TEXT NULL COMMENT 'Optional department description',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    CONSTRAINT pk_departments PRIMARY KEY (department_id),
    CONSTRAINT uq_departments_code UNIQUE (department_code),
    CONSTRAINT uq_departments_name UNIQUE (department_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Academic departments';

CREATE TABLE IF NOT EXISTS administrative_classes (
    class_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate administrative class identifier',
    department_id INT NOT NULL COMMENT 'Owning department',
    class_name VARCHAR(100) NOT NULL COMMENT 'Cohort name such as K65',
    academic_year SMALLINT NOT NULL COMMENT 'Academic intake year',
    section_label VARCHAR(20) NOT NULL DEFAULT 'A' COMMENT 'Subgroup label',
    CONSTRAINT pk_administrative_classes PRIMARY KEY (class_id),
    CONSTRAINT fk_class_department FOREIGN KEY (department_id)
        REFERENCES departments (department_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT uq_class_department UNIQUE (department_id, class_name, academic_year, section_label),
    CONSTRAINT chk_class_year CHECK (academic_year BETWEEN 2000 AND 2100),
    CONSTRAINT chk_class_name CHECK (CHAR_LENGTH(TRIM(class_name)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Administrative student cohorts';

CREATE TABLE IF NOT EXISTS students (
    student_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate student identifier',
    class_id INT NOT NULL COMMENT 'Administrative class',
    student_code VARCHAR(30) NOT NULL COMMENT 'Institution student number',
    first_name VARCHAR(50) NOT NULL COMMENT 'Student first name',
    last_name VARCHAR(50) NOT NULL COMMENT 'Student last name',
    email VARCHAR(150) NOT NULL COMMENT 'Unique student email',
    enrollment_year SMALLINT NOT NULL COMMENT 'Admission year',
    status VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT 'Academic status',
    CONSTRAINT pk_students PRIMARY KEY (student_id),
    CONSTRAINT fk_student_class FOREIGN KEY (class_id)
        REFERENCES administrative_classes (class_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT uq_students_code UNIQUE (student_code),
    CONSTRAINT uq_students_email UNIQUE (email),
    CONSTRAINT chk_student_year CHECK (enrollment_year BETWEEN 2000 AND 2100),
    CONSTRAINT chk_student_status CHECK (status IN ('active', 'inactive', 'graduated', 'on_leave')),
    CONSTRAINT chk_student_name CHECK (CHAR_LENGTH(TRIM(first_name)) > 0 AND CHAR_LENGTH(TRIM(last_name)) > 0),
    INDEX idx_students_class_id (class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Student records';

CREATE TABLE IF NOT EXISTS lecturers (
    lecturer_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate lecturer identifier',
    department_id INT NOT NULL COMMENT 'Department assignment',
    first_name VARCHAR(50) NOT NULL COMMENT 'Lecturer first name',
    last_name VARCHAR(50) NOT NULL COMMENT 'Lecturer last name',
    email VARCHAR(150) NOT NULL COMMENT 'Unique lecturer email',
    title VARCHAR(80) NOT NULL COMMENT 'Academic title',
    CONSTRAINT pk_lecturers PRIMARY KEY (lecturer_id),
    CONSTRAINT fk_lecturer_department FOREIGN KEY (department_id)
        REFERENCES departments (department_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT uq_lecturers_email UNIQUE (email),
    CONSTRAINT chk_lecturer_name CHECK (CHAR_LENGTH(TRIM(first_name)) > 0 AND CHAR_LENGTH(TRIM(last_name)) > 0),
    INDEX idx_lecturers_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Academic staff';

CREATE TABLE IF NOT EXISTS courses (
    course_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate course identifier',
    department_id INT NOT NULL COMMENT 'Owning department',
    course_code VARCHAR(20) NOT NULL COMMENT 'Unique course code',
    course_name VARCHAR(150) NOT NULL COMMENT 'Course title',
    credit_hours SMALLINT NOT NULL COMMENT 'Academic credits from 1 to 10',
    description TEXT NULL COMMENT 'Optional course description',
    CONSTRAINT pk_courses PRIMARY KEY (course_id),
    CONSTRAINT fk_course_department FOREIGN KEY (department_id)
        REFERENCES departments (department_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT uq_courses_code UNIQUE (course_code),
    CONSTRAINT chk_course_credits CHECK (credit_hours BETWEEN 1 AND 10),
    CONSTRAINT chk_course_name CHECK (CHAR_LENGTH(TRIM(course_name)) > 0),
    INDEX idx_courses_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Course catalog';

CREATE TABLE IF NOT EXISTS semesters (
    semester_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate semester identifier',
    semester_name VARCHAR(60) NOT NULL COMMENT 'Unique semester label',
    start_date DATE NOT NULL COMMENT 'First day of semester',
    end_date DATE NOT NULL COMMENT 'Last day of semester',
    CONSTRAINT pk_semesters PRIMARY KEY (semester_id),
    CONSTRAINT uq_semesters_name UNIQUE (semester_name),
    CONSTRAINT chk_semester_dates CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Academic semesters';

CREATE TABLE IF NOT EXISTS course_sections (
    section_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate section identifier',
    course_id INT NOT NULL COMMENT 'Offered course',
    semester_id INT NOT NULL COMMENT 'Offering semester',
    lecturer_id INT NOT NULL COMMENT 'Assigned lecturer',
    section_number VARCHAR(10) NOT NULL COMMENT 'Section code such as A1',
    room_number VARCHAR(30) NOT NULL COMMENT 'Classroom or laboratory',
    schedule_text VARCHAR(200) NOT NULL COMMENT 'Human-readable weekly schedule',
    capacity SMALLINT NOT NULL COMMENT 'Maximum number of students',
    CONSTRAINT pk_course_sections PRIMARY KEY (section_id),
    CONSTRAINT fk_section_course FOREIGN KEY (course_id)
        REFERENCES courses (course_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_section_semester FOREIGN KEY (semester_id)
        REFERENCES semesters (semester_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_section_lecturer FOREIGN KEY (lecturer_id)
        REFERENCES lecturers (lecturer_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT uq_section_course_semester UNIQUE (course_id, semester_id, section_number),
    CONSTRAINT chk_section_capacity CHECK (capacity > 0),
    INDEX idx_sections_semester_id (semester_id),
    INDEX idx_sections_lecturer_id (lecturer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Specific course offerings';

CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate enrollment identifier',
    student_id INT NOT NULL COMMENT 'Enrolled student',
    section_id INT NOT NULL COMMENT 'Selected course section',
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Registration time',
    final_grade DECIMAL(3,1) NULL COMMENT 'Final grade from 0 to 10 when assigned',
    CONSTRAINT pk_enrollments PRIMARY KEY (enrollment_id),
    CONSTRAINT fk_enrollment_student FOREIGN KEY (student_id)
        REFERENCES students (student_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_enrollment_section FOREIGN KEY (section_id)
        REFERENCES course_sections (section_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT uq_student_section UNIQUE (student_id, section_id),
    CONSTRAINT chk_enrollment_grade CHECK (final_grade IS NULL OR final_grade BETWEEN 0 AND 10),
    INDEX idx_enrollments_section_id (section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Student-to-section registration';
