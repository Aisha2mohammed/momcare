import { useState, useCallback, useEffect } from 'react';
import type { ApprovalStatus, Doctor } from '../types';
import { adminDoctorsApi } from '../../services/api';

let doctorsStore: Doctor[] = [];

export function useDoctors(filterStatus?: ApprovalStatus | 'All') {
    const [doctors, setDoctors] = useState<Doctor[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const refresh = useCallback(async (status?: ApprovalStatus | 'All') => {
        setIsLoading(true);
        setError(null);
        try {
            const list = await adminDoctorsApi.adminListDoctors({
                approvalStatus: status && status !== 'All' ? status : undefined,
            });
            doctorsStore = list;
            setDoctors(status && status !== 'All' ? list.filter(d => d.approvalStatus === status) : list);
        } catch (err: any) {
            setError(err?.message || 'Failed to load doctors');
            // If API fails, keep existing store
            setDoctors(status && status !== 'All' ? doctorsStore.filter(d => d.approvalStatus === status) : doctorsStore);
        } finally {
            setIsLoading(false);
        }
    }, []);

    useEffect(() => {
        refresh(filterStatus);
    }, [filterStatus, refresh]);

    const approveDoctor = useCallback(async (id: string) => {
        setIsLoading(true);
        try {
            const updated = await adminDoctorsApi.adminApproveDoctor(id);
            doctorsStore = doctorsStore.map(d => (d.id === id ? updated : d));
            await refresh(filterStatus);
            return updated;
        } catch (err: any) {
            setError(err?.message || 'Failed to approve doctor');
            throw err;
        } finally {
            setIsLoading(false);
        }
    }, [filterStatus, refresh]);

    const rejectDoctor = useCallback(async (id: string, reason: string) => {
        setIsLoading(true);
        try {
            const updated = await adminDoctorsApi.adminRejectDoctor(id, reason);
            doctorsStore = doctorsStore.map(d => (d.id === id ? updated : d));
            await refresh(filterStatus);
            return updated;
        } catch (err: any) {
            setError(err?.message || 'Failed to reject doctor');
            throw err;
        } finally {
            setIsLoading(false);
        }
    }, [filterStatus, refresh]);

    const getDoctorById = useCallback((id: string) => {
        return doctorsStore.find(d => d.id === id) ?? null;
    }, []);

    return { doctors, isLoading, error, approveDoctor, rejectDoctor, getDoctorById, refresh };
}
