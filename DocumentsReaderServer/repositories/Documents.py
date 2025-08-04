from database.connection import get_connection

def get_all_documents():
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id, title, link FROM Documents")
        rows = cursor.fetchall()

        return [
            {"id": row.id, "title": row.title, "link": row.link}
            for row in rows
        ]