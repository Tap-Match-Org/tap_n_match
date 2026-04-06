import sqlite3

def debug_seen_rewards():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    
    cursor.execute("SELECT id, username, unlocked_themes, seen_rewards FROM users WHERE username = 'DangerMarlow'")
    user = cursor.fetchone()
    if not user:
        print("User DangerMarlow not found.")
        conn.close()
        return

    print(f"User ID: {user[0]}, Username: {user[1]}")
    print(f"Unlocked Themes: '{user[2]}'")
    print(f"Seen Rewards:    '{user[3]}'")
    
    unlocked = [t.strip() for t in user[2].split(",") if t.strip()]
    seen = [t.strip() for t in user[3].split(",") if t.strip()]
    
    not_seen = [t for t in unlocked if t not in seen]
    print(f"\nUnlocked but NOT in Seen list: {not_seen}")
    
    conn.close()

if __name__ == '__main__':
    debug_seen_rewards()
