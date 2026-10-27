# MySQL Sakila sample database

Lab 2 yêu cầu tải, tạo, nhập và truy vấn một cơ sở dữ liệu mẫu. Bài này dùng **Sakila**, bộ dữ liệu mẫu chính thức của MySQL.

- Trang tài liệu: <https://dev.mysql.com/doc/sakila/en/>
- File tải chính thức: <https://downloads.mysql.com/docs/sakila-db.zip>
- Dự phòng khi CDN Oracle lỗi: <https://github.com/jOOQ/sakila/tree/main/mysql-sakila-db> (bản mirror các script Sakila MySQL)
- Nội dung: cửa hàng cho thuê phim giả lập gồm film, actor, category, customer, rental, payment và các bảng liên quan.
- Mục đích sử dụng: minh họa tạo database, import DDL/DML, JOIN, LEFT JOIN, GROUP BY và subquery.

Chạy:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/import-sample.ps1
```

Script tải ZIP nếu chưa có, giải nén, nhập `sakila-schema.sql` và `sakila-data.sql` vào MySQL Docker, sau đó chạy `sql/07_external_sample_queries.sql`. Database `sakila` độc lập với `student_reg_db`, nên không làm thay đổi ERD của bài đăng ký học phần.

Các file ZIP/SQL tải về là dữ liệu sinh tự động cục bộ và không cần commit vào Git.
