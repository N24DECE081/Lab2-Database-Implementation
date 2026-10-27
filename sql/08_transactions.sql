-- Safe MySQL transaction example; the grade change is rolled back.
START TRANSACTION;
SAVEPOINT before_grade;
UPDATE enrollments SET final_grade = 9.0 WHERE enrollment_id = 2;
SELECT enrollment_id, final_grade FROM enrollments WHERE enrollment_id = 2;
ROLLBACK TO SAVEPOINT before_grade;
SELECT enrollment_id, final_grade FROM enrollments WHERE enrollment_id = 2;
ROLLBACK;
