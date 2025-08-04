from fastapi import APIRouter
from fastapi.responses import JSONResponse
from database.connection import get_connection
from repositories.VerifyTokenCode import health_check_db

router = APIRouter(prefix="/healthcheck", tags=["Healthcheck"])

@router.get("/status")
def check_status():
    return JSONResponse(content={"status": "success", "message": "Backend is reachable"}, status_code=200)
@router.get("/database")
def check_database():
    try:
        with get_connection() as conn:
            if not conn:
                raise Exception("No DB connection returned")

            if health_check_db():
                return JSONResponse(
                    content={"status": "success", "message": "Database is reachable and schema appears to be present"},
                    status_code=200
                )
            else:
                return JSONResponse(
                    content={"status": "failed", "message": "Database is running but database model is missing"},
                    status_code=500
                )

    except Exception:
        return JSONResponse(
            content={"status": "failed", "message": "Database is not running"},
            status_code=500
        )

