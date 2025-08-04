from fastapi import APIRouter, Form, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from models.schemas import EmailConfirmationRequest, EmailRequest
from services.auth_service import confirm_email_logic, confirm_email_verify_code, handle_user_registration, \
    generate_verify_token_logic, handle_register_email, send_email_verify_code

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/confirm-email")
async def confirm_email(payload: EmailConfirmationRequest):
    try:
        result = confirm_email_logic(payload.email, payload.code)
        return JSONResponse(content=result, status_code=200)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/confirm-email-verify-code")
async def confirm_verify_code_route(payload: EmailConfirmationRequest):

    result = confirm_email_verify_code(payload.email, payload.code)

    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])

    return JSONResponse(content={"message": result["message"]}, status_code=200)

@router.post("/enrol")
async def register_user(
    name: str = Form(...),
    company: str = Form(...),
    email: str = Form(...),
    photo: UploadFile = Form(...)
):
    try:
        result = await handle_user_registration(name, company, email, photo)
        return JSONResponse(content=result, status_code=200)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate-verify-token")
async def generate_verify_token(payload: EmailConfirmationRequest):
    result = await generate_verify_token_logic(payload.email, payload.code)

    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    if "message" in result:
        return JSONResponse(content={"message": result["message"]}, status_code=200)

    return JSONResponse(content=result, status_code=200)

@router.post("/register-email")
async def register_email(payload: EmailRequest):
    try:
        result = handle_register_email(payload.email)
        return JSONResponse(content=result, status_code=200)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/send-email-verify-code")
async def send_verify_code_route(payload: EmailRequest):

    result = send_email_verify_code(payload.email)

    if "error" in result:
        raise HTTPException(status_code=500, detail=result["error"])

    return JSONResponse(content={"message": result["message"]}, status_code=200)
