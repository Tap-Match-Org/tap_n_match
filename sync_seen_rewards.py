import sqlite3

def fix_seen_rewards():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    
    # 1. Update the 'seen_rewards' entries that still have the old path
    cursor.execute("""
        UPDATE users 
        SET seen_rewards = REPLACE(seen_rewards, 'assets/background_color/minecraft_bgColor.jpg', 'assets/background/minecraft_bgColor.jpg')
    """)
    
    # 2. Specifically for DangerMarlow, make sure Genshin is also marked as seen 
    # (since we identified it was missing in the debug run)
    cursor.execute("SELECT seen_rewards FROM users WHERE username = 'DangerMarlow'")
    row = cursor.fetchone()
    if row:
        seen = [s.strip() for s in row[0].split(",") if s.strip()]
        genshin = "asset:assets/background/genshin_background.jpeg"
        if genshin not in seen:
            seen.append(genshin)
            new_seen_str = ",".join(seen)
            cursor.execute("UPDATE users SET seen_rewards = ? WHERE username = 'DangerMarlow'", (new_seen_str,))
            print("Manually added Genshin background to DangerMarlow's seen list.")

    conn.commit()
    conn.close()
    print("Database sync complete.")

if __name__ == '__main__':
    fix_seen_rewards()
