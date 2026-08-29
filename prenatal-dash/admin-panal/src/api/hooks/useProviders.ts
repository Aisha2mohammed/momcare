import { useState, useCallback } from 'react';
import { mockProviders } from '../mockData';
import type { HealthProvider, Status } from '../types';

let providersStore: HealthProvider[] = [...mockProviders];

export function useProviders() {
    const [providers, setProviders] = useState<HealthProvider[]>([...providersStore]);
    const [isLoading] = useState(false);
    const [error] = useState<string | null>(null);

    const refresh = useCallback(() => setProviders([...providersStore]), []);

    const toggleStatus = useCallback(async (id: string) => {
        await new Promise(r => setTimeout(r, 400));
        providersStore = providersStore.map(p =>
            p.id === id ? { ...p, status: p.status === 'Active' ? 'Inactive' as Status : 'Active' as Status } : p
        );
        refresh();
    }, [refresh]);

    const addProvider = useCallback(async (provider: Omit<HealthProvider, 'id' | 'linkedDoctorCount' | 'linkedDoctors' | 'createdAt'>) => {
        await new Promise(r => setTimeout(r, 600));
        const newProvider: HealthProvider = {
            ...provider,
            id: `P${String(providersStore.length + 1).padStart(3, '0')}`,
            linkedDoctorCount: 0,
            linkedDoctors: [],
            createdAt: new Date().toISOString().split('T')[0],
        };
        providersStore = [...providersStore, newProvider];
        refresh();
    }, [refresh]);

    const updateProvider = useCallback(async (id: string, updates: Partial<HealthProvider>) => {
        await new Promise(r => setTimeout(r, 600));
        providersStore = providersStore.map(p => p.id === id ? { ...p, ...updates } : p);
        refresh();
    }, [refresh]);

    const getProviderById = useCallback((id: string) => {
        return providersStore.find(p => p.id === id) ?? null;
    }, []);

    return { providers, isLoading, error, toggleStatus, addProvider, updateProvider, getProviderById, refresh };
}
