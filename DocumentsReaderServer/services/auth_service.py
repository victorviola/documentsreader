import os
import random
import smtplib
import uuid
from fastapi import HTTPException,UploadFile
from email.message import EmailMessage
from dotenv import load_dotenv

import externals.iproov_client as iproov
import repositories.Token as token_repo
import repositories.UserApp as user_app_repo
import repositories.UserData as user_data_repo
import repositories.VerifyTokenCode as code_repo
import services.image_service as image_service
import services.verify_service as verify_service

load_dotenv()

EMAIL_SENDER = os.getenv("EMAIL_SENDER")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD")
EMAIL_SMTP = os.getenv("EMAIL_SMTP")
EMAIL_PORT = int(os.getenv("EMAIL_PORT", 587))

def confirm_email_logic(email: str, code: str):
    user = user_data_repo.get_user_by_email(email)

    if not user:
        raise HTTPException(status_code=404, detail="Email not found")

    if user["isEmailVerified"]:
        return {"verified": True, "message": "Email already verified"}

    if user["emailCode"] != code:
        raise HTTPException(status_code=400, detail="Invalid code")

    user_data_repo.mark_email_as_verified(user["id"])

    return {"verified": True, "message": "Email confirmed"}

async def handle_user_registration(name: str, company: str, email: str, photo: UploadFile):
    user_data = user_data_repo.get_user_by_email(email)

    if not user_data:
        raise HTTPException(status_code=400, detail="Email not registered")
    if not user_data["isEmailVerified"]:
        raise HTTPException(status_code=400, detail="Email not verified")

    photo_bytes = image_service.resize_and_convert_image(photo)
    user_id = str(uuid.uuid4())

    try:
        enrol_token = iproov.request_enrol_token(user_id)
        iproov.send_enrol_image(enrol_token, photo_bytes)

        user_data_repo.update_user_data(user_data["id"], name, company)
        user_app_repo.insert_user_app(user_data["id"], user_id)

        verify_token = await verify_service.generate_verification_token(user_id)
    except HTTPException as e:
        raise HTTPException(status_code=e.status_code, detail=f"iProov enrol failed: {e.detail}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error during enrolment: {str(e)}")

    try:
        token_repo.insert_token(user_id, enrol_token, "Enrol", used=True)
        token_repo.insert_token(user_id, verify_token, "Verify", used=False)
    except:
        raise HTTPException(status_code=500, detail="Database error during enrolment")
    return {"token": verify_token, "success": "true"}

async def generate_verify_token_logic(email: str, code: str) -> dict:
    try:
        user_data = user_data_repo.get_user_by_email(email)
        if not user_data:
            return {"error": "Email not found"}
        if not user_data["isEmailVerified"]:
            return {"error": "Email is not verified"}

        pending_code = code_repo.get_pending_code_by_email(email)
        if not pending_code or pending_code["code"] != code:
            return {"error": "Invalid or expired verification code"}

        user_app = user_app_repo.get_user_app_info_by_user_data(user_data["id"])
        if not user_app:
            return {"error": "User not found"}

        enrol_token = token_repo.get_enrol_token(user_app["userId"])
        if not enrol_token:
            return {"error": "User has not completed enrolment"}

        token_repo.mark_token_used(user_app["userId"], "Verify")

        verify_token = await verify_service.generate_verification_token(user_app["userId"])
        token_repo.insert_token(user_app["userId"], verify_token, "Verify", used=False)

        code_repo.mark_code_as_confirmed(email, code)

        return {"token": verify_token}

    except Exception as e:
        return {"error": f"Internal error: {str(e)}"}


def generate_verification_code() -> str:
    return str(random.randint(10000, 99999))

def send_verification_email(email: str, code: str):
    msg = EmailMessage()
    msg["Subject"] = "Your Verification Code"
    msg["From"] = EMAIL_SENDER
    msg["To"] = email
    msg.set_content(f"Your confirmation code is: {code}")

    try:
        with smtplib.SMTP(EMAIL_SMTP, EMAIL_PORT) as server:
            server.starttls()
            server.login(EMAIL_SENDER, EMAIL_PASSWORD)
            server.send_message(msg)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

def handle_register_email(email: str) -> dict:
    if user_data_repo.check_user_exists(email):
        raise HTTPException(status_code=409, detail="Email already exists")

    code = generate_verification_code()

    user_data_repo.insert_user_data(email=email, name=None, company=None, email_code=code)
    send_verification_email(email, code)

    return {"message": "Verification code sent to email"}

def confirm_email_verify_code(email: str, code: str) -> dict:
    try:
        existing = code_repo.get_pending_code_by_email(email)
        if not existing:
            return {"error": "No verification code found for this email."}

        if str(existing["code"]) != code:
            return {"error": "Invalid verification code."}

        code_repo.mark_code_as_confirmed(email, code)
        return {"message": "Code confirmed successfully."}
    except Exception as e:
        return {"error": f"Internal error: {str(e)}"}

def send_email_verify_code(email: str) -> dict:
    try:

        user_data = user_data_repo.get_user_by_email(email)

        if user_data is None:
            return {"error": f"Internal error: email not found"}

        code_repo.reset_all_codes(email)
        code = generate_verification_code()

        code_repo.insert_verify_code(email, code)
        send_verification_email(email, code)
        return {"message": "Verification code sent to email."}
    except Exception as e:
        return {"error": f"Internal error: {str(e)}"}




