"""Small command-line demonstration of MySQL reads and transactional CSV writes."""
import argparse
import csv
from pathlib import Path

from app import db
from app.models import Student


def import_students(path):
    with Path(path).open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        expected = set(Student.model_fields)
        if set(reader.fieldnames or []) != expected:
            raise ValueError(f"CSV columns must be: {', '.join(sorted(expected))}")
        rows = [Student(**row).model_dump() for row in reader]
    inserted = 0
    with db.connection() as conn, conn.cursor() as cur:
        # Only an already-known student_code is skipped.  INSERT IGNORE would
        # also hide FK, CHECK and email errors, which breaks the all-or-nothing
        # transaction promised by this command.
        cur.execute("SELECT student_code FROM students")
        existing_codes = {record[0] for record in cur.fetchall()}
        for row in rows:
            if row["student_code"] in existing_codes:
                continue
            columns = ",".join(f"`{field}`" for field in row)
            placeholders = ",".join("%s" for _ in row)
            cur.execute(
                f"INSERT INTO students ({columns}) VALUES ({placeholders})",
                list(row.values()),
            )
            inserted += 1
            existing_codes.add(row["student_code"])
    return {"read": len(rows), "inserted": inserted, "skipped_existing_code": len(rows) - inserted}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("list-students")
    importer = sub.add_parser("import-students")
    importer.add_argument("csv_file")
    args = parser.parse_args()
    if args.action == "import-students":
        print(import_students(args.csv_file))
    else:
        for row in db.query("""SELECT s.student_code, s.last_name, s.first_name, ac.class_name
                              FROM students AS s
                              JOIN administrative_classes AS ac USING (class_id)
                              ORDER BY s.student_id"""):
            print(row)


if __name__ == "__main__":
    main()
