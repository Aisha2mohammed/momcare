import { createContext, useContext, useState, useEffect, type ReactNode } from 'react';
import { Navigate } from 'react-router-dom';

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

export function AuthProvider({ children }: { children: ReactNode }) {
    const [user, setUser] = useState<AdminUser | null>(null);
    const [token, setToken] = useState<string | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    // Restore session on mount
    useEffect(() => {
        const stored = sessionStorage.getItem(SESSION_KEY);
        if (stored) {
            try {
                const { user: u, token: t } = JSON.parse(stored);
                setUser(u);
                setToken(t);
            } catch {
                sessionStorage.removeItem(SESSION_KEY);
            }
        }
        setIsLoading(false);
    }, []);

    const login = async (email: string, password: string, _twofa?: string): Promise<{ success: boolean; error?: string }> => {
        // Simulate network delay
        await new Promise(r => setTimeout(r, 800));

        if (email === MOCK_ADMIN.email && password === MOCK_ADMIN.password) {
            const mockToken = `mock-jwt-${Date.now()}`;
            setUser(MOCK_ADMIN.user);
            setToken(mockToken);
            sessionStorage.setItem(SESSION_KEY, JSON.stringify({ user: MOCK_ADMIN.user, token: mockToken }));
            return { success: true };
        }
        return { success: false, error: 'Invalid email or password.' };
    };

    const logout = () => {
        setUser(null);
        setToken(null);
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
