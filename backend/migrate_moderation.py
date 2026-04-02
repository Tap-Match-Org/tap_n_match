import sqlite3

def migrate():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()

    # Update Users Table
    try:
        cursor.execute("ALTER TABLE users ADD COLUMN is_banned INTEGER DEFAULT 0")
        cursor.execute("ALTER TABLE users ADD COLUMN ban_reason TEXT")
    except sqlite3.OperationalError:
        print("Columns already exist in users table.")

    # Create Reports Table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reporter_id INTEGER,
            reported_id INTEGER,
            reason TEXT,
            timestamp TEXT,
            status TEXT DEFAULT 'Pending'
        )
    """)

    # Create Support/Feedback Table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS support_tickets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            type TEXT,
            message TEXT,
            status TEXT DEFAULT 'Open',
            timestamp TEXT
        )
    """)

    # Create Appeals Table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS appeals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            appeal_text TEXT,
            status TEXT DEFAULT 'Pending',
            timestamp TEXT
        )
    """)

    conn.commit()
    conn.close()
    print("Migration complete.")

if __name__ == "__main__":
    migrate()
