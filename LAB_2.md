# Lab 2 - MySQL Deployment, Programming and API

## Phạm vi bài nộp

Lab 2 là bài thực hành DBMS. DBMS chọn là **MySQL 8.4** chạy bằng Docker Desktop. Bài dùng hai database độc lập:

- `student_reg_db`: database đã triển khai để minh họa quyền truy cập, Python đọc/ghi và API.
- `sakila`: database mẫu chính thức của MySQL, được tải/import riêng đúng phần dữ liệu mẫu của đề.

## Đối chiếu yêu cầu đề bài

| Yêu cầu Lab 2 | Cách hoàn thành / minh chứng |
|---|---|
| Cài DBMS và deploy database | `docker-compose.yml`, `docker/init/01_initialize.sh`, `sql/01_schema.sql` |
| Access control và user classification | `sql/05_access_control.sql`: root, `lab_api` (CRUD), `lab_report` (read-only), role `app_user`, `report_user` |
| Tải sample database | `scripts/import-sample.ps1` tải ZIP Sakila từ MySQL |
| Tạo/import sample database | Script giải nén và import `sakila-schema.sql`, `sakila-data.sql` vào database `sakila` |
| Chạy SELECT lấy thông tin | `sql/07_external_sample_queries.sql` trên Sakila; `sql/03_sample_queries.sql` trên student_reg_db |
| Python kết nối DB | `app/config.py`, `app/db.py` dùng `mysql-connector-python` |
| Python query, hiển thị kết quả | `python -m app.cli list-students` |
| Python ghi dữ liệu | `python -m app.cli import-students data/students.csv` |
| Đóng kết nối | Context manager ở `app/db.py` luôn `close()` trong `finally` |
| API library tương tác DB | `app/main.py`, FastAPI CRUD/report endpoints; Swagger `/docs` |
| Test API | `tests/` và Postman collection `postman/student_course_registration.postman_collection.json` |
| Nêu nguồn dữ liệu | `data/external/README.md` ghi rõ nguồn Sakila và cách sử dụng |

## Chạy và chứng minh bài

```powershell
docker compose up -d --build
powershell -ExecutionPolicy Bypass -File scripts/import-sample.ps1
docker compose exec api python -m app.cli list-students
docker compose exec api python -m app.cli import-students data/students.csv
docker compose --profile test run --rm tests
```

Mở <http://localhost:8001/docs> để thử API hoặc import Postman collection. Có thể chạy toàn bộ kiểm tra bằng:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-labs.ps1
```

## Nguồn dữ liệu mẫu

Sakila là sample database chính thức của MySQL: <https://dev.mysql.com/doc/sakila/en/>. Bài chỉ dùng dữ liệu này để đáp ứng yêu cầu tải, import và truy vấn CSDL mẫu; không dùng Sakila để thiết kế ERD của Lab 1.
