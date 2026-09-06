import { useState, useEffect, useCallback } from 'react';
import { Plus, Edit2, Trash2, Eye, EyeOff, Search, Loader2 } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

export interface ExerciseEntry {
    id: string | number;
    nameAm: string;
    nameOr: string;
    nameEn?: string;
    trimesters: string[];
    trimesterFlags?: number[];
    videoUrl?: string;
    mediaUrl?: string;
    duration?: string;
    durationMin?: number;
    safetyAm: string;
    safetyOr: string;
    safetyNotesAm?: string;
    safetyNotesOr?: string;
    safetyNotesEn?: string;
    published?: boolean;
    isPublished?: boolean;
    week?: string;
    videoFile?: File | null;
}

const empty: Omit<ExerciseEntry, 'id'> = {
    nameAm: '',
    nameOr: '',
    nameEn: '',
    trimesters: ['1st'],
    week: '',
    videoUrl: '',
    mediaUrl: '',
    videoFile: null,
    duration: '15 min',
    safetyAm: '',
    safetyOr: '',
    safetyNotesEn: '',
    published: false,
    isPublished: false,
};

const allTrimesters = ['1st', '2nd', '3rd'];

export default function ExerciseManager() {
    const { showToast } = useToast();
    const [entries, setEntries] = useState<ExerciseEntry[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterTrimester, setFilterTrimester] = useState('All');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<ExerciseEntry | null>(null);
    const [form, setForm] = useState<Omit<ExerciseEntry, 'id'>>(empty);
    const [saving, setSaving] = useState(false);

    const fetchEntries = useCallback(async (search: string, trimester: string) => {
        try {
            setLoading(true);
            const params: any = {};
            if (search.trim()) params.search = search.trim();
            if (trimester !== 'All') params.trimester = trimester;

            const res = await cmsClient.list<ExerciseEntry>('exercises', params);
            setEntries(res.items);
        } catch (err: any) {
            console.error('Failed to load exercises:', err);
            showToast(err.message || 'Failed to load exercises', 'error');
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

    function toggleTrimester(t: string) {
        setForm(f => ({
            ...f,
            trimesters: f.trimesters.includes(t) ? f.trimesters.filter(x => x !== t) : [...f.trimesters, t],
        }));
    }

    function openCreate() {
        setEditing(null);
        setForm(empty);
        setModalOpen(true);
    }

    function openEdit(e: ExerciseEntry) {
        setEditing(e);
        setForm({
            nameAm: e.nameAm || '',
            nameOr: e.nameOr || '',
            nameEn: e.nameEn || '',
            trimesters: e.trimesters || ['1st'],
            week: e.week || '',
            videoUrl: e.videoUrl || e.mediaUrl || '',
            mediaUrl: e.mediaUrl || e.videoUrl || '',
            videoFile: null,
            duration: e.duration || (e.durationMin ? `${e.durationMin} min` : '15 min'),
            safetyAm: e.safetyAm || e.safetyNotesAm || '',
            safetyOr: e.safetyOr || e.safetyNotesOr || '',
            safetyNotesEn: e.safetyNotesEn || '',
            published: Boolean(e.published ?? e.isPublished),
            isPublished: Boolean(e.published ?? e.isPublished),
        });
        setModalOpen(true);
    }

    async function handleDelete(id: string | number) {
        if (!window.confirm('Are you sure you want to delete this exercise?')) return;
        try {
            await cmsClient.delete('exercises', id);
            showToast('Exercise entry deleted.', 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete exercise.', 'error');
        }
    }

    async function togglePublish(entry: ExerciseEntry) {
        const current = Boolean(entry.published ?? entry.isPublished);
        try {
            await cmsClient.togglePublish('exercises', entry.id, current);
            showToast(`Exercise ${!current ? 'published' : 'moved to drafts'}.`, 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to toggle visibility.', 'error');
        }
    }

    async function handleSave() {
        if (!form.nameAm && !form.nameOr && !form.nameEn) {
            showToast('Exercise name is required in at least one language.', 'error');
            return;
        }

        try {
            setSaving(true);
            const payload = {
                nameAm: form.nameAm,
                nameOr: form.nameOr,
                nameEn: form.nameEn,
                trimesters: form.trimesters,
                duration: form.duration,
                safetyNotesAm: form.safetyAm,
                safetyNotesOr: form.safetyOr,
                safetyNotesEn: form.safetyNotesEn,
                mediaUrl: form.videoUrl || form.mediaUrl,
                isPublished: Boolean(form.published ?? form.isPublished),
            };

            if (editing) {
                await cmsClient.update('exercises', editing.id, payload);
                showToast('Exercise updated successfully!', 'success');
            } else {
                await cmsClient.create('exercises', payload);
                showToast('Exercise created successfully!', 'success');
            }
            setModalOpen(false);
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to save exercise.', 'error');
        } finally {
            setSaving(false);
        }
    }

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Exercise Recommendations</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage recommended safe exercises and guided workouts for expectant mothers</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Exercise</Button>
            </div>

            {/* Filters */}
            <div className="flex flex-col sm:flex-row gap-3 bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
                <div className="relative flex-1">
                    <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Search exercises by name or safety instructions..."
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
                    <p className="text-sm font-medium">Loading exercises from backend...</p>
                </div>
            ) : entries.length === 0 ? (
                <div className="text-center p-12 bg-white rounded-2xl border border-gray-100">
                    <p className="text-gray-500 text-sm">No exercises found matching your search.</p>
                </div>
            ) : (
                <div className="grid gap-4">
                    {entries.map(entry => {
                        const isPub = Boolean(entry.published ?? entry.isPublished);
                        return (
                            <Card key={entry.id} className="flex items-start justify-between gap-4">
                                <div className="flex-1">
                                    <div className="flex items-center gap-2 mb-2 flex-wrap">
                                        <h4 className="font-semibold text-gray-900">{entry.nameAm || entry.nameEn}</h4>
                                        {entry.nameOr && <span className="text-gray-400 text-sm">/ {entry.nameOr}</span>}
                                        <Badge variant={isPub ? 'green' : 'gray'}>{isPub ? 'Published' : 'Draft'}</Badge>
                                        {(entry.trimesters || []).map(t => <Badge key={t} variant="pink">{t} Tri</Badge>)}
                                        {entry.duration && <Badge variant="blue">{entry.duration}</Badge>}
                                    </div>
                                    <p className="text-sm text-gray-600">⚠️ {entry.safetyAm || entry.safetyNotesAm || entry.safetyNotesEn}</p>
                                    {(entry.videoUrl || entry.mediaUrl) && (
                                        <p className="text-xs text-[#61183e] font-medium mt-2 font-mono truncate">
                                            Video: {entry.videoUrl || entry.mediaUrl}
                                        </p>
                                    )}
                                </div>
                                <div className="flex gap-2 shrink-0">
                                    <button
                                        onClick={() => togglePublish(entry)}
                                        className="p-2 rounded-lg hover:bg-[#fdf2f8] text-[#61183e] transition-colors"
                                        title={isPub ? 'Unpublish' : 'Publish'}
                                    >
                                        {isPub ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                                    </button>
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
            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Exercise' : 'New Exercise'} size="xl">
                <div className="space-y-5">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Name (Amharic)" value={form.nameAm} onChange={e => setForm(f => ({ ...f, nameAm: e.target.value }))} placeholder="የእንቅስቃሴ ስም..." />
                        <Input label="Name (Afan Oromo)" value={form.nameOr} onChange={e => setForm(f => ({ ...f, nameOr: e.target.value }))} placeholder="Maqaa shaakalaa..." />
                    </div>
                    <div>
                        <Input label="Name (English)" value={form.nameEn || ''} onChange={e => setForm(f => ({ ...f, nameEn: e.target.value }))} placeholder="Exercise name in English..." />
                    </div>
                    <div>
                        <p className="text-sm font-medium text-gray-700 mb-2">Trimester Suitability</p>
                        <div className="flex gap-3">
                            {allTrimesters.map(t => (
                                <button
                                    key={t}
                                    type="button"
                                    onClick={() => toggleTrimester(t)}
                                    className={`px-4 py-2 rounded-lg text-sm font-medium border transition-colors ${form.trimesters.includes(t) ? 'bg-[#61183e] text-white border-[#61183e]' : 'border-gray-200 text-gray-600 hover:border-[#61183e]'}`}
                                >
                                    {t} Trimester
                                </button>
                            ))}
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Duration (e.g. '15 min')" value={form.duration || ''} onChange={e => setForm(f => ({ ...f, duration: e.target.value }))} placeholder="15 min" />
                        <Input label="Video / Media URL" value={form.videoUrl || ''} onChange={e => setForm(f => ({ ...f, videoUrl: e.target.value, mediaUrl: e.target.value }))} placeholder="https://youtube.com/..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="Safety Notes (Amharic)" value={form.safetyAm} onChange={e => setForm(f => ({ ...f, safetyAm: e.target.value }))} rows={3} placeholder="የደህንነት ጥንቃቄዎች..." />
                        <TextArea label="Safety Notes (Afan Oromo)" value={form.safetyOr} onChange={e => setForm(f => ({ ...f, safetyOr: e.target.value }))} rows={3} placeholder="Of eeggannoo..." />
                    </div>
                    <div>
                        <TextArea label="Safety Notes (English)" value={form.safetyNotesEn || ''} onChange={e => setForm(f => ({ ...f, safetyNotesEn: e.target.value }))} rows={2} placeholder="Safety precautions in English..." />
                    </div>
                    <label className="flex items-center gap-3 cursor-pointer">
                        <div
                            onClick={() => setForm(f => ({ ...f, published: !(f.published ?? f.isPublished), isPublished: !(f.published ?? f.isPublished) }))}
                            className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${(form.published ?? form.isPublished) ? 'bg-[#61183e]' : 'bg-gray-300'}`}
                        >
                            <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${(form.published ?? form.isPublished) ? 'left-6' : 'left-1'}`} />
                        </div>
                        <span className="text-sm font-medium text-gray-700">{(form.published ?? form.isPublished) ? 'Published' : 'Draft'}</span>
                    </label>
                    <div className="flex justify-end gap-3 pt-2">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave} disabled={saving}>
                            {saving ? 'Saving...' : editing ? 'Save Changes' : 'Create Exercise'}
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
