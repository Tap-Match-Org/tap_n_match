import sqlite3

def unlock_snowfall():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    
    snowfall = "asset:assets/background/snowfall_background.jpeg"
    username = "DangerMarlow"
    
    cursor.execute("SELECT unlocked_themes, seen_rewards FROM users WHERE username = ?", (username,))
    row = cursor.fetchone()
    if not row:
        print(f"User {username} not found.")
        conn.close()
        return

    unlocked = [t.strip() for t in row[0].split(",") if t.strip()]
    seen = [t.strip() for t in row[1].split(",") if t.strip()]
    
    if snowfall not in unlocked:
        unlocked.append(snowfall)
    if snowfall not in seen:
        seen.append(snowfall)
        
    cursor.execute("UPDATE users SET unlocked_themes = ?, seen_rewards = ? WHERE username = ?", 
                   (",".join(unlocked), ",".join(seen), username))
    
    conn.commit()
    conn.close()
    print(f"Snowfall background unlocked and marked as seen for {username}.")

if __name__ == '__main__':
    unlock_snowfall()
