import React, { createContext, useContext, useState, useEffect } from 'react';

interface SidebarContextType {
    isCollapsed: boolean;
    isMobileOpen: boolean;
    toggleCollapse: () => void;
    toggleMobileOpen: () => void;
    setIsCollapsed: (collapsed: boolean) => void;
    setIsMobileOpen: (open: boolean) => void;
    closeMobile: () => void;
}

const SidebarContext = createContext<SidebarContextType | undefined>(undefined);

const STORAGE_KEY = 'momcare_sidebar_collapsed';

export function SidebarProvider({ children }: { children: React.ReactNode }) {
    // Check saved preference or default to false (expanded)
    const [isCollapsed, setIsCollapsedState] = useState<boolean>(() => {
        try {
            const saved = localStorage.getItem(STORAGE_KEY);
            return saved !== null ? saved === 'true' : false;
        } catch {
            return false;
        }
    });

    const [isMobileOpen, setIsMobileOpen] = useState(false);

    const setIsCollapsed = (collapsed: boolean) => {
        setIsCollapsedState(collapsed);
        try {
            localStorage.setItem(STORAGE_KEY, String(collapsed));
        } catch {
            // ignore localStorage quota errors
        }
    };

    const toggleCollapse = () => {
        setIsCollapsed(!isCollapsed);
    };

    const toggleMobileOpen = () => {
        setIsMobileOpen(prev => !prev);
    };

    const closeMobile = () => {
        setIsMobileOpen(false);
    };

    // Auto-close mobile menu on desktop resize
    useEffect(() => {
        const handleResize = () => {
            if (window.innerWidth >= 1024) {
                setIsMobileOpen(false);
            }
        };
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

    return (
        <SidebarContext.Provider
            value={{
                isCollapsed,
                isMobileOpen,
                toggleCollapse,
                toggleMobileOpen,
                setIsCollapsed,
                setIsMobileOpen,
                closeMobile,
            }}
        >
            {children}
        </SidebarContext.Provider>
    );
}

export function useSidebar() {
    const context = useContext(SidebarContext);
    if (!context) {
        throw new Error('useSidebar must be used within a SidebarProvider');
    }
    return context;
}
