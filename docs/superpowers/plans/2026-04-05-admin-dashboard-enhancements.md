# Admin Dashboard Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the Admin Dashboard with a User Management tab, allowing admins to search for players, view their progress, and perform administrative actions like banning/unbanning and resetting progress.

**Architecture:** 
- **Backend:** Add administrative endpoints to `backend/main.py` for user listing, searching, and management actions (resetting progress). 
- **Frontend:** Implement a new `UsersTab` component in the React-based dashboard to interact with these endpoints.

**Tech Stack:** FastAPI (Python), React (JavaScript), SQLite.

---

### Task 1: Backend Administrative Endpoints

**Files:**
- Modify: `backend/main.py`

- [ ] **Step 1: Add `/admin/users` endpoint**
Add an endpoint to list users with optional search by username or email.

```python
@app.get("/admin/users", dependencies=[Depends(verify_admin)])
async def get_admin_users(search: str = ""):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    query = "SELECT id, username, email, total_score, highest_level, is_banned, ban_reason FROM users"
    params = []
    
    if search:
        query += " WHERE username LIKE ? OR email LIKE ?"
        params = [f"%{search}%", f"%{search}%"]
    
    query += " ORDER BY id DESC"
    
    users = cursor.execute(query, params).fetchall()
    conn.close()
    
    return [dict(u) for u in users]
```

- [ ] **Step 2: Add `/admin/users/{user_id}/reset` endpoint**
Add an endpoint to reset a user's progress.

```python
@app.post("/admin/users/{user_id}/reset", dependencies=[Depends(verify_admin)])
async def admin_reset_user(user_id: int):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    
    # Check if user exists
    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")
        
    cursor.execute("""
        UPDATE users 
        SET total_score = 0, highest_score = 0, highest_level = 0, levels_cleared = 0,
            fast_finishes = 0, perfect_finishes = 0, boxes_tapped = 0, completed_daily_challenges = 0,
            extreme_clears = 0, unlocked_themes = '', selected_theme = '#A9A9A9',
            streak = 0, last_challenge_date = NULL, daily_attempts = 0, last_attempt_date = NULL
        WHERE id = ?
    """, (user_id,))
    
    conn.commit()
    conn.close()
    return {"message": f"User {user_id} progress reset successfully."}
```

- [ ] **Step 3: Commit backend changes**

```bash
git add backend/main.py
git commit -m "feat(admin): add user management endpoints"
```

### Task 2: Frontend User Management Tab

**Files:**
- Modify: `dashboard/src/App.jsx`

- [ ] **Step 1: Implement `UsersTab` component**
Add the `UsersTab` component to the `App.jsx` file.

```javascript
function UsersTab({ adminKey }) {
    const [users, setUsers] = useState([]);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (adminKey) {
            fetchUsers();
        }
    }, [adminKey]);

    const fetchUsers = async (searchTerm = '') => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/users?search=${searchTerm}`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setUsers(response.data);
        } catch (err) {
            setError('Failed to fetch users');
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = (e) => {
        e.preventDefault();
        fetchUsers(search);
    };

    const toggleBan = async (user) => {
        try {
            if (user.is_banned) {
                await axios.put(`${API_BASE_URL}/admin/users/${user.id}/unban`, {}, {
                    headers: { 'X-Admin-Key': adminKey }
                });
            } else {
                const reason = prompt('Enter ban reason:', 'Rules violation');
                if (reason === null) return;
                await axios.put(`${API_BASE_URL}/admin/users/${user.id}/ban`, { reason }, {
                    headers: { 'X-Admin-Key': adminKey }
                });
            }
            fetchUsers(search);
        } catch (err) {
            setError('Failed to update ban status');
        }
    };

    const resetProgress = async (userId) => {
        if (!window.confirm('Are you sure you want to reset this user\'s progress? This cannot be undone.')) {
            return;
        }
        try {
            await axios.post(`${API_BASE_URL}/admin/users/${userId}/reset`, {}, {
                headers: { 'X-Admin-Key': adminKey }
            });
            alert('User progress reset successfully');
            fetchUsers(search);
        } catch (err) {
            setError('Failed to reset user progress');
        }
    };

    return (
        <div className="tab-content active">
            <div style={{ marginBottom: '20px', display: 'flex', gap: '10px' }}>
                <form onSubmit={handleSearch} style={{ display: 'flex', gap: '10px', width: '100%' }}>
                    <input
                        type="text"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        placeholder="Search by username or email..."
                        style={{ flexGrow: 1 }}
                    />
                    <button type="submit" className="btn-primary">Search</button>
                    <button type="button" className="btn-secondary" onClick={() => { setSearch(''); fetchUsers(''); }}>Clear</button>
                </form>
            </div>

            {error && <div className="alert alert-error">{error}</div>}
            {loading && <div className="loading">Loading users...</div>}
            
            {!loading && (
                <div className="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Username</th>
                                <th>Email</th>
                                <th>Score</th>
                                <th>Level</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {users.map(user => (
                                <tr key={user.id}>
                                    <td>#{user.id}</td>
                                    <td>{user.username}</td>
                                    <td>{user.email}</td>
                                    <td>{user.total_score}</td>
                                    <td>{user.highest_level}</td>
                                    <td>
                                        <span className={`status-badge status-${user.is_banned ? 'rejected' : 'approved'}`}>
                                            {user.is_banned ? 'Banned' : 'Active'}
                                        </span>
                                    </td>
                                    <td>
                                        <div className="action-cell">
                                            <button
                                                className={user.is_banned ? 'btn-primary' : 'btn-secondary'}
                                                onClick={() => toggleBan(user)}
                                            >
                                                {user.is_banned ? 'Unban' : 'Ban'}
                                            </button>
                                            <button
                                                className="btn-secondary"
                                                style={{ backgroundColor: '#ff4444', color: 'white' }}
                                                onClick={() => resetProgress(user.id)}
                                            >
                                                Reset
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}
```

- [ ] **Step 2: Update `Dashboard` component to include `UsersTab`**
Update the `activeTab` state and the tab buttons to include 'users'.

```javascript
function Dashboard({ adminKey, onLogout }) {
    const [stats, setStats] = useState(null);
    const [activeTab, setActiveTab] = useState('users'); // Set default to users
    const [error, setError] = useState('');
    
    // ... useEffect and fetchStats ...

    return (
        <div>
            {/* ... header ... */}
            <StatsBar stats={stats} adminKey={adminKey} />

            <div className="tabs">
                <button
                    className={`tab-button ${activeTab === 'users' ? 'active' : ''}`}
                    onClick={() => setActiveTab('users')}
                >
                    Users
                </button>
                <button
                    className={`tab-button ${activeTab === 'reports' ? 'active' : ''}`}
                    onClick={() => setActiveTab('reports')}
                >
                    Reports
                </button>
                {/* ... other buttons ... */}
            </div>

            {activeTab === 'users' && <UsersTab adminKey={adminKey} />}
            {activeTab === 'reports' && <ReportsTab adminKey={adminKey} />}
            {/* ... other tabs ... */}
        </div>
    );
}
```

- [ ] **Step 3: Commit frontend changes**

```bash
git add dashboard/src/App.jsx
git commit -m "feat(admin): add users management tab to dashboard"
```

### Task 3: Final Touches and Security Fixes

- [ ] **Step 1: Fix `StatsBar` update logic**
Ensure `StatsBar` actually updates the parent's state or handles it locally. In `Dashboard`, we are already fetching stats, so `StatsBar` should just display them.

```javascript
function StatsBar({ stats }) {
    return (
        <div className="stats">
            <div className="stat-card">
                <h3>Total Users</h3>
                <div className="number">{stats?.total_users || 0}</div>
            </div>
            <div className="stat-card">
                <h3>Banned Users</h3>
                <div className="number">{stats?.banned_users || 0}</div>
            </div>
            <div className="stat-card">
                <h3>Pending Reports</h3>
                <div className="number">{stats?.pending_reports || 0}</div>
            </div>
        </div>
    );
}
```

- [ ] **Step 2: Commit final fixes**

```bash
git add dashboard/src/App.jsx
git commit -m "fix(admin): cleanup dashboard stats display"
```
