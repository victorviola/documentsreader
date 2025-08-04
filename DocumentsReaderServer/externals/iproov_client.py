import os
import requests
from fastapi import HTTPException
from dotenv import load_dotenv

load_dotenv()

IPROOV_API_KEY = os.getenv("IPROOV_API_KEY")
IPROOV_SECRET = os.getenv("IPROOV_SECRET")
IPROOV_API_ROOT = os.getenv("IPROOV_API_ROOT", "https://eu.rp.secure.iproov.me/api/v2").rstrip("/")
RESOURCE = "App Documents Reader"


def _build_url(path: str) -> str:
    return f"{IPROOV_API_ROOT}/{path.lstrip('/')}"


def request_enrol_token(user_id: str):
    payload = {
        "api_key": IPROOV_API_KEY,
        "secret": IPROOV_SECRET,
        "resource": RESOURCE,
        "assurance_type": "genuine_presence",
        "user_id": str(user_id)
    }
    response = requests.post(_build_url("claim/enrol/token"), json=payload)
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()["token"]


def send_enrol_image(token, photo_data):
    files = {
        "image": ("selfie.png", photo_data, "image/png")
    }
    data = {
        "api_key": IPROOV_API_KEY,
        "secret": IPROOV_SECRET,
        "rotation": "0",
        "token": token,
        "source": "selfie"
    }
    response = requests.post(_build_url("claim/enrol/image"), data=data, files=files)
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()["token"]


def request_verify_token(user_id: str):
    payload = {
        "api_key": IPROOV_API_KEY,
        "secret": IPROOV_SECRET,
        "resource": RESOURCE,
        "assurance_type": "genuine_presence",
        "user_id": str(user_id)
    }
    response = requests.post(_build_url("claim/verify/token"), json=payload)
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()["token"]


def validate_with_iproov(user_id: str, token: str, email: str):
    payload = {
        "api_key": IPROOV_API_KEY,
        "secret": IPROOV_SECRET,
        "user_id": user_id,
        "token": token,
        "client": email
    }
    try:
        response = requests.post(_build_url("claim/verify/validate"), json=payload)
        response.raise_for_status()
        data = response.json()
        return data.get("passed")
    except Exception as e:
        print("iProov validation error:", e)
        return False