from database.connection import get_connection

def get_user_app_info_by_user_data(user_data_id: int):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
                       SELECT userId, userDataId, isActive
                       FROM UserApp
                       WHERE userDataId = ?
                       """, user_data_id)
        row = cursor.fetchone()

        if not row:
            return None

        return {
            "userId": row.userId,
            "userDataId": row.userDataId,
            "isActive": bool(row.isActive),
        }

def get_user_app_info_by_userId(user_id: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT userId, userDataId, isActive
            FROM UserApp
            WHERE userId = ?
        """, user_id)
        row = cursor.fetchone()

        if not row:
            return None

        return {
            "userId": row[0],
            "userDataId": row[1],
            "isActive": bool(row[2])
        }

def insert_user_app(user_data_id: int, user_id: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO UserApp (userId, userDataId, isActive) VALUES (?, ?, 0)",
            (user_id, user_data_id)
        )
        conn.commit()

def activate_user_app(user_id: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE UserApp
            SET isActive = 1
            WHERE userId = ?
        """, user_id)
        conn.commit()