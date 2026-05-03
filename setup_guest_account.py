import sqlite3
import os

def setup_guest_account():
    db_path = "users.db"
    if not os.path.exists(db_path):
        print(f"Error: {db_path} not found. Run the backend first to initialize the DB.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check if guest user already exists
    cursor.execute("SELECT id FROM users WHERE id = 9999")
    if cursor.fetchone():
        print("Guest account (ID 9999) already exists.")
    else:
        print("Creating Guest account (ID 9999)...")
        try:
            cursor.execute(
                """
                INSERT INTO users (
                    id, username, email, password, created_at, 
                    unlocked_themes, selected_theme, banked_points, lifetime_points,
                    unlocked_tap_sounds, selected_tap_sound, 
                    unlocked_bg_music, selected_bg_music,
                    tap_sound_enabled, bg_music_enabled
                ) VALUES (
                    9999, 'Guest', 'guest@example.com', 'kazuya143', '2026-05-03',
                    '#A9A9A9', '#A9A9A9', 1000, 0,
                    'audio/tap_sounds/default_tapSounds.mp3', 'audio/tap_sounds/default_tapSounds.mp3',
                    'audio/background_music/stal_default.mp3', 'audio/background_music/stal_default.mp3',
                    1, 1
                )
                """
            )
            conn.commit()
            print("Guest account created successfully.")
        except Exception as e:
            print(f"Error creating guest account: {e}")
            
    conn.close()

if __name__ == '__main__':
    setup_guest_account()
