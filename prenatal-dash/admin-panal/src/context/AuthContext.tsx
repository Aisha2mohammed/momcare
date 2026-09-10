import { createContext, useContext, useState, type ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { authApi } from '../services/api';

export interface AdminUser {
    id: string;
    name: string;
    email: string;
    role: 'admin';
    avatar?: string;
}

interface AuthContextType {
    user: AdminUser | null;
    token: string | null;
    isLoading: boolean;
    login: (email: string, password: string, twofa?: string) => Promise<{ success: boolean; error?: string }>;
    logout: () => void;
    isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

// Mock admin credentials
const MOCK_ADMIN = {
    email: 'admin@momcare.et',
    password: 'Admin123!',
    user: {
        id: 'ADM001',
        name: 'Yohannes Tesfaye',
        email: 'admin@momcare.et',
        role: 'admin' as const,
    },
};

const SESSION_KEY = 'momcare_admin_session';

function getInitialSession(): { user: AdminUser | null; token: string | null } {
    try {
        const stored = sessionStorage.getItem(SESSION_KEY);
        if (stored) {
            const { user, token } = JSON.parse(stored);
            if (user && token) return { user, token };
        }
    } catch {
        sessionStorage.removeItem(SESSION_KEY);
    }
    return { user: null, token: null };
}

export function AuthProvider({ children }: { children: ReactNode }) {
    const [session, setSession] = useState<{ user: AdminUser | null; token: string | null }>(getInitialSession);
    const [isLoading, setIsLoading] = useState(false);

    const user = session.user;
    const token = session.token;

    const login = async (email: string, password: string): Promise<{ success: boolean; error?: string }> => {
        setIsLoading(true);
        try {
            // First attempt live backend login
            const result = await authApi.adminLogin(email, password);
            if (result && result.token) {
                const adminUser: AdminUser = {
                    id: result.admin?.id || 'admin',
                    name: result.admin?.name || 'Administrator',
                    email: result.admin?.email || email,
                    role: 'admin',
                };
                const newSession = { user: adminUser, token: result.token };
                setSession(newSession);
                sessionStorage.setItem(SESSION_KEY, JSON.stringify(newSession));
                return { success: true };
            }
        } catch (apiErr: any) {
            console.warn('[AuthContext] Backend login attempt message:', apiErr.message);

            // Fallback to local mock admin if credentials match
            if (email === MOCK_ADMIN.email && (password === MOCK_ADMIN.password || password === 'Admin123!')) {
                const mockToken = `mock-jwt-${Date.now()}`;
                const newSession = { user: MOCK_ADMIN.user, token: mockToken };
                setSession(newSession);
                sessionStorage.setItem(SESSION_KEY, JSON.stringify(newSession));
                return { success: true };
            }

            return { success: false, error: apiErr.message || 'Invalid email or password.' };
        } finally {
            setIsLoading(false);
        }

        if (email === MOCK_ADMIN.email && password === MOCK_ADMIN.password) {
            const mockToken = `mock-jwt-${Date.now()}`;
            const newSession = { user: MOCK_ADMIN.user, token: mockToken };
            setSession(newSession);
            sessionStorage.setItem(SESSION_KEY, JSON.stringify(newSession));
            return { success: true };
        }

        return { success: false, error: 'Invalid email or password.' };
    };

    const logout = () => {
        setSession({ user: null, token: null });
        sessionStorage.removeItem(SESSION_KEY);
    };

    return (
        <AuthContext.Provider value={{ user, token, isLoading, login, logout, isAuthenticated: !!user }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be used within AuthProvider');
    return ctx;
}

// Role-guarded route wrapper
export function ProtectedRoute({ children }: { children: ReactNode }) {
    const { isAuthenticated, isLoading } = useAuth();

    if (isLoading) {
        return (
            <div className="flex h-screen items-center justify-center bg-gray-50">
                <div className="animate-spin rounded-full h-10 w-10 border-2 border-[#61183e] border-t-transparent" />
            </div>
        );
    }

    if (!isAuthenticated) {
        return <Navigate to="/login" replace />;
    }

    return <>{children}</>;
}
