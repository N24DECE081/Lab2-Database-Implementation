from fastapi import FastAPI, HTTPException, Path, Query, Request, Response
from fastapi.responses import JSONResponse
from mysql.connector import Error as DatabaseError

from app import db, models

app = FastAPI(title="Student Course Registration API", version="3.0.0",
    description="MySQL lab API. Local classroom demo; database roles enforce service permissions.")


@app.exception_handler(DatabaseError)
def database_error(request: Request, exc):
    if exc.errno in {2002, 2003, 2006, 2013}:
        return JSONResponse(status_code=503, content={"detail": "Database unavailable"})
    code = exc.errno
    if code == 1062:
        status, message = 409, "A record with this unique key already exists"
    elif code in {1451, 1452}:
        status, message = 409, "Referenced record is missing or this record is still in use"
    elif code in {1644, 3819}:
        status, message = 409, "Business constraint violated (check values or section capacity)"
    elif code in {1048, 1264, 1292, 1366, 1406}:
        status, message = 422, "Invalid database value"
    elif code in {1044, 1045, 1142, 1227}:
        status, message = 403, "Database role does not permit this operation"
    else:
        status, message = 500, "Database operation failed"
    return JSONResponse(status_code=status, content={"detail": message})


@app.get("/")
def root():
    return {"message": "Use /docs for Swagger UI and /redoc for ReDoc."}


@app.get("/health")
def healthcheck():
    return {"status": "ok", "service": "student-course-registration"}


@app.get("/ready", tags=["Operations"])
def readiness():
    db.query("SELECT 1")
    return {"status": "ok", "database": "connected"}


def require_row(row):
    if row is None:
        raise HTTPException(404, "Record not found")
    return row


def register_resource(resource, model):
    def listing(request: Request, limit: int = Query(100, ge=1, le=1000),
                offset: int = Query(0, ge=0)):
        allowed = db.RESOURCES[resource][2]
        unknown = set(request.query_params) - set(allowed) - {"limit", "offset"}
        if unknown:
            raise HTTPException(422, f"Unsupported filters: {', '.join(sorted(unknown))}")
        filters = {key: request.query_params[key] for key in allowed if key in request.query_params}
        for key, value in filters.items():
            if key.endswith("_id"):
                try:
                    if not 0 < int(value) <= 2147483647:
                        raise ValueError
                except ValueError:
                    raise HTTPException(422, f"{key} must be a positive integer")
        return db.list_rows(resource, limit, offset, filters)

    def detail(item_id: int = Path(gt=0, le=2147483647)):
        return require_row(db.get_row(resource, item_id))

    def create(payload: model):
        return db.save_row(resource, payload.model_dump())

    def replace(payload: model, item_id: int = Path(gt=0, le=2147483647)):
        return require_row(db.save_row(resource, payload.model_dump(), item_id))

    def remove(item_id: int = Path(gt=0, le=2147483647)):
        require_row(db.delete_row(resource, item_id))
        return Response(status_code=204)

    for suffix, method, handler, status in [
        ("", "GET", listing, 200), ("/{item_id}", "GET", detail, 200),
        ("", "POST", create, 201), ("/{item_id}", "PUT", replace, 200),
        ("/{item_id}", "DELETE", remove, 204),
    ]:
        app.add_api_route(f"/{resource}{suffix}", handler, methods=[method],
            tags=[resource], status_code=status, name=f"{method.lower()}_{resource}",
            operation_id=f"{method.lower()}_{resource.replace('-', '_')}{'_item' if suffix else ''}")


for resource, model in zip(db.RESOURCES, [models.Department, models.AdministrativeClass,
        models.Student, models.Lecturer, models.Course, models.Semester,
        models.CourseSection, models.Enrollment]):
    register_resource(resource, model)


@app.patch("/enrollments/{item_id}/grade", tags=["enrollments"])
def update_grade(payload: models.GradeUpdate, item_id: int = Path(gt=0, le=2147483647)):
    return require_row(db.save_row("enrollments", payload.model_dump(), item_id))


@app.get("/reports/section-occupancy", tags=["Reports"])
def occupancy():
    return db.query("SELECT * FROM v_section_occupancy ORDER BY section_id")


@app.get("/reports/students/{student_id}/transcript", tags=["Reports"])
def transcript(student_id: int = Path(gt=0, le=2147483647)):
    require_row(db.get_row("students", student_id))
    return db.call_transcript(student_id)
