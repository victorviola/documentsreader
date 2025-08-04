from database.connection import get_connection

def insert_verify_code(email: str, code: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO VerifyTokenCode (email, code)
            VALUES (?, ?)
        """, (email, code))
        conn.commit()

def get_pending_code_by_email(email: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT TOP 1 code, isConfirmed, dateCreated
            FROM VerifyTokenCode
            WHERE email = ? AND isConfirmed = 0
            ORDER BY dateCreated DESC
        """, email)
        row = cursor.fetchone()
        if not row:
            return None
        return {
            "code": row.code,
            "isConfirmed": bool(row.isConfirmed),
            "dateCreated": row.dateCreated
        }

def mark_code_as_confirmed(email: str, code: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE VerifyTokenCode
            SET isConfirmed = 1
            WHERE email = ? AND code = ?
        """, (email, code))
        conn.commit()

def reset_all_codes(email: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
                       UPDATE VerifyTokenCode
                       SET isConfirmed = 1
                       WHERE email = ?
                       """, (email))
        conn.commit()

def health_check_db():
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT TOP 1 name FROM TokenTypeEnum")
            row = cursor.fetchone()

            if row and row[0] in ("Enrol", "Verify"):
                return True
            else:
                return False
    except Exception:
        return False