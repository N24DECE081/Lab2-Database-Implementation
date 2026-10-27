-- Remove reporting/capacity objects without deleting business rows.
DROP TRIGGER IF EXISTS trg_enrollment_capacity_insert;
DROP TRIGGER IF EXISTS trg_enrollment_capacity_update;
DROP TRIGGER IF EXISTS trg_section_capacity_update;
DROP VIEW IF EXISTS v_section_occupancy;
DROP PROCEDURE IF EXISTS student_transcript;
