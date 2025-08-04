from database.connection import get_connection

def get_enrol_token(user_id: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT token FROM Token
            WHERE userId = ? AND tokenUsed = 1 AND type = 'Enrol' ORDER BY dateCreated DESC
        """, user_id)
        row = cursor.fetchone()
        if not row:
            return None
        return row[0]

def get_verify_token(user_id: str):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT token FROM Token
            WHERE userId = ? AND tokenUsed = 0 AND type = 'Verify' ORDER BY dateCreated DESC
        """, user_id)
        row = cursor.fetchone()
        if not row:
            return None
        return row[0]

def insert_token(user_id, token, type, used=False):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO Token (userId, token, type, tokenUsed)
            VALUES (?, ?, ?, ?)
        """, user_id, token, type, used)
        conn.commit()

def mark_token_used(user_id, type):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE Token
            SET tokenUsed = 1
            WHERE userId = ? AND type = ?
        """, user_id, type)
        conn.commit()
