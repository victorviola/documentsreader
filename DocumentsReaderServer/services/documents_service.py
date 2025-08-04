from repositories.UserData import get_user_by_email
from repositories.UserApp import activate_user_app, get_user_app_info_by_user_data
from repositories.Token import get_verify_token, mark_token_used
from repositories.Documents import get_all_documents
from externals.iproov_client import validate_with_iproov

def get_documents_for_user(email: str, token_sent_by_user: str) -> dict:
    try:
        user_data = get_user_by_email(email)
        if not user_data:
            return {"error": "Email not found"}
        if not user_data["isEmailVerified"]:
            return {"error": "Email not verified"}

        user_app = get_user_app_info_by_user_data(user_data["id"])
        if not user_app:
            return {"error": "User not found"}

        token = get_verify_token(user_app["userId"])
        if not token:
            return {"error": "No valid token found for verification. User not verified."}
        if token != token_sent_by_user:
            return {"error": "User not verified."}

        is_verified = validate_with_iproov(user_app["userId"], token, email)
        if not is_verified:
            return {"error": "User verification failed"}
        else:
            if not user_app["isActive"]:
                activate_user_app(user_app["userId"])
                mark_token_used(user_app["userId"], "Verify")
            return {"documents": get_all_documents()}

    except Exception as e:
        return {"error": f"Internal error: {str(e)}"}