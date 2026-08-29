import { useState } from 'react';
import { Search, Download, Filter, Clock } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { useAuditLog } from '../api/hooks/useAuditLog';
import type { AuditActionType } from '../api/types';

const actionTypes: (AuditActionType | 'All')[] = [
    'All', 'Account Change', 'Content Update', 'Approval', 'Suspension',
    'Login', 'Provider Update', 'Announcement Sent', 'Content Delete'
];

const actionBadgeVariant = (type: AuditActionType): 'green' | 'yellow' | 'red' | 'blue' | 'gray' | 'pink' => {
    if (type === 'Approval') return 'green';
    if (type === 'Suspension') return 'red';
    if (type === 'Login') return 'blue';
    if (type === 'Account Change') return 'yellow';
    if (type === 'Content Delete') return 'red';
    if (type === 'Announcement Sent') return 'pink';
    return 'gray';
};

export default function AuditLog() {
    const [search, setSearch] = useState('');
    const [actionFilter, setActionFilter] = useState<AuditActionType | 'All'>('All');

    const { entries, isLoading, exportCSV } = useAuditLog({
        actionType: actionFilter === 'All' ? undefined : actionFilter,
        search: search || undefined,
    });

    const formatTimestamp = (ts: string) => {
        const d = new Date(ts);
        return d.toLocaleString('en-US', { dateStyle: 'medium', timeStyle: 'short' });
    };

    if (isLoading) {
        return <div className="flex justify-center py-16"><div className="animate-spin rounded-full h-8 w-8 border-2 border-[#61183e] border-t-transparent" /></div>;
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Audit Log</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Complete history of all admin actions</p>
                </div>
                <Button variant="secondary" size="sm" icon={<Download className="w-4 h-4" />} onClick={exportCSV}>
                    Export CSV
                </Button>
            </div>

            <Card>
                {/* Filters */}
                <div className="flex flex-wrap gap-3 mb-6">
                    <div className="flex-1 min-w-[200px] relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                        <input
                            className="w-full pl-10 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white"
                            placeholder="Search admin, entity, or details..."
                            value={search}
                            onChange={e => setSearch(e.target.value)}
                        />
                    </div>
                    <div className="relative flex items-center gap-2">
                        <Filter className="w-4 h-4 text-gray-400" />
                        <select
                            value={actionFilter}
                            onChange={e => setActionFilter(e.target.value as AuditActionType | 'All')}
                            className="pl-3 pr-8 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:outline-none focus:border-[#61183e] cursor-pointer appearance-none"
                        >
                            {actionTypes.map(t => (
                                <option key={t} value={t}>{t}</option>
                            ))}
                        </select>
                    </div>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="border-b border-gray-100">
                                {['Timestamp', 'Admin User', 'Action', 'Target Entity', 'Before → After', 'Details'].map(h => (
                                    <th key={h} className="text-left pb-3 text-xs text-gray-500 font-medium pr-4">{h}</th>
                                ))}
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-50">
                            {entries.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="text-center text-gray-400 py-12">
                                        <div className="flex flex-col items-center gap-2">
                                            <Clock className="w-10 h-10 text-gray-200" />
                                            <p>No audit entries match your filters.</p>
                                        </div>
                                    </td>
                                </tr>
                            ) : entries.map(entry => (
                                <tr key={entry.id} className="hover:bg-gray-50/80 transition-colors">
                                    <td className="py-3.5 pr-4 whitespace-nowrap">
                                        <p className="text-xs font-medium text-gray-700">{formatTimestamp(entry.timestamp)}</p>
                                    </td>
                                    <td className="py-3.5 pr-4">
                                        <div className="flex items-center gap-2">
                                            <div className="w-7 h-7 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center shrink-0">
                                                {entry.adminUser.split(' ').map(n => n[0]).join('')}
                                            </div>
                                            <span className="text-xs text-gray-700 whitespace-nowrap">{entry.adminUser}</span>
                                        </div>
                                    </td>
                                    <td className="py-3.5 pr-4">
                                        <Badge variant={actionBadgeVariant(entry.actionType)}>{entry.actionType}</Badge>
                                    </td>
                                    <td className="py-3.5 pr-4 text-gray-600 text-xs max-w-[160px] break-words">{entry.targetEntity}</td>
                                    <td className="py-3.5 pr-4 text-xs">
                                        {entry.beforeSummary && (
                                            <span className="text-red-500 line-through">{entry.beforeSummary}</span>
                                        )}
                                        {entry.beforeSummary && entry.afterSummary && <span className="text-gray-400 mx-1">→</span>}
                                        {entry.afterSummary && (
                                            <span className="text-green-600 font-medium">{entry.afterSummary}</span>
                                        )}
                                        {!entry.beforeSummary && !entry.afterSummary && (
                                            <span className="text-gray-400">—</span>
                                        )}
                                    </td>
                                    <td className="py-3.5 text-xs text-gray-500 max-w-[200px]">{entry.details}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
                <p className="text-xs text-gray-400 mt-4">{entries.length} entries shown</p>
            </Card>
        </div>
    );
}
