#!/bin/sh
set -eu

mysql --protocol=socket -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" <<SQL
SOURCE /lab/sql/01_schema.sql;
SOURCE /lab/sql/04_business_logic.sql;
SOURCE /lab/sql/02_seed_data.sql;
SOURCE /lab/sql/06_metadata.sql;
SET @app_password = '${APP_DB_PASSWORD:-lab_api_dev}';
SET @report_password = '${REPORT_DB_PASSWORD:-lab_report_dev}';
SOURCE /lab/sql/05_access_control.sql;
SQL
