-- MySQL roles and restricted login accounts.
CREATE ROLE IF NOT EXISTS 'app_user'@'%', 'report_user'@'%';

SET @create_api = CONCAT(
    "CREATE USER IF NOT EXISTS 'lab_api'@'%' IDENTIFIED BY ", QUOTE(@app_password)
);
PREPARE create_api_stmt FROM @create_api;
EXECUTE create_api_stmt;
DEALLOCATE PREPARE create_api_stmt;

SET @create_report = CONCAT(
    "CREATE USER IF NOT EXISTS 'lab_report'@'%' IDENTIFIED BY ", QUOTE(@report_password)
);
PREPARE create_report_stmt FROM @create_report;
EXECUTE create_report_stmt;
DEALLOCATE PREPARE create_report_stmt;

GRANT SELECT, INSERT, UPDATE, DELETE ON student_reg_db.* TO 'app_user'@'%';
GRANT EXECUTE ON PROCEDURE student_reg_db.student_transcript TO 'app_user'@'%';
GRANT SELECT ON student_reg_db.* TO 'report_user'@'%';
GRANT EXECUTE ON PROCEDURE student_reg_db.student_transcript TO 'report_user'@'%';

GRANT 'app_user'@'%' TO 'lab_api'@'%';
GRANT 'report_user'@'%' TO 'lab_report'@'%';
SET DEFAULT ROLE 'app_user'@'%' TO 'lab_api'@'%';
SET DEFAULT ROLE 'report_user'@'%' TO 'lab_report'@'%';
