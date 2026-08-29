import { useState, useCallback } from 'react';
import { mockMothers } from '../mockData';
import { mockDoctors } from '../mockData';
import type { Mother, Doctor, Status } from '../types';

let mothersStore: Mother[] = [...mockMothers];
let doctorsApprovedStore: Doctor[] = mockDoctors.filter(d => d.approvalStatus === 'Approved');

export function useMothers() {
    const [mothers, setMothers] = useState<Mother[]>([...mothersStore]);
    const [isLoading] = useState(false);
    const [error] = useState<string | null>(null);

    const refresh = useCallback(() => setMothers([...mothersStore]), []);

    const updateMotherStatus = useCallback(async (id: string, status: Status, _reason?: string) => {
        await new Promise(r => setTimeout(r, 500));
        mothersStore = mothersStore.map(m => m.id === id ? { ...m, status } : m);
        console.log(`[AUDIT STUB] Mother ${id} status changed to ${status}. Reason: ${_reason ?? 'N/A'}`);
        refresh();
    }, [refresh]);

    return { mothers, isLoading, error, updateMotherStatus, refresh };
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
