from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from models.schemas import DocumentRequest
from services.documents_service import get_documents_for_user
router = APIRouter(prefix="/documents", tags=["Documents"])
@router.post("/list")
async def get_documents(request: DocumentRequest):

    result = get_documents_for_user(request.email, request.token)

    if "error" in result:
        msg = result["error"]
        if msg == "Email not found":
            raise HTTPException(status_code=404, detail=msg)
        elif msg == "No valid token found for verification":
            raise HTTPException(status_code=400, detail=msg)
        elif msg == "User verification failed":
            raise HTTPException(status_code=403, detail=msg)
        else:
            raise HTTPException(status_code=500, detail=msg)

    return JSONResponse(content=result["documents"], status_code=200)
