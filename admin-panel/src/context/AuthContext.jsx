import { createContext, useState, useContext, useEffect, useCallback } from 'react';
import api from '../utils/api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        try {
            const storedUser = localStorage.getItem('admin_user');
            const token = localStorage.getItem('admin_token');

            if (storedUser && token) {
                setUser(JSON.parse(storedUser));
            }
        } catch {
            localStorage.removeItem('admin_user');
            localStorage.removeItem('admin_token');
        }
        setLoading(false);
    }, []);

    const login = useCallback(async (email, password) => {
        try {
            const response = await api.post('/admin/login', { email, password });
            const { user: userData, accessToken } = response.data;

            localStorage.setItem('admin_token', accessToken);
            localStorage.setItem('admin_user', JSON.stringify(userData));
            setUser(userData);
            return { success: true };
        } catch (error) {
            return {
                success: false,
                message: error.response?.data?.message || 'Login failed. Please check your credentials.',
            };
        }
    }, []);

    const logout = useCallback(() => {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
        setUser(null);
        window.location.href = '/login';
    }, []);

    return (
        <AuthContext.Provider value={{ user, login, logout, loading }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
