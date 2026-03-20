import sqlite3
from datetime import date

conn = sqlite3.connect('users.db')
cursor = conn.cursor()

# Check current database state
cursor.execute('SELECT id, username, unlocked_themes, streak, last_challenge_date FROM users')
users = cursor.fetchall()

print('Current users:')
for user in users:
    print(f'ID: {user[0]}, Username: {user[1]}, Themes: {user[2]}, Streak: {user[3]}, Last Date: {user[4]}')

# Fix existing users with problematic unlocked_themes
cursor.execute('UPDATE users SET unlocked_themes = "" WHERE unlocked_themes = "#FFFFFF"')
conn.commit()

print('\nAfter fixing:')
cursor.execute('SELECT id, username, unlocked_themes, streak, last_challenge_date FROM users')
users = cursor.fetchall()
for user in users:
    print(f'ID: {user[0]}, Username: {user[1]}, Themes: {user[2]}, Streak: {user[3]}, Last Date: {user[4]}')

conn.close()
print('Database fixed!')
