import { useState, useEffect, useCallback } from 'react';
import { Plus, Edit2, Trash2, Music, Play, Search, Loader2 } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, Select } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

export interface Track {
    id: string | number;
    titleAm: string;
    titleOr: string;
    titleEn?: string;
    category: string;
    duration: string;
    durationSeconds?: number;
    url?: string;
    mediaUrl?: string;
    thumbnailUrl?: string;
    trimester?: string;
    week?: string;
    active: boolean;
    isActive?: boolean;
    videoFile?: File | null;
}

const empty: Omit<Track, 'id'> = {
    titleAm: '',
    titleOr: '',
    titleEn: '',
    category: 'Relaxation',
    trimester: 'All',
    week: '',
    duration: '10:00',
    url: '',
    mediaUrl: '',
    active: true,
    isActive: true,
    videoFile: null,
};

const categoryColors: Record<string, 'pink' | 'purple' | 'blue' | 'yellow'> = {
    Relaxation: 'pink',
    Meditation: 'purple',
    Lullaby: 'blue',
};

export default function MusicLibraryManager() {
    const { showToast } = useToast();
    const [tracks, setTracks] = useState<Track[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterCategory, setFilterCategory] = useState('All');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<Track | null>(null);
    const [form, setForm] = useState<Omit<Track, 'id'>>(empty);
    const [saving, setSaving] = useState(false);

    const fetchTracks = useCallback(async (search: string, category: string) => {
        try {
            setLoading(true);
            const params: any = {};
            if (search.trim()) params.search = search.trim();
            if (category !== 'All') params.category = category;

            const res = await cmsClient.list<Track>('music', params);
            setTracks(res.items);
        } catch (err: any) {
            console.error('Failed to load music tracks:', err);
            showToast(err.message || 'Failed to load music tracks', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        const timer = setTimeout(() => {
            fetchTracks(searchTerm, filterCategory);
        }, 250);
        return () => clearTimeout(timer);
    }, [searchTerm, filterCategory, fetchTracks]);

    const refresh = () => fetchTracks(searchTerm, filterCategory);

    function openCreate() {
        setEditing(null);
        setForm(empty);
        setModalOpen(true);
    }

    function openEdit(t: Track) {
        setEditing(t);
        setForm({
            titleAm: t.titleAm || '',
            titleOr: t.titleOr || '',
            titleEn: t.titleEn || '',
            category: t.category || 'Relaxation',
            trimester: t.trimester || 'All',
            week: t.week || '',
            duration: t.duration || '10:00',
            url: t.url || t.mediaUrl || '',
            mediaUrl: t.mediaUrl || t.url || '',
            active: Boolean(t.active ?? t.isActive),
            isActive: Boolean(t.active ?? t.isActive),
            videoFile: null,
        });
        setModalOpen(true);
    }

    async function handleDelete(id: string | number) {
        if (!window.confirm('Are you sure you want to delete this audio track?')) return;
        try {
            await cmsClient.delete('music', id);
            showToast('Track deleted successfully.', 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete track.', 'error');
        }
    }

    async function toggleActive(track: Track) {
        const current = Boolean(track.active ?? track.isActive);
        try {
            await cmsClient.toggleActive('music', track.id, current);
            showToast(`Track status ${!current ? 'activated' : 'deactivated'}.`, 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to update track status.', 'error');
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
                category: form.category,
                duration: form.duration,
                mediaUrl: form.url || form.mediaUrl,
                isActive: Boolean(form.active ?? form.isActive),
            };

            if (editing) {
                await cmsClient.update('music', editing.id, payload);
                showToast('Track updated successfully!', 'success');
            } else {
                await cmsClient.create('music', payload);
                showToast('Track added successfully!', 'success');
            }
            setModalOpen(false);
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to save audio track.', 'error');
        } finally {
            setSaving(false);
        }
    }

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Music & Relaxation Library</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage relaxation audio tracks, guided meditations and lullabies</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Track</Button>
            </div>

            {/* Filters */}
            <div className="flex flex-col sm:flex-row gap-3 bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
                <div className="relative flex-1">
                    <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Search audio tracks by title (Amharic, Afan Oromo, English)..."
                        value={searchTerm}
                        onChange={e => setSearchTerm(e.target.value)}
                        className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-xl focus:outline-none focus:border-[#61183e]"
                    />
                </div>
                <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-gray-500 uppercase">Category:</span>
                    <select
                        value={filterCategory}
                        onChange={e => setFilterCategory(e.target.value)}
                        className="text-sm border border-gray-200 rounded-xl px-3 py-2 bg-white text-gray-700 focus:outline-none focus:border-[#61183e]"
                    >
                        <option value="All">All Categories</option>
                        <option value="Relaxation">Relaxation</option>
                        <option value="Meditation">Meditation</option>
                        <option value="Lullaby">Lullaby</option>
                    </select>
                </div>
            </div>

            {/* List */}
            {loading ? (
                <div className="flex flex-col items-center justify-center p-12 text-gray-400">
                    <Loader2 className="w-8 h-8 animate-spin text-[#61183e] mb-2" />
                    <p className="text-sm font-medium">Loading relaxation tracks...</p>
                </div>
            ) : tracks.length === 0 ? (
                <div className="text-center p-12 bg-white rounded-2xl border border-gray-100">
                    <p className="text-gray-500 text-sm">No audio tracks found matching your filter.</p>
                </div>
            ) : (
                <div className="grid gap-4">
                    {tracks.map(track => {
                        const isAct = Boolean(track.active ?? track.isActive);
                        return (
                            <Card key={track.id} className="flex items-center gap-5">
                                <div className="w-12 h-12 rounded-xl bg-[#fdf2f8] flex items-center justify-center shrink-0">
                                    <Music className="w-6 h-6 text-[#61183e]" />
                                </div>
                                <div className="flex-1">
                                    <div className="flex items-center gap-2 flex-wrap mb-1">
                                        <h4 className="font-semibold text-gray-900">{track.titleAm || track.titleEn}</h4>
                                        {track.titleOr && <span className="text-gray-400 text-sm">/ {track.titleOr}</span>}
                                        <Badge variant={categoryColors[track.category] || 'pink'}>{track.category}</Badge>
                                        {track.trimester && track.trimester !== 'All' && <Badge variant="pink">{track.trimester} Tri</Badge>}
                                        <Badge variant={isAct ? 'green' : 'gray'}>{isAct ? 'Active' : 'Inactive'}</Badge>
                                    </div>
                                    <p className="text-sm text-gray-500">Duration: {track.duration || '—'}</p>
                                    {(track.url || track.mediaUrl) && (
                                        <p className="text-sm text-[#61183e] flex items-center gap-1 mt-1 truncate">
                                            <Play className="w-3 h-3" /> {track.url || track.mediaUrl}
                                        </p>
                                    )}
                                </div>
                                <div className="flex gap-2 shrink-0">
                                    <button
                                        onClick={() => toggleActive(track)}
                                        className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${isAct ? 'bg-amber-50 text-amber-700 hover:bg-amber-100' : 'bg-green-50 text-green-700 hover:bg-green-100'}`}
                                    >
                                        {isAct ? 'Deactivate' : 'Activate'}
                                    </button>
                                    <button
                                        onClick={() => openEdit(track)}
                                        className="p-2 rounded-lg hover:bg-blue-50 text-blue-600 transition-colors"
                                        title="Edit"
                                    >
                                        <Edit2 className="w-4 h-4" />
                                    </button>
                                    <button
                                        onClick={() => handleDelete(track.id)}
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
            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Audio Track' : 'New Audio Track'} size="lg">
                <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Title (Amharic)" value={form.titleAm} onChange={e => setForm(f => ({ ...f, titleAm: e.target.value }))} placeholder="የዜማ ስም..." />
                        <Input label="Title (Afan Oromo)" value={form.titleOr} onChange={e => setForm(f => ({ ...f, titleOr: e.target.value }))} placeholder="Maqaa faaruu..." />
                    </div>
                    <div>
                        <Input label="Title (English)" value={form.titleEn || ''} onChange={e => setForm(f => ({ ...f, titleEn: e.target.value }))} placeholder="Track title in English..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <Select
                            label="Category"
                            value={form.category}
                            onChange={e => setForm(f => ({ ...f, category: e.target.value }))}
                            options={['Relaxation', 'Meditation', 'Lullaby'].map(c => ({ value: c, label: c }))}
                        />
                        <Input label="Duration (e.g. '10:00')" value={form.duration} onChange={e => setForm(f => ({ ...f, duration: e.target.value }))} placeholder="mm:ss" />
                    </div>
                    <div>
                        <Input label="Audio Stream / Media URL" value={form.url || ''} onChange={e => setForm(f => ({ ...f, url: e.target.value, mediaUrl: e.target.value }))} placeholder="https://..." />
                    </div>
                    <label className="flex items-center gap-3 cursor-pointer">
                        <div
                            onClick={() => setForm(f => ({ ...f, active: !(f.active ?? f.isActive), isActive: !(f.active ?? f.isActive) }))}
                            className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${(form.active ?? form.isActive) ? 'bg-[#61183e]' : 'bg-gray-300'}`}
                        >
                            <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${(form.active ?? form.isActive) ? 'left-6' : 'left-1'}`} />
                        </div>
                        <span className="text-sm font-medium text-gray-700">{(form.active ?? form.isActive) ? 'Active — accessible to mothers' : 'Inactive'}</span>
                    </label>
                    <div className="flex justify-end gap-3 pt-2">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave} disabled={saving}>
                            {saving ? 'Saving...' : editing ? 'Save Changes' : 'Add Track'}
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
