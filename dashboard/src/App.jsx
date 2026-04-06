import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000';

// Auth component
function AuthComponent({ onAuth }) {
    const [adminKey, setAdminKey] = useState('');
    const [error, setError] = useState('');

    const handleSubmit = (e) => {
        e.preventDefault();
        if (adminKey.trim()) {
            onAuth(adminKey);
            setAdminKey('');
        } else {
            setError('Admin key is required');
        }
    };

    return (
        <div className="auth-section">
            <h2>Tap & Match Admin Dashboard</h2>
            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label htmlFor="adminKey">Admin Key:</label>
                    <input
                        id="adminKey"
                        type="password"
                        value={adminKey}
                        onChange={(e) => {
                            setAdminKey(e.target.value);
                            setError('');
                        }}
                        placeholder="Enter admin key"
                    />
                </div>
                {error && <div className="alert alert-error">{error}</div>}
                <button type="submit" className="btn-primary" style={{ width: '100%' }}>
                    Login
                </button>
            </form>
        </div>
    );
}

// Stats component
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

// Reports component
function ReportsTab({ adminKey }) {
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (adminKey) {
            fetchReports();
        }
    }, [adminKey]);

    const fetchReports = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/reports`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setReports(response.data);
        } catch (err) {
            setError('Failed to fetch reports');
        } finally {
            setLoading(false);
        }
    };

    const updateStatus = async (reportId, status) => {
        try {
            await axios.put(`${API_BASE_URL}/admin/reports/${reportId}?status=${status}`, {}, {
                headers: { 'X-Admin-Key': adminKey }
            });
            fetchReports();
        } catch (err) {
            setError('Failed to update report status');
        }
    };

    return (
        <div className="tab-content active">
            {error && <div className="alert alert-error">{error}</div>}
            {loading && <div className="loading">Loading reports...</div>}
            {!loading && reports.length > 0 && (
                <div className="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Reporter</th>
                                <th>Reported User</th>
                                <th>Reason</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {reports.map(report => (
                                <tr key={report.id}>
                                    <td>#{report.id}</td>
                                    <td>User {report.reporter_id}</td>
                                    <td>User {report.reported_id}</td>
                                    <td className="reason-text">{report.reason}</td>
                                    <td>{report.timestamp}</td>
                                    <td>
                                        <span className={`status-badge status-${report.status.toLowerCase()}`}>
                                            {report.status}
                                        </span>
                                    </td>
                                    <td>
                                        <div className="action-cell">
                                            {report.status !== 'approved' && (
                                                <button
                                                    className="btn-primary"
                                                    onClick={() => updateStatus(report.id, 'approved')}
                                                >
                                                    Approve
                                                </button>
                                            )}
                                            {report.status !== 'rejected' && (
                                                <button
                                                    className="btn-secondary"
                                                    onClick={() => updateStatus(report.id, 'rejected')}
                                                >
                                                    Reject
                                                </button>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
            {!loading && reports.length === 0 && <div className="loading">No reports found.</div>}
        </div>
    );
}

// Appeals component
function AppealsTab({ adminKey }) {
    const [appeals, setAppeals] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (adminKey) {
            fetchAppeals();
        }
    }, [adminKey]);

    const fetchAppeals = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/appeals`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setAppeals(response.data);
        } catch (err) {
            setError('Failed to fetch appeals');
        } finally {
            setLoading(false);
        }
    };

    const updateStatus = async (appealId, status) => {
        try {
            await axios.put(`${API_BASE_URL}/admin/appeals/${appealId}?status=${status}`, {}, {
                headers: { 'X-Admin-Key': adminKey }
            });
            fetchAppeals();
        } catch (err) {
            setError('Failed to update appeal status');
        }
    };

    return (
        <div className="tab-content">
            {error && <div className="alert alert-error">{error}</div>}
            {loading && <div className="loading">Loading appeals...</div>}
            {!loading && appeals.length > 0 && (
                <div className="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>User</th>
                                <th>Appeal Text</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {appeals.map(appeal => (
                                <tr key={appeal.id}>
                                    <td>#{appeal.id}</td>
                                    <td>User {appeal.user_id}</td>
                                    <td className="reason-text">{appeal.appeal_text}</td>
                                    <td>{appeal.timestamp}</td>
                                    <td>
                                        <span className={`status-badge status-${appeal.status.toLowerCase()}`}>
                                            {appeal.status}
                                        </span>
                                    </td>
                                    <td>
                                        <div className="action-cell">
                                            {appeal.status !== 'Approved' && (
                                                <button
                                                    className="btn-primary"
                                                    onClick={() => updateStatus(appeal.id, 'Approved')}
                                                >
                                                    Approve
                                                </button>
                                            )}
                                            {appeal.status !== 'Rejected' && (
                                                <button
                                                    className="btn-secondary"
                                                    onClick={() => updateStatus(appeal.id, 'Rejected')}
                                                >
                                                    Reject
                                                </button>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
            {!loading && appeals.length === 0 && <div className="loading">No appeals found.</div>}
        </div>
    );
}

// Support Tickets component
function SupportTicketsTab({ adminKey }) {
    const [tickets, setTickets] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (adminKey) {
            fetchTickets();
        }
    }, [adminKey]);

    const fetchTickets = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/support/tickets`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setTickets(response.data);
        } catch (err) {
            setError('Failed to fetch support tickets');
        } finally {
            setLoading(false);
        }
    };

    const updateStatus = async (ticketId, status) => {
        try {
            await axios.put(`${API_BASE_URL}/admin/support/tickets/${ticketId}?status=${status}`, {}, {
                headers: { 'X-Admin-Key': adminKey }
            });
            fetchTickets();
        } catch (err) {
            setError('Failed to update ticket status');
        }
    };

    return (
        <div className="tab-content">
            {error && <div className="alert alert-error">{error}</div>}
            {loading && <div className="loading">Loading support tickets...</div>}
            {!loading && tickets.length > 0 && (
                <div className="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>User</th>
                                <th>Type</th>
                                <th>Message</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {tickets.map(ticket => (
                                <tr key={ticket.id}>
                                    <td>#{ticket.id}</td>
                                    <td>User {ticket.user_id}</td>
                                    <td>{ticket.type}</td>
                                    <td className="reason-text">{ticket.message}</td>
                                    <td>{ticket.timestamp}</td>
                                    <td>
                                        <span className={`status-badge status-${ticket.status.toLowerCase()}`}>
                                            {ticket.status}
                                        </span>
                                    </td>
                                    <td>
                                        <div className="action-cell">
                                            {ticket.status !== 'Closed' && (
                                                <button
                                                    className="btn-primary"
                                                    onClick={() => updateStatus(ticket.id, 'Closed')}
                                                >
                                                    Close
                                                </button>
                                            )}
                                            {ticket.status !== 'Open' && (
                                                <button
                                                    className="btn-primary"
                                                    onClick={() => updateStatus(ticket.id, 'Open')}
                                                >
                                                    Reopen
                                                </button>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
            {!loading && tickets.length === 0 && <div className="loading">No support tickets found.</div>}
        </div>
    );
}

// Users management component
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

// Main Dashboard component
function Dashboard({ adminKey, onLogout }) {
    const [stats, setStats] = useState(null);
    const [activeTab, setActiveTab] = useState('users');
    const [error, setError] = useState('');

    useEffect(() => {
        fetchStats();
        const interval = setInterval(fetchStats, 30000); // Refresh every 30 seconds
        return () => clearInterval(interval);
    }, [adminKey]);

    const fetchStats = async () => {
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/stats`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setStats(response.data);
        } catch (err) {
            setError('Failed to fetch stats. Admin key may be invalid.');
            onLogout();
        }
    };

    return (
        <div>
            <header>
                <h1>Tap & Match Admin Dashboard</h1>
                <p>Moderation, Support & User Management Hub</p>
                <button
                    onClick={onLogout}
                    style={{
                        position: 'absolute',
                        top: 30,
                        right: 30,
                        background: 'rgba(255,255,255,0.2)',
                        color: 'white',
                        border: '1px solid white',
                        padding: '8px 16px',
                        borderRadius: '6px',
                        cursor: 'pointer'
                    }}
                >
                    Logout
                </button>
            </header>

            {error && <div className="alert alert-error">{error}</div>}

            <StatsBar stats={stats} />

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
                <button
                    className={`tab-button ${activeTab === 'appeals' ? 'active' : ''}`}
                    onClick={() => setActiveTab('appeals')}
                >
                    Appeals
                </button>
                <button
                    className={`tab-button ${activeTab === 'tickets' ? 'active' : ''}`}
                    onClick={() => setActiveTab('tickets')}
                >
                    Support Tickets
                </button>
            </div>

            {activeTab === 'users' && <UsersTab adminKey={adminKey} />}
            {activeTab === 'reports' && <ReportsTab adminKey={adminKey} />}
            {activeTab === 'appeals' && <AppealsTab adminKey={adminKey} />}
            {activeTab === 'tickets' && <SupportTicketsTab adminKey={adminKey} />}
        </div>
    );
}

// Main App component
export default function App() {
    const [adminKey, setAdminKey] = useState(localStorage.getItem('adminKey') || null);

    const handleAuth = (key) => {
        localStorage.setItem('adminKey', key);
        setAdminKey(key);
    };

    const handleLogout = () => {
        localStorage.removeItem('adminKey');
        setAdminKey(null);
    };

    return (
        <div className="container">
            {adminKey ? (
                <Dashboard adminKey={adminKey} onLogout={handleLogout} />
            ) : (
                <AuthComponent onAuth={handleAuth} />
            )}
        </div>
    );
}
