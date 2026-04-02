import sqlite3
import os
import sys

# Add the backend directory to sys.path to import main
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from main import init_db

def test_migration():
    db_path = "users.db"
    # Ensure we are working with a clean state or the current state
    # For this test, we want to see if init_db adds what's missing.
    
    init_db()
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check if reports table exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='reports'")
    if not cursor.fetchone():
        print("FAIL: reports table does not exist")
        conn.close()
        return False
    print("PASS: reports table exists")
    
    # Check columns in users table
    cursor.execute("PRAGMA table_info(users)")
    columns = [row[1] for row in cursor.fetchall()]
    
    required_columns = ["is_banned", "ban_expires_at", "ban_reason"]
    for col in required_columns:
        if col not in columns:
            print(f"FAIL: column {col} does not exist in users table")
            conn.close()
            return False
        print(f"PASS: column {col} exists in users table")
        
    conn.close()
    return True

if __name__ == "__main__":
    if test_migration():
        print("Migration test PASSED")
        sys.exit(0)
    else:
        print("Migration test FAILED")
        sys.exit(1)
