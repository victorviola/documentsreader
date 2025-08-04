from database.connection import get_connection

def get_user_by_email(email: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, emailCode, isEmailVerified, retriesLeft FROM UserData WHERE email = ?",
            (email,)
        )
        row = cursor.fetchone()

    if not row:
        return None

    return {
        "id": row.id,
        "emailCode": row.emailCode,
        "isEmailVerified": row.isEmailVerified,
        "retriesLeft": row.retriesLeft
    }

def get_user_by_uuid(user_uuid: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
                       SELECT ud.id,
                              ud.emailCode,
                              ud.isEmailVerified,
                              ud.retriesLeft
                       FROM UserApp ua
                                JOIN UserData ud ON ua.userDataId = ud.id
                       WHERE ua.userId = ?
                       """, (user_uuid,))

        row = cursor.fetchone()

    if not row:
        return None

    return {
        "id": row.id,
        "emailCode": row.emailCode,
        "isEmailVerified": row.isEmailVerified,
        "retriesLeft": row.retriesLeft
    }

def insert_user_data(email: str, name: str, company: str, email_code: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO UserData (email, name, company, emailCode, isEmailVerified)
            VALUES (?, ?, ?, ?, 0)
        """, (email, name, company, email_code))
        conn.commit()

def update_user_data(id: int, name: str, company: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE UserData SET name = ?, company = ? WHERE id = ?",
            (name, company, id)
        )
        conn.commit()

def mark_email_as_verified(id: int):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("UPDATE UserData SET isEmailVerified = 1 WHERE id = ?", (id,))
        conn.commit()

def check_user_exists(email: str) -> bool:
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM UserData WHERE email = ?", (email,))
        return cursor.fetchone() is not None

def decrement_retries_left(id: int):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE UserData
            SET retriesLeft = CASE
                WHEN retriesLeft > 0 THEN retriesLeft - 1
                ELSE 0
            END
            WHERE id = ?
        """, (id,))
        conn.commit()

def decrement_retries_left_by_uuid(user_uuid: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE ud
            SET ud.retriesLeft = CASE
                WHEN ud.retriesLeft > 0 THEN ud.retriesLeft - 1
                ELSE 0
            END
            FROM UserData ud
            JOIN UserApp ua ON ua.userDataId = ud.id
            WHERE ua.userId = ?
        """, (user_uuid,))
        conn.commit()

