import sqlite3

def clean_danger_marlow():
    # The valid themes as defined in lib/presentation/personal_feature/theme.dart
    valid_themes = {
        "#A9A9A9", "#98EE99", "#2E1A47", "#1A3A5F", "#FFA500", "#FFC0CB", "#00FF00", "#00FFFF", 
        "#FFD700", "#87CEEB", "#228B22", "#301934", "#FF4500", "#DC143C", "#BF00FF", "#800000", 
        "#191970", "#FF7F50", "#40E0D0", "#000080", "#50C878", "#FF69B4", "#39FF14", "#E0E0E0", 
        "#A020F0", "#F8F8FF", 
        "asset:assets/background/minecraft_bgColor.jpg",
        "asset:assets/background/harvest_moon_background.jpeg",
        "asset:assets/background/genshin_background.jpeg",
        "asset:assets/background/snowfall_background.jpeg"
    }

    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    
    cursor.execute("SELECT unlocked_themes FROM users WHERE username = 'DangerMarlow'")
    row = cursor.fetchone()
    if not row:
        print("User DangerMarlow not found.")
        conn.close()
        return

    current_themes = [t.strip() for t in row[0].split(",") if t.strip()]
    cleaned_themes = [t for t in current_themes if t in valid_themes]
    
    new_themes_str = ",".join(cleaned_themes)
    cursor.execute("UPDATE users SET unlocked_themes = ? WHERE username = 'DangerMarlow'", (new_themes_str,))
    
    # Also check selected_theme
    cursor.execute("SELECT selected_theme FROM users WHERE username = 'DangerMarlow'")
    selected = cursor.fetchone()[0]
    if selected and selected.strip() not in valid_themes:
        cursor.execute("UPDATE users SET selected_theme = '#A9A9A9' WHERE username = 'DangerMarlow'")
        print(f"Reset selected theme from {selected} to default.")

    conn.commit()
    print(f"Cleaned themes for DangerMarlow.")
    print(f"Original count: {len(current_themes)}")
    print(f"New count: {len(cleaned_themes)}")
    print(f"Removed: {set(current_themes) - set(cleaned_themes)}")
    
    conn.close()

if __name__ == '__main__':
    clean_danger_marlow()
