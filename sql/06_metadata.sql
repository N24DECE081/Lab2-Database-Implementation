-- MySQL metadata queries. Table and column comments are declared in 01_schema.sql.

SELECT table_name, table_comment
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT table_name, ordinal_position, column_name, column_type,
       is_nullable, column_default, column_key, extra, column_comment
FROM information_schema.columns
WHERE table_schema = DATABASE()
ORDER BY table_name, ordinal_position;

SELECT table_name, index_name, non_unique, seq_in_index, column_name, index_type
FROM information_schema.statistics
WHERE table_schema = DATABASE()
ORDER BY table_name, index_name, seq_in_index;

SELECT table_name, constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE constraint_schema = DATABASE()
ORDER BY table_name, constraint_type, constraint_name;

SELECT trigger_name, event_manipulation, event_object_table, action_timing
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
ORDER BY trigger_name;

SELECT routine_name, routine_type, sql_data_access, security_type
FROM information_schema.routines
WHERE routine_schema = DATABASE()
ORDER BY routine_name;
