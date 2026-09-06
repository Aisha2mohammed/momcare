import { useState, useEffect, useCallback } from 'react';
import { Plus, Edit2, Trash2, Search, Loader2 } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea, Select } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

export interface SleepTip {
    id: string | number;
    titleAm: string;
    titleOr: string;
    titleEn?: string;
    descAm: string;
    descOr: string;
    descriptionAm?: string;
    descriptionOr?: string;
    descriptionEn?: string;
    trimester: string;
    trimesterNumber?: number;
    videoUrl?: string;
    illustrationUrl?: string;
    week?: string;
    videoFile?: File | null;
}

const empty: Omit<SleepTip, 'id'> = {
    titleAm: '',
    titleOr: '',
    titleEn: '',
    trimester: '1st',
    week: '',
    descAm: '',
    descOr: '',
    descriptionEn: '',
    videoUrl: '',
    illustrationUrl: '',
    videoFile: null,
};

export default function SleepPositionManager() {
    const { showToast } = useToast();
    const [entries, setEntries] = useState<SleepTip[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterTrimester, setFilterTrimester] = useState('All');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<SleepTip | null>(null);
    const [form, setForm] = useState<Omit<SleepTip, 'id'>>(empty);
    const [saving, setSaving] = useState(false);

    const fetchEntries = useCallback(async (search: string, trimester: string) => {
        try {
            setLoading(true);
            const params: any = {};
            if (search.trim()) params.search = search.trim();
            if (trimester !== 'All') params.trimester = trimester;

            const res = await cmsClient.list<SleepTip>('sleep', params);
            setEntries(res.items);
        } catch (err: any) {
            console.error('Failed to load sleep tips:', err);
            showToast(err.message || 'Failed to load sleep tips', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        const timer = setTimeout(() => {
            fetchEntries(searchTerm, filterTrimester);
        }, 250);
        return () => clearTimeout(timer);
    }, [searchTerm, filterTrimester, fetchEntries]);

    const refresh = () => fetchEntries(searchTerm, filterTrimester);

    function openCreate() {
        setEditing(null);
        setForm(empty);
        setModalOpen(true);
    }

    function openEdit(e: SleepTip) {
        setEditing(e);
        setForm({
            titleAm: e.titleAm || '',
            titleOr: e.titleOr || '',
            titleEn: e.titleEn || '',
            trimester: e.trimester || '1st',
            week: e.week || '',
            descAm: e.descAm || e.descriptionAm || '',
            descOr: e.descOr || e.descriptionOr || '',
            descriptionEn: e.descriptionEn || '',
            videoUrl: e.videoUrl || e.illustrationUrl || '',
            illustrationUrl: e.illustrationUrl || e.videoUrl || '',
            videoFile: null,
        });
        setModalOpen(true);
    }

    async function handleDelete(id: string | number) {
        if (!window.confirm('Are you sure you want to delete this sleep tip?')) return;
        try {
            await cmsClient.delete('sleep', id);
            showToast('Sleep tip deleted.', 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete sleep tip.', 'error');
        }
    }

    async function handleSave() {
        if (!form.titleAm && !form.titleOr && !form.titleEn) {
            showToast('Title is required in at least one language.', 'error');
            return;
        }

        try {
            setSaving(true);
            const payload = {
                titleAm: form.titleAm,
                titleOr: form.titleOr,
                titleEn: form.titleEn,
                trimester: form.trimester,
                descriptionAm: form.descAm,
                descriptionOr: form.descOr,
                descriptionEn: form.descriptionEn,
                illustrationUrl: form.videoUrl || form.illustrationUrl,
            };

            if (editing) {
                await cmsClient.update('sleep', editing.id, payload);
                showToast('Sleep tip updated!', 'success');
            } else {
                await cmsClient.create('sleep', payload);
                showToast('Sleep tip created!', 'success');
            }
            setModalOpen(false);
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to save sleep tip.', 'error');
        } finally {
            setSaving(false);
        }
    }

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Sleep Position Tips</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage recommended safe sleep positions, pillows and posture tips</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Tip</Button>
            </div>

            {/* Filters */}
            <div className="flex flex-col sm:flex-row gap-3 bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
                <div className="relative flex-1">
                    <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Search sleep tips by title or posture advice..."
                        value={searchTerm}
                        onChange={e => setSearchTerm(e.target.value)}
                        className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-xl focus:outline-none focus:border-[#61183e]"
                    />
                </div>
                <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-gray-500 uppercase">Trimester:</span>
                    <select
                        value={filterTrimester}
                        onChange={e => setFilterTrimester(e.target.value)}
                        className="text-sm border border-gray-200 rounded-xl px-3 py-2 bg-white text-gray-700 focus:outline-none focus:border-[#61183e]"
                    >
                        <option value="All">All Trimesters</option>
                        <option value="1st">1st Trimester</option>
                        <option value="2nd">2nd Trimester</option>
                        <option value="3rd">3rd Trimester</option>
                    </select>
                </div>
            </div>

            {/* List */}
            {loading ? (
                <div className="flex flex-col items-center justify-center p-12 text-gray-400">
                    <Loader2 className="w-8 h-8 animate-spin text-[#61183e] mb-2" />
                    <p className="text-sm font-medium">Loading sleep tips...</p>
                </div>
            ) : entries.length === 0 ? (
                <div className="text-center p-12 bg-white rounded-2xl border border-gray-100">
                    <p className="text-gray-500 text-sm">No sleep tips found matching your filter.</p>
                </div>
            ) : (
                <div className="grid gap-4 sm:grid-cols-2">
                    {entries.map(entry => (
                        <Card key={entry.id} className="relative flex flex-col justify-between">
                            <div>
                                <div className="flex items-start justify-between mb-3">
                                    <div>
                                        <h4 className="font-semibold text-gray-900">{entry.titleAm || entry.titleEn}</h4>
                                        {entry.titleOr && <p className="text-sm text-gray-500">{entry.titleOr}</p>}
                                    </div>
                                    <div className="flex gap-2">
                                        <Badge variant="pink">{entry.trimester} Tri.</Badge>
                                        {entry.week && <Badge variant="yellow">{entry.week}</Badge>}
                                    </div>
                                </div>
                                <p className="text-sm text-gray-600 mb-2">{entry.descAm || entry.descriptionAm || entry.descriptionEn}</p>
                                {entry.descOr && <p className="text-sm text-gray-400 italic mb-4">{entry.descOr}</p>}
                                {(entry.videoUrl || entry.illustrationUrl) && (
                                    <p className="text-xs text-[#61183e] font-medium mb-4 truncate font-mono">
                                        Media: {entry.videoUrl || entry.illustrationUrl}
                                    </p>
                                )}
                            </div>
                            <div className="flex gap-2 pt-2 border-t border-gray-50">
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
                    ))}
                </div>
            )}

            {/* Modal */}
            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Sleep Tip' : 'New Sleep Tip'} size="xl">
                <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Title (Amharic)" value={form.titleAm} onChange={e => setForm(f => ({ ...f, titleAm: e.target.value }))} placeholder="ርዕስ..." />
                        <Input label="Title (Afan Oromo)" value={form.titleOr} onChange={e => setForm(f => ({ ...f, titleOr: e.target.value }))} placeholder="Mata duree..." />
                    </div>
                    <div>
                        <Input label="Title (English)" value={form.titleEn || ''} onChange={e => setForm(f => ({ ...f, titleEn: e.target.value }))} placeholder="Title in English..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <Select
                            label="Trimester"
                            value={form.trimester}
                            onChange={e => setForm(f => ({ ...f, trimester: e.target.value }))}
                            options={[{ value: '1st', label: '1st Trimester' }, { value: '2nd', label: '2nd Trimester' }, { value: '3rd', label: '3rd Trimester' }, { value: 'All', label: 'All Trimesters' }]}
                        />
                        <Input label="Illustration / Media URL" value={form.videoUrl || ''} onChange={e => setForm(f => ({ ...f, videoUrl: e.target.value, illustrationUrl: e.target.value }))} placeholder="https://..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="Description (Amharic)" value={form.descAm} onChange={e => setForm(f => ({ ...f, descAm: e.target.value }))} rows={4} placeholder="ዝርዝር መመሪያ..." />
                        <TextArea label="Description (Afan Oromo)" value={form.descOr} onChange={e => setForm(f => ({ ...f, descOr: e.target.value }))} rows={4} placeholder="Ibsa..." />
                    </div>
                    <div>
                        <TextArea label="Description (English)" value={form.descriptionEn || ''} onChange={e => setForm(f => ({ ...f, descriptionEn: e.target.value }))} rows={2} placeholder="Sleep position description in English..." />
                    </div>
                    <div className="flex justify-end gap-3 pt-2">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave} disabled={saving}>
                            {saving ? 'Saving...' : editing ? 'Save Changes' : 'Create Tip'}
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
