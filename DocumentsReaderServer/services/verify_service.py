from fastapi import HTTPException
from externals.iproov_client import request_verify_token
from repositories.UserData import decrement_retries_left_by_uuid, get_user_by_uuid
from repositories.UserApp import get_user_app_info_by_userId

async def generate_verification_token(user_id: str):

    user = get_user_app_info_by_userId(user_id)

    if user and user["isActive"]:
        try:
            verify_token = request_verify_token(user_id)
            return verify_token
        except HTTPException as e:
            raise HTTPException(status_code=e.status_code, detail=f"iProov verify service failed: {e.detail}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Unexpected error during the get of the token: {str(e)}")
    elif not user["isActive"]:
        try:
            retries_left = get_user_by_uuid(user_id)["retriesLeft"]
            if retries_left <= 0:
                raise HTTPException(status_code=500, detail=f"No more retries left")
            else:
                verify_token = request_verify_token(user_id)
                decrement_retries_left_by_uuid(user_id)
                return verify_token
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Unexpected error during verification: {str(e)}")
    else:
        raise HTTPException(status_code=500, detail=f"User not found")


