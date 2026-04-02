import sqlite3
import os

def get_schema(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    schema = {}
    for table_name in tables:
        table_name = table_name[0]
        cursor.execute(f"PRAGMA table_info({table_name});")
        schema[table_name] = cursor.fetchall()
    conn.close()
    return schema

if __name__ == "__main__":
    db_path = "backend/users.db"
    if os.path.exists(db_path):
        schema = get_schema(db_path)
        for table, columns in schema.items():
            print(f"Table: {table}")
            for col in columns:
                print(f"  {col}")
    else:
        print(f"Database not found at {db_path}")
