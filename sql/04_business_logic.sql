-- MySQL view, stored procedure and triggers for reporting and capacity integrity.

DROP VIEW IF EXISTS v_section_occupancy;
CREATE VIEW v_section_occupancy AS
SELECT cs.section_id, c.course_code, c.course_name, sem.semester_name,
       cs.section_number, cs.capacity,
       COUNT(e.enrollment_id) AS enrolled,
       cs.capacity - COUNT(e.enrollment_id) AS available_seats
FROM course_sections AS cs
JOIN courses AS c ON c.course_id = cs.course_id
JOIN semesters AS sem ON sem.semester_id = cs.semester_id
LEFT JOIN enrollments AS e ON e.section_id = cs.section_id
GROUP BY cs.section_id, c.course_code, c.course_name, sem.semester_name,
         cs.section_number, cs.capacity;

DROP PROCEDURE IF EXISTS student_transcript;
DELIMITER $$
CREATE PROCEDURE student_transcript(IN p_student_id INT)
READS SQL DATA
BEGIN
    SELECT e.enrollment_id, sem.semester_name, c.course_code, c.course_name,
           c.credit_hours, e.final_grade
    FROM enrollments AS e
    JOIN course_sections AS cs ON cs.section_id = e.section_id
    JOIN courses AS c ON c.course_id = cs.course_id
    JOIN semesters AS sem ON sem.semester_id = cs.semester_id
    WHERE e.student_id = p_student_id
    ORDER BY sem.start_date, c.course_code;
END$$

DROP TRIGGER IF EXISTS trg_enrollment_capacity_insert$$
CREATE TRIGGER trg_enrollment_capacity_insert
BEFORE INSERT ON enrollments
FOR EACH ROW
BEGIN
    DECLARE section_capacity INT;
    DECLARE current_enrollment INT;
    SELECT capacity INTO section_capacity
    FROM course_sections
    WHERE section_id = NEW.section_id
    FOR UPDATE;
    SELECT COUNT(*) INTO current_enrollment
    FROM enrollments
    WHERE section_id = NEW.section_id;
    IF current_enrollment >= section_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Section capacity exceeded';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_enrollment_capacity_update$$
CREATE TRIGGER trg_enrollment_capacity_update
BEFORE UPDATE ON enrollments
FOR EACH ROW
BEGIN
    DECLARE section_capacity INT;
    DECLARE current_enrollment INT;
    IF NEW.section_id <> OLD.section_id THEN
        SELECT capacity INTO section_capacity
        FROM course_sections
        WHERE section_id = NEW.section_id
        FOR UPDATE;
        SELECT COUNT(*) INTO current_enrollment
        FROM enrollments
        WHERE section_id = NEW.section_id AND enrollment_id <> OLD.enrollment_id;
        IF current_enrollment >= section_capacity THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Section capacity exceeded';
        END IF;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_section_capacity_update$$
CREATE TRIGGER trg_section_capacity_update
BEFORE UPDATE ON course_sections
FOR EACH ROW
BEGIN
    DECLARE current_enrollment INT;
    IF NEW.capacity <> OLD.capacity THEN
        SELECT COUNT(*) INTO current_enrollment
        FROM enrollments
        WHERE section_id = OLD.section_id;
        IF NEW.capacity < current_enrollment THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Capacity cannot be lower than current enrollment';
        END IF;
    END IF;
END$$
DELIMITER ;
