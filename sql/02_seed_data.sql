INSERT INTO departments (department_code, department_name, description) VALUES
    ('CS', 'Computer Science', 'Software engineering, algorithms, and computing systems'),
    ('EE', 'Electrical Engineering', 'Hardware systems, electronics, and power engineering'),
    ('BM', 'Business Management', 'Administration, accounting, and entrepreneurship');

INSERT INTO administrative_classes (department_id, class_name, academic_year, section_label) VALUES
    (1, 'K65', 2025, 'A'),
    (1, 'K65', 2025, 'B'),
    (2, 'K64', 2024, 'A'),
    (3, 'K66', 2026, 'A');

INSERT INTO students (class_id, student_code, first_name, last_name, email, enrollment_year, status) VALUES
    (1, 'CS25001', 'An', 'Nguyen', 'an.nguyen@example.edu.vn', 2025, 'active'),
    (1, 'CS25002', 'Binh', 'Tran', 'binh.tran@example.edu.vn', 2025, 'active'),
    (2, 'CS25003', 'Cuong', 'Le', 'cuong.le@example.edu.vn', 2025, 'active'),
    (3, 'EE24001', 'Duyen', 'Pham', 'duyen.pham@example.edu.vn', 2024, 'active'),
    (4, 'BM26001', 'Em', 'Vo', 'em.vo@example.edu.vn', 2026, 'active');

INSERT INTO lecturers (department_id, first_name, last_name, email, title) VALUES
    (1, 'Ha', 'Thanh', 'ha.thanh@ptit.edu.vn', 'Lecturer'),
    (1, 'Mai', 'Nguyen', 'mai.nguyen@ptit.edu.vn', 'Associate Professor'),
    (2, 'Lan', 'Hoang', 'lan.hoang@ptit.edu.vn', 'Senior Lecturer'),
    (3, 'Khanh', 'Bui', 'khanh.bui@ptit.edu.vn', 'Lecturer');

INSERT INTO courses (department_id, course_code, course_name, credit_hours, description) VALUES
    (1, 'INT1313', 'Databases', 3, 'Relational database design and SQL queries'),
    (1, 'INT1331', 'Software Engineering', 3, 'Requirements, design, testing, and maintenance'),
    (1, 'INT1351', 'Operating Systems', 3, 'Processes, scheduling, memory, file systems'),
    (2, 'ELE2020', 'Digital Logic', 3, 'Boolean algebra, gates, and state machines'),
    (3, 'BUS2001', 'Introduction to Management', 2, 'Business operations and organization');

INSERT INTO semesters (semester_name, start_date, end_date) VALUES
    ('2025-2026 Semester 1', '2025-09-01', '2025-12-31'),
    ('2025-2026 Semester 2', '2026-02-01', '2026-06-30'),
    ('2026-2027 Semester 1', '2026-09-01', '2026-12-31');

INSERT INTO course_sections (course_id, semester_id, lecturer_id, section_number, room_number, schedule_text, capacity) VALUES
    (1, 1, 1, 'A1', 'B102', 'Mon 08:00-10:00', 60),
    (1, 2, 1, 'A2', 'B204', 'Wed 13:00-15:00', 50),
    (2, 1, 2, 'B1', 'B110', 'Tue 09:00-11:00', 70),
    (4, 1, 3, 'E1', 'E305', 'Thu 10:00-12:00', 40),
    (5, 3, 4, 'M1', 'M201', 'Fri 08:00-10:00', 35);

INSERT INTO enrollments (student_id, section_id, registration_date, final_grade) VALUES
    (1, 1, '2025-09-05 09:00:00', 8.5),
    (2, 1, '2025-09-05 09:10:00', NULL),
    (3, 2, '2026-02-10 10:00:00', 7.0),
    (4, 4, '2025-09-10 14:00:00', 9.2),
    (5, 5, '2026-09-02 08:30:00', NULL);
