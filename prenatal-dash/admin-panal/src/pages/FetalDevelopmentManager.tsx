import { useState, useEffect, useCallback } from 'react';
import { Plus, Edit2, Trash2, Search, Loader2 } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

export interface FetalEntry {
    id: string | number;
    week: number;
    weekNumber?: number;
    sizeComparison: string;
    milestoneAm: string;
    milestoneOr: string;
    milestoneEn?: string;
    tipsAm: string;
    tipsOr: string;
    tipsEn?: string;
    imageUrl?: string;
}

const empty: Omit<FetalEntry, 'id'> = {
    week: 1,
    sizeComparison: '',
    milestoneAm: '',
    milestoneOr: '',
    milestoneEn: '',
    tipsAm: '',
    tipsOr: '',
    tipsEn: '',
    imageUrl: '',
};

export default function FetalDevelopmentManager() {
    const { showToast } = useToast();
    const [entries, setEntries] = useState<FetalEntry[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<FetalEntry | null>(null);
    const [form, setForm] = useState<Omit<FetalEntry, 'id'>>(empty);
    const [saving, setSaving] = useState(false);

    const fetchEntries = useCallback(async (search: string) => {
        try {
            setLoading(true);
            const params: any = { limit: 50 };
            if (search.trim()) params.search = search.trim();

            const res = await cmsClient.list<FetalEntry>('fetal', params);
            setEntries(res.items);
        } catch (err: any) {
            console.error('Failed to load fetal tracker entries:', err);
            showToast(err.message || 'Failed to load fetal tracker entries', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        const timer = setTimeout(() => {
            fetchEntries(searchTerm);
        }, 250);
        return () => clearTimeout(timer);
    }, [searchTerm, fetchEntries]);

    const refresh = () => fetchEntries(searchTerm);

    function openCreate() {
        setEditing(null);
        setForm(empty);
        setModalOpen(true);
    }

    function openEdit(e: FetalEntry) {
        setEditing(e);
        setForm({
            week: e.week || e.weekNumber || 1,
            sizeComparison: e.sizeComparison || '',
            milestoneAm: e.milestoneAm || '',
            milestoneOr: e.milestoneOr || '',
            milestoneEn: e.milestoneEn || '',
            tipsAm: e.tipsAm || '',
            tipsOr: e.tipsOr || '',
            tipsEn: e.tipsEn || '',
            imageUrl: e.imageUrl || '',
        });
        setModalOpen(true);
    }

    async function handleDelete(id: string | number) {
        if (!window.confirm('Are you sure you want to delete this week entry?')) return;
        try {
            await cmsClient.delete('fetal', id);
            showToast('Week entry deleted successfully.', 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete week entry.', 'error');
        }
    }

    async function handleSave() {
        if (!form.week || form.week < 1 || form.week > 42) {
            showToast('Week number must be between 1 and 42.', 'error');
            return;
        }

        try {
            setSaving(true);
            const payload = {
                weekNumber: form.week,
                sizeComparison: form.sizeComparison,
                milestoneAm: form.milestoneAm,
                milestoneOr: form.milestoneOr,
                milestoneEn: form.milestoneEn,
                tipsAm: form.tipsAm,
                tipsOr: form.tipsOr,
                tipsEn: form.tipsEn,
                imageUrl: form.imageUrl,
            };

            if (editing) {
                await cmsClient.update('fetal', editing.id, payload);
                showToast(`Week ${form.week} updated!`, 'success');
            } else {
                await cmsClient.create('fetal', payload);
                showToast(`Week ${form.week} created!`, 'success');
            }
            setModalOpen(false);
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to save week entry.', 'error');
        } finally {
            setSaving(false);
        }
    }

    const sorted = [...entries].sort((a, b) => (a.week || a.weekNumber || 0) - (b.week || b.weekNumber || 0));

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Fetal Development Tracker</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage week-by-week development milestones and size comparisons (Weeks 1–40)</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Week Entry</Button>
            </div>

            {/* Search */}
            <div className="relative bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
                <Search className="w-4 h-4 absolute left-6 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                    type="text"
                    placeholder="Search fetal development by size comparison or milestone keyword..."
                    value={searchTerm}
                    onChange={e => setSearchTerm(e.target.value)}
                    className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-xl focus:outline-none focus:border-[#61183e]"
                />
            </div>

            {/* List */}
            {loading ? (
                <div className="flex flex-col items-center justify-center p-12 text-gray-400">
                    <Loader2 className="w-8 h-8 animate-spin text-[#61183e] mb-2" />
                    <p className="text-sm font-medium">Loading fetal development weeks...</p>
                </div>
            ) : sorted.length === 0 ? (
                <div className="text-center p-12 bg-white rounded-2xl border border-gray-100">
                    <p className="text-gray-500 text-sm">No weeks found. Click "Add Week Entry" to create one.</p>
                </div>
            ) : (
                <div className="grid gap-4">
                    {sorted.map(entry => {
                        const weekNum = entry.week || entry.weekNumber || 0;
                        return (
                            <Card key={entry.id} className="flex items-start gap-6">
                                <div className="shrink-0 w-20 h-20 rounded-2xl bg-[#fdf2f8] flex flex-col items-center justify-center">
                                    <span className="text-2xl font-black text-[#61183e]">{weekNum}</span>
                                    <span className="text-xs text-gray-500 font-medium">weeks</span>
                                </div>
                                <div className="flex-1">
                                    <div className="flex items-center gap-2 mb-1 flex-wrap">
                                        <Badge variant="pink">Size: {entry.sizeComparison}</Badge>
                                    </div>
                                    <p className="text-sm font-semibold text-gray-800">{entry.milestoneAm || entry.milestoneEn}</p>
                                    {entry.milestoneOr && <p className="text-sm text-gray-500">{entry.milestoneOr}</p>}
                                    {entry.milestoneEn && entry.milestoneAm && (
                                        <p className="text-xs text-gray-500 italic mt-0.5">{entry.milestoneEn}</p>
                                    )}
                                    <p className="text-xs text-gray-400 mt-2">💡 Tip: {entry.tipsAm || entry.tipsEn}</p>
                                </div>
                                <div className="flex gap-2 shrink-0">
                                    <button
                                        onClick={() => openEdit(entry)}
                                        className="p-2 rounded-lg hover:bg-blue-50 text-blue-600 transition-colors"
                                        title="Edit"
                                    >
                                        <Edit2 className="w-4 h-4" />
                                    </button>
                                    <button
                                        onClick={() => handleDelete(entry.id)}
                                        className="p-2 rounded-lg hover:bg-red-50 text-red-500 transition-colors"
                                        title="Delete"
                                    >
                                        <Trash2 className="w-4 h-4" />
                                    </button>
                                </div>
                            </Card>
                        );
                    })}
                </div>
            )}

            {/* Modal */}
            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? `Edit Week ${form.week} Entry` : 'New Week Entry'} size="xl">
                <div className="space-y-5">
                    <div className="grid grid-cols-2 gap-4">
                        <Input
                            label="Week Number (1–42)"
                            type="number"
                            min={1}
                            max={42}
                            value={form.week}
                            onChange={e => setForm(f => ({ ...f, week: parseInt(e.target.value, 10) || 1 }))}
                        />
                        <Input
                            label="Baby Size Comparison (e.g. 'Avocado')"
                            value={form.sizeComparison}
                            onChange={e => setForm(f => ({ ...f, sizeComparison: e.target.value }))}
                            placeholder="e.g. Raspberry, Lemon, Avocado"
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea
                            label="Developmental Milestone (Amharic)"
                            value={form.milestoneAm}
                            onChange={e => setForm(f => ({ ...f, milestoneAm: e.target.value }))}
                            rows={3}
                            placeholder="የህፃኑ እድገት..."
                        />
                        <TextArea
                            label="Developmental Milestone (Afan Oromo)"
                            value={form.milestoneOr}
                            onChange={e => setForm(f => ({ ...f, milestoneOr: e.target.value }))}
                            rows={3}
                            placeholder="Guddina daa'imaa..."
                        />
                    </div>
                    <div>
                        <TextArea
                            label="Developmental Milestone (English)"
                            value={form.milestoneEn || ''}
                            onChange={e => setForm(f => ({ ...f, milestoneEn: e.target.value }))}
                            rows={2}
                            placeholder="Milestone description in English..."
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea
                            label="Tips for Mother (Amharic)"
                            value={form.tipsAm}
                            onChange={e => setForm(f => ({ ...f, tipsAm: e.target.value }))}
                            rows={3}
                            placeholder="ለእናት የሚሰጥ ምክር..."
                        />
                        <TextArea
                            label="Tips for Mother (Afan Oromo)"
                            value={form.tipsOr}
                            onChange={e => setForm(f => ({ ...f, tipsOr: e.target.value }))}
                            rows={3}
                            placeholder="Gorsa haadhaa..."
                        />
                    </div>
                    <div className="flex justify-end gap-3 pt-2">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave} disabled={saving}>
                            {saving ? 'Saving...' : editing ? 'Save Changes' : 'Create Entry'}
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
