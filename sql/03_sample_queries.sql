-- MySQL retrieval examples used during Q&A.

-- 1. Students with their administrative class and department.
SELECT s.student_id, s.student_code, s.first_name, s.last_name,
       ac.class_name, ac.section_label, d.department_name
FROM students AS s
JOIN administrative_classes AS ac ON ac.class_id = s.class_id
JOIN departments AS d ON d.department_id = ac.department_id
ORDER BY s.student_id;

-- 2. Sections with course, semester and lecturer.
SELECT cs.section_id, c.course_code, c.course_name, sem.semester_name,
       CONCAT(l.first_name, ' ', l.last_name) AS lecturer_name,
       cs.section_number, cs.room_number, cs.schedule_text, cs.capacity
FROM course_sections AS cs
JOIN courses AS c ON c.course_id = cs.course_id
JOIN semesters AS sem ON sem.semester_id = cs.semester_id
JOIN lecturers AS l ON l.lecturer_id = cs.lecturer_id
ORDER BY cs.section_id;

-- 3. Enrollments with student and course information.
SELECT e.enrollment_id, s.student_code,
       CONCAT(s.first_name, ' ', s.last_name) AS student_name,
       c.course_code, c.course_name, cs.section_number, e.final_grade
FROM enrollments AS e
JOIN students AS s ON s.student_id = e.student_id
JOIN course_sections AS cs ON cs.section_id = e.section_id
JOIN courses AS c ON c.course_id = cs.course_id
ORDER BY e.enrollment_id;

-- 4. Count students in every section; LEFT JOIN preserves empty sections.
SELECT cs.section_id, c.course_code, c.course_name,
       COUNT(e.enrollment_id) AS total_students
FROM course_sections AS cs
JOIN courses AS c ON c.course_id = cs.course_id
LEFT JOIN enrollments AS e ON e.section_id = cs.section_id
GROUP BY cs.section_id, c.course_code, c.course_name
ORDER BY total_students DESC;

-- 5. Graded attempts with grade at least 8.
SELECT s.student_code, s.first_name, s.last_name, c.course_code, e.final_grade
FROM enrollments AS e
JOIN students AS s ON s.student_id = e.student_id
JOIN course_sections AS cs ON cs.section_id = e.section_id
JOIN courses AS c ON c.course_id = cs.course_id
WHERE e.final_grade IS NOT NULL AND e.final_grade >= 8.0
ORDER BY e.final_grade DESC;

-- 6. Sections without enrollment.
SELECT cs.section_id, cs.section_number
FROM course_sections AS cs
WHERE NOT EXISTS (
    SELECT 1 FROM enrollments AS e WHERE e.section_id = cs.section_id
)
ORDER BY cs.section_id;

-- 7. Courses never offered in a section.
SELECT c.course_code, c.course_name
FROM courses AS c
WHERE NOT EXISTS (
    SELECT 1 FROM course_sections AS cs WHERE cs.course_id = c.course_id
)
ORDER BY c.course_code;

-- 8. Class sizes, including empty classes.
SELECT ac.class_id, ac.class_name, ac.section_label,
       COUNT(s.student_id) AS total_students
FROM administrative_classes AS ac
LEFT JOIN students AS s ON s.class_id = ac.class_id
GROUP BY ac.class_id, ac.class_name, ac.section_label
ORDER BY ac.class_id;

-- 9. Credit-weighted average for each student.
SELECT s.student_code,
       ROUND(
           SUM(CASE WHEN e.final_grade IS NOT NULL THEN e.final_grade * c.credit_hours ELSE 0 END)
           / NULLIF(SUM(CASE WHEN e.final_grade IS NOT NULL THEN c.credit_hours ELSE 0 END), 0),
           2
       ) AS weighted_average
FROM students AS s
LEFT JOIN enrollments AS e ON e.student_id = s.student_id
LEFT JOIN course_sections AS cs ON cs.section_id = e.section_id
LEFT JOIN courses AS c ON c.course_id = cs.course_id
GROUP BY s.student_id, s.student_code
ORDER BY s.student_id;

-- 10. Transcript through a stored procedure.
CALL student_transcript(1);

-- 11. Available seats through a view.
SELECT * FROM v_section_occupancy ORDER BY section_id;

-- 12. HAVING filters groups after aggregation.
SELECT section_id, COUNT(*) AS enrolled
FROM enrollments
GROUP BY section_id
HAVING COUNT(*) >= 2
ORDER BY section_id;

-- 13. CTE and window function: rank grades within each course.
WITH graded AS (
    SELECT c.course_code, s.student_code, e.final_grade
    FROM enrollments AS e
    JOIN students AS s ON s.student_id = e.student_id
    JOIN course_sections AS cs ON cs.section_id = e.section_id
    JOIN courses AS c ON c.course_id = cs.course_id
    WHERE e.final_grade IS NOT NULL
)
SELECT course_code, student_code, final_grade,
       DENSE_RANK() OVER (PARTITION BY course_code ORDER BY final_grade DESC) AS grade_rank
FROM graded
ORDER BY course_code, grade_rank, student_code;

-- 14. Relational division: students enrolled in every section of semester 1.
SELECT s.student_code
FROM students AS s
WHERE EXISTS (SELECT 1 FROM course_sections WHERE semester_id = 1)
  AND NOT EXISTS (
      SELECT 1
      FROM course_sections AS cs
      WHERE cs.semester_id = 1
        AND NOT EXISTS (
            SELECT 1 FROM enrollments AS e
            WHERE e.student_id = s.student_id AND e.section_id = cs.section_id
        )
  )
ORDER BY s.student_code;

-- 15. Teaching workload by lecturer and semester, including zero sections.
SELECT l.lecturer_id, l.last_name, l.first_name, sem.semester_name,
       COUNT(cs.section_id) AS sections
FROM lecturers AS l
CROSS JOIN semesters AS sem
LEFT JOIN course_sections AS cs
       ON cs.lecturer_id = l.lecturer_id AND cs.semester_id = sem.semester_id
GROUP BY l.lecturer_id, l.last_name, l.first_name, sem.semester_id, sem.semester_name
ORDER BY l.lecturer_id, sem.start_date;
