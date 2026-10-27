-- Optional MySQL reset. Run only inside student_reg_db when a full rebuild is intended.
SET FOREIGN_KEY_CHECKS = 0;
DROP VIEW IF EXISTS v_section_occupancy;
DROP PROCEDURE IF EXISTS student_transcript;
DROP TABLE IF EXISTS enrollments, course_sections, semesters, courses,
                     lecturers, students, administrative_classes, departments;
SET FOREIGN_KEY_CHECKS = 1;
