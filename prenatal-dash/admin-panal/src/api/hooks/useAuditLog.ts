import { useState, useCallback } from 'react';
import { mockAuditLog } from '../mockData';
import type { AuditEntry, AuditActionType } from '../types';

let auditStore: AuditEntry[] = [...mockAuditLog];

export function useAuditLog(filters?: { actionType?: AuditActionType; search?: string }) {
    const applyFilters = (entries: AuditEntry[]) => {
        let result = [...entries];
        if (filters?.actionType) result = result.filter(e => e.actionType === filters.actionType);
        if (filters?.search) {
            const s = filters.search.toLowerCase();
            result = result.filter(e =>
                e.adminUser.toLowerCase().includes(s) ||
                e.targetEntity.toLowerCase().includes(s) ||
                e.details.toLowerCase().includes(s)
            );
        }
        return result;
    };

    const [entries] = useState<AuditEntry[]>(applyFilters(auditStore));
    const [isLoading] = useState(false);
    const [error] = useState<string | null>(null);

    const addEntry = useCallback((entry: Omit<AuditEntry, 'id' | 'timestamp'>) => {
        const newEntry: AuditEntry = {
            ...entry,
            id: `AL${String(auditStore.length + 1).padStart(3, '0')}`,
            timestamp: new Date().toISOString(),
        };
        auditStore = [newEntry, ...auditStore];
    }, []);

    const exportCSV = useCallback(() => {
        const headers = ['ID', 'Timestamp', 'Admin User', 'Action Type', 'Target Entity', 'Before', 'After', 'Details'];
        const rows = auditStore.map(e => [
            e.id, e.timestamp, e.adminUser, e.actionType, e.targetEntity,
            e.beforeSummary ?? '', e.afterSummary ?? '', e.details
        ]);
        const csv = [headers, ...rows].map(row => row.map(cell => `"${cell}"`).join(',')).join('\n');
        const blob = new Blob([csv], { type: 'text/csv' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `audit-log-${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
        URL.revokeObjectURL(url);
    }, []);

    return { entries, isLoading, error, addEntry, exportCSV };
}
