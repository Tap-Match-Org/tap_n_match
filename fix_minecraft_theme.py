import sqlite3
import os

db_path = "users.db"
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check current themes
    cursor.execute("SELECT id, username, unlocked_themes FROM users")
    users = cursor.fetchall()
    
    print("Before fix:")
    for user in users:
        print(f"User ID: {user[0]}, Username: {user[1]}, Themes: {user[2]}")
    
    # Update themes
    cursor.execute("UPDATE users SET unlocked_themes = REPLACE(unlocked_themes, 'assets/background_color/minecraft_bgColor.jpg', 'assets/background/minecraft_bgColor.jpg')")
    cursor.execute("UPDATE users SET selected_theme = REPLACE(selected_theme, 'assets/background_color/minecraft_bgColor.jpg', 'assets/background/minecraft_bgColor.jpg')")
    
    conn.commit()
    
    print("\nAfter fix:")
    cursor.execute("SELECT id, username, unlocked_themes FROM users")
    users = cursor.fetchall()
    for user in users:
        print(f"User ID: {user[0]}, Username: {user[1]}, Themes: {user[2]}")
        
    conn.close()
else:
    print("Database not found.")
