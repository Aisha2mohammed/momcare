import { useState, useCallback, useEffect } from 'react';
import { mockDoctors } from '../mockData';
import type { ApprovalStatus, Doctor } from '../types';

let doctorsStore: Doctor[] = [...mockDoctors];

export function useDoctors(filterStatus?: ApprovalStatus) {
    const [doctors, setDoctors] = useState<Doctor[]>(
        filterStatus ? doctorsStore.filter(d => d.approvalStatus === filterStatus) : doctorsStore
    );
    const [isLoading] = useState(false);
    const [error] = useState<string | null>(null);

    const refresh = useCallback((status?: ApprovalStatus) => {
        setDoctors(status ? doctorsStore.filter(d => d.approvalStatus === status) : [...doctorsStore]);
    }, []);

    useEffect(() => {
        refresh(filterStatus);
    }, [filterStatus, refresh]);

    const approveDoctor = useCallback(async (id: string) => {
        await new Promise(r => setTimeout(r, 600));
        doctorsStore = doctorsStore.map(d =>
            d.id === id ? { ...d, approvalStatus: 'Approved' as ApprovalStatus, status: 'Active' } : d
        );
        // Stub: email notification would fire here
        console.log(`[EMAIL STUB] Approval email sent to doctor ${id}`);
        refresh(filterStatus);
    }, [filterStatus, refresh]);

    const rejectDoctor = useCallback(async (id: string, reason: string) => {
        await new Promise(r => setTimeout(r, 600));
        doctorsStore = doctorsStore.map(d =>
            d.id === id ? { ...d, approvalStatus: 'Rejected' as ApprovalStatus, rejectionReason: reason } : d
        );
        console.log(`[EMAIL STUB] Rejection email sent to doctor ${id}. Reason: ${reason}`);
        refresh(filterStatus);
    }, [filterStatus, refresh]);

    const getDoctorById = useCallback((id: string) => {
        return doctorsStore.find(d => d.id === id) ?? null;
    }, []);

    return { doctors, isLoading, error, approveDoctor, rejectDoctor, getDoctorById, refresh };
}
