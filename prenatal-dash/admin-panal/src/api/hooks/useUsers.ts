import { useState, useCallback, useEffect } from 'react';
import { mockMothers } from '../mockData';
import { mockDoctors } from '../mockData';
import type { Mother, Doctor, Status } from '../types';
import { adminUsersApi } from '../../services/api';

let mothersStore: Mother[] = [...mockMothers];
let doctorsApprovedStore: Doctor[] = mockDoctors.filter(d => d.approvalStatus === 'Approved');

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

    // Load real pending mothers once when the table mounts.
    useEffect(() => {
        loadPendingMothers();
    }, [loadPendingMothers]);

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
        loadPendingMothers,
        refresh,
    };
}

export function useApprovedDoctors() {
    const [doctors, setDoctors] = useState<Doctor[]>([...doctorsApprovedStore]);
    const [isLoading] = useState(false);
    const [error] = useState<string | null>(null);

    const refresh = useCallback(() => {
        doctorsApprovedStore = mockDoctors.filter(d => d.approvalStatus === 'Approved');
        setDoctors([...doctorsApprovedStore]);
    }, []);

    const updateDoctorStatus = useCallback(async (id: string, status: Status, _reason?: string) => {
        await new Promise(r => setTimeout(r, 500));
        doctorsApprovedStore = doctorsApprovedStore.map(d => d.id === id ? { ...d, status } : d);
        console.log(`[AUDIT STUB] Doctor ${id} status changed to ${status}. Reason: ${_reason ?? 'N/A'}`);
        refresh();
    }, [refresh]);

    return { doctors, isLoading, error, updateDoctorStatus, refresh };
}
