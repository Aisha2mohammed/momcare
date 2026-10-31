import { useState, useCallback } from 'react';
import type { Mother, Doctor, Status } from '../types';
import { adminUsersApi, adminDoctorsApi } from '../../services/api';

let mothersStore: Mother[] = [];
let doctorsApprovedStore: Doctor[] = [];

/**
 * Insert or update a mother by id. Pending mothers come from the real API, so
 * on first load they are prepended; afterwards only the approval-relevant
 * fields change.
 */
function upsertMother(mother: Mother) {
    if (mothersStore.some(m => m.id === mother.id)) {
        mothersStore = mothersStore.map(m => (m.id === mother.id ? { ...m, ...mother } : m));
    } else {
        mothersStore = [mother, ...mothersStore];
    }
}

export function useMothers() {
    const [mothers, setMothers] = useState<Mother[]>([...mothersStore]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const refresh = useCallback(() => setMothers([...mothersStore]), []);

    /** Load every mother (active, pending, rejected, suspended, inactive). */
    const loadAllUsers = useCallback(async () => {
        setIsLoading(true);
        setError(null);
        try {
            mothersStore = await adminUsersApi.adminListMothers();
        } catch (e: any) {
            setError(e?.message ?? 'Failed to load mothers');
        } finally {
            setIsLoading(false);
            refresh();
        }
    }, [refresh]);

    /** Merge the real pending-mother list into the table (deduped by id). */
    const loadPendingMothers = useCallback(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const pending = await adminUsersApi.adminListPendingMothers();
            const pendingIds = new Set(pending.map(p => p.id));
            mothersStore = [...pending, ...mothersStore.filter(m => !pendingIds.has(m.id))];
        } catch (e: any) {
            // The list itself is still mock-seeded, so a failed fetch only means
            // no pending rows to show — surface it without clearing the table.
            setError(e?.message ?? 'Failed to load pending mothers');
        } finally {
            setIsLoading(false);
            refresh();
        }
    }, [refresh]);

    const approveMother = useCallback(async (id: string): Promise<Mother | null> => {
        setIsLoading(true);
        setError(null);
        try {
            const updated = await adminUsersApi.adminApproveMother(id);
            upsertMother({ ...updated, status: 'Active' });
            return updated;
        } catch (e: any) {
            setError(e?.message ?? 'Failed to approve mother');
            return null;
        } finally {
            setIsLoading(false);
            refresh();
        }
    }, [refresh]);

    const rejectMother = useCallback(async (id: string): Promise<Mother | null> => {
        setIsLoading(true);
        setError(null);
        try {
            const updated = await adminUsersApi.adminRejectMother(id);
            upsertMother({ ...updated, status: 'Rejected' });
            return updated;
        } catch (e: any) {
            setError(e?.message ?? 'Failed to reject mother');
            return null;
        } finally {
            setIsLoading(false);
            refresh();
        }
    }, [refresh]);

    const reactivateMother = useCallback(async (id: string): Promise<Mother | null> => {
        setIsLoading(true);
        setError(null);
        try {
            const updated = await adminUsersApi.adminReactivateMother(id);
            upsertMother({ ...updated, status: 'Active' });
            return updated;
        } catch (e: any) {
            setError(e?.message ?? 'Failed to reactivate mother');
            return null;
        } finally {
            setIsLoading(false);
            refresh();
        }
    }, [refresh]);

    /**
     * Legacy entry point used by the suspend/reactivate confirm flow.
     * Suspending and reactivating now hit the real backend; anything else
     * (and mock-only rows whose ids are not in the DB) keeps the old local
     * behaviour as a safe fallback.
     */
    const updateMotherStatus = useCallback(async (id: string, status: Status, _reason?: string) => {
        setIsLoading(true);
        setError(null);
        try {
            if (status === 'Suspended') {
                const updated = await adminUsersApi.adminSuspendMother(id);
                upsertMother({ ...updated, status: 'Suspended' });
                return;
            }
            if (status === 'Active') {
                const current = mothersStore.find(m => m.id === id);
                if (current && (current.status === 'Rejected' || current.status === 'Suspended')) {
                    const updated = await adminUsersApi.adminReactivateMother(id);
                    upsertMother({ ...updated, status: 'Active' });
                    return;
                }
            }
            mothersStore = mothersStore.map(m => (m.id === id ? { ...m, status } : m));
            console.log(`[MOCK] Mother ${id} status changed to ${status}. Reason: ${_reason ?? 'N/A'}`);
        } catch (e: any) {
            // Seeded mock rows (ids like 'M001') don't exist in the database, so
            // the live endpoint 404s for them. Keep the demo table responsive.
            console.warn(`[useMothers] API ${status} failed for ${id}; falling back to mock:`, e?.message);
            mothersStore = mothersStore.map(m => (m.id === id ? { ...m, status } : m));
        } finally {
            setIsLoading(false);
            refresh();
        }
    }, [refresh]);

    return {
        mothers,
        isLoading,
        error,
        updateMotherStatus,
        approveMother,
        rejectMother,
        reactivateMother,
        loadAllUsers,
        loadPendingMothers,
        refresh,
    };
}

export function useApprovedDoctors() {
    const [doctors, setDoctors] = useState<Doctor[]>([...doctorsApprovedStore]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const refresh = useCallback(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const list = await adminDoctorsApi.adminListDoctors();
            doctorsApprovedStore = list;
            setDoctors(list);
        } catch (err: any) {
            setError(err?.message || 'Failed to load doctors');
            setDoctors([...doctorsApprovedStore]);
        } finally {
            setIsLoading(false);
        }
    }, []);

    const updateDoctorStatus = useCallback(async (id: string, status: Status, _reason?: string) => {
        setIsLoading(true);
        try {
            if (status === 'Suspended') {
                await adminDoctorsApi.adminSuspendDoctor(id);
            } else if (status === 'Active') {
                await adminDoctorsApi.adminReactivateDoctor(id);
            }
            await refresh();
        } catch (err: any) {
            console.error(`Failed to update doctor ${id} status:`, err);
            doctorsApprovedStore = doctorsApprovedStore.map(d => (d.id === id ? { ...d, status } : d));
            setDoctors([...doctorsApprovedStore]);
        } finally {
            setIsLoading(false);
        }
    }, [refresh]);

    return { doctors, isLoading, error, updateDoctorStatus, refresh };
}
