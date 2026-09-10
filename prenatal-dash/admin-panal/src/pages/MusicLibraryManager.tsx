import { useState, useEffect, useCallback } from 'react';
import { Plus, Edit2, Trash2, Music, Play, Search, Loader2, Globe } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea, Select } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { MediaInput } from '../components/ui/MediaInput';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface Track {
    id: string | number;
    category: string;
    titleEn?: string;
    titleAm?: string;
    titleOm?: string;
    titleSo?: string;
    descriptionEn?: string;
    descriptionAm?: string;
    descriptionOm?: string;
    descriptionSo?: string;
    audioEnUrl?: string;
    audioAmUrl?: string;
    audioOmUrl?: string;
    audioSoUrl?: string;
    imageUrl?: string;
    durationSeconds?: number;
    benefitsEn?: string;
    benefitsAm?: string;
    benefitsOm?: string;
    benefitsSo?: string;
    isActive?: boolean;
    isFeatured?: boolean;
    displayOrder?: number;
}

const EMPTY: Omit<Track, 'id'> = {
    category: 'relaxation',
    titleEn: '', titleAm: '', titleOm: '', titleSo: '',
    descriptionEn: '', descriptionAm: '', descriptionOm: '', descriptionSo: '',
    audioEnUrl: '', audioAmUrl: '', audioOmUrl: '', audioSoUrl: '',
    imageUrl: '',
    durationSeconds: 0,
    benefitsEn: '', benefitsAm: '', benefitsOm: '', benefitsSo: '',
    isActive: true,
    isFeatured: false,
    displayOrder: 0,
};

const CATEGORIES = ['relaxation', 'classical', 'lullaby', 'stories'];
const categoryColors: Record<string, 'pink' | 'purple' | 'blue' | 'yellow' | 'green'> = {
    relaxation: 'pink',
    classical: 'blue',
    lullaby: 'purple',
    stories: 'green',
};

const LANG_TABS = [
    { code: 'en', label: '🇬🇧 English', color: '#2563EB' },
    { code: 'am', label: '🇪🇹 አማርኛ', color: '#7C3AED' },
    { code: 'om', label: '🌿 Afaan Oromo', color: '#059669' },
    { code: 'so', label: '🌊 Af-Soomaali', color: '#DB2777' },
];

// ─── Component ────────────────────────────────────────────────────────────────

export default function MusicLibraryManager() {
    const { showToast } = useToast();
    const [tracks, setTracks] = useState<Track[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterCategory, setFilterCategory] = useState('All');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<Track | null>(null);
    const [form, setForm] = useState<Omit<Track, 'id'>>(EMPTY);
    const [saving, setSaving] = useState(false);
    const [activeLang, setActiveLang] = useState('en');

    // ── Fetch ────────────────────────────────────────────────────────────────
    const fetchTracks = useCallback(async (search: string, category: string) => {
        try {
            setLoading(true);
            const params: any = {};
            if (search.trim()) params.search = search.trim();
            if (category !== 'All') params.category = category;

            const res = await cmsClient.list<Track>('music', params);
            setTracks(res.items);
        } catch (err: any) {
            showToast(err.message || 'Failed to load music tracks', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        const t = setTimeout(() => fetchTracks(searchTerm, filterCategory), 250);
        return () => clearTimeout(t);
    }, [searchTerm, filterCategory, fetchTracks]);

    const refresh = () => fetchTracks(searchTerm, filterCategory);

    // ── Open modals ───────────────────────────────────────────────────────────
    function openCreate() {
        setEditing(null);
        setForm(EMPTY);
        setActiveLang('en');
        setModalOpen(true);
    }

    function openEdit(t: Track) {
        setEditing(t);
        setForm({
            category: t.category || 'relaxation',
            titleEn: t.titleEn || '',
            titleAm: t.titleAm || '',
            titleOm: t.titleOm || '',
            titleSo: t.titleSo || '',
            descriptionEn: t.descriptionEn || '',
            descriptionAm: t.descriptionAm || '',
            descriptionOm: t.descriptionOm || '',
            descriptionSo: t.descriptionSo || '',
            audioEnUrl: t.audioEnUrl || '',
            audioAmUrl: t.audioAmUrl || '',
            audioOmUrl: t.audioOmUrl || '',
            audioSoUrl: t.audioSoUrl || '',
            imageUrl: t.imageUrl || '',
            durationSeconds: t.durationSeconds || 0,
            benefitsEn: t.benefitsEn || '',
            benefitsAm: t.benefitsAm || '',
            benefitsOm: t.benefitsOm || '',
            benefitsSo: t.benefitsSo || '',
            isActive: t.isActive ?? true,
            isFeatured: t.isFeatured ?? false,
            displayOrder: t.displayOrder ?? 0,
        });
        setActiveLang('en');
        setModalOpen(true);
    }

    // ── Delete / toggle ───────────────────────────────────────────────────────
    async function handleDelete(id: string | number) {
        if (!window.confirm('Delete this audio track?')) return;
        try {
            await cmsClient.delete('music', id);
            showToast('Track deleted.', 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete.', 'error');
        }
    }

    async function toggleActive(track: Track) {
        try {
            await cmsClient.update('music', track.id, { isActive: !track.isActive });
            showToast(`Track ${!track.isActive ? 'activated' : 'deactivated'}.`, 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to update status.', 'error');
        }
    }

    // ── Save ──────────────────────────────────────────────────────────────────
    async function handleSave() {
        if (!form.titleEn && !form.titleAm) {
            showToast('At least English or Amharic title is required.', 'error');
            return;
        }
        if (!form.category) {
            showToast('Category is required.', 'error');
            return;
        }
        try {
            setSaving(true);
            const payload = {
                category: form.category,
                titleEn: form.titleEn || undefined,
                titleAm: form.titleAm || undefined,
                titleOm: form.titleOm || undefined,
                titleSo: form.titleSo || undefined,
                descriptionEn: form.descriptionEn || undefined,
                descriptionAm: form.descriptionAm || undefined,
                descriptionOm: form.descriptionOm || undefined,
                descriptionSo: form.descriptionSo || undefined,
                audioEnUrl: form.audioEnUrl || undefined,
                audioAmUrl: form.audioAmUrl || undefined,
                audioOmUrl: form.audioOmUrl || undefined,
                audioSoUrl: form.audioSoUrl || undefined,
                imageUrl: form.imageUrl || undefined,
                durationSeconds: form.durationSeconds || undefined,
                benefitsEn: form.benefitsEn || undefined,
                benefitsAm: form.benefitsAm || undefined,
                benefitsOm: form.benefitsOm || undefined,
                benefitsSo: form.benefitsSo || undefined,
                isActive: form.isActive,
                isFeatured: form.isFeatured,
                displayOrder: form.displayOrder || 0,
            };

            if (editing) {
                await cmsClient.update('music', editing.id, payload);
                showToast('Track updated!', 'success');
            } else {
                await cmsClient.create('music', payload);
                showToast('Track added!', 'success');
            }
            setModalOpen(false);
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to save track.', 'error');
        } finally {
            setSaving(false);
        }
    }

    // ── Render ────────────────────────────────────────────────────────────────
    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Music & Relaxation Library</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage relaxation, classical & lullaby audio tracks in 4 languages</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Track</Button>
            </div>

            {/* Filters */}
            <div className="flex flex-col sm:flex-row gap-3 bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
                <div className="relative flex-1">
                    <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Search by title (English, Amharic, Oromo, Somali)…"
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
                        {CATEGORIES.map(c => <option key={c} value={c}>{c[0].toUpperCase() + c.slice(1)}</option>)}
                    </select>
                </div>
            </div>

            {/* List */}
            {loading ? (
                <div className="flex flex-col items-center justify-center p-12 text-gray-400">
                    <Loader2 className="w-8 h-8 animate-spin text-[#61183e] mb-2" />
                    <p className="text-sm font-medium">Loading tracks…</p>
                </div>
            ) : tracks.length === 0 ? (
                <div className="text-center p-12 bg-white rounded-2xl border border-gray-100">
                    <Music className="w-10 h-10 mx-auto text-gray-300 mb-3" />
                    <p className="text-gray-500 text-sm">No tracks found. Click "Add Track" to create one.</p>
                </div>
            ) : (
                <div className="grid gap-4">
                    {tracks.map(track => {
                        const title = track.titleEn || track.titleAm || track.titleOm || '—';
                        const isAct = Boolean(track.isActive);
                        return (
                            <Card key={track.id} className="flex items-center gap-5">
                                {/* Thumb */}
                                <div className="w-14 h-14 rounded-xl overflow-hidden shrink-0 bg-[#fdf2f8] flex items-center justify-center">
                                    {track.imageUrl ? (
                                        <img src={track.imageUrl} alt={title} className="w-full h-full object-cover" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
                                    ) : (
                                        <Music className="w-7 h-7 text-[#61183e]" />
                                    )}
                                </div>
                                {/* Info */}
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2 flex-wrap mb-1">
                                        <h4 className="font-semibold text-gray-900 truncate">{title}</h4>
                                        <Badge variant={categoryColors[track.category] || 'pink'}>{track.category}</Badge>
                                        <Badge variant={isAct ? 'green' : 'gray'}>{isAct ? 'Active' : 'Inactive'}</Badge>
                                        {track.isFeatured && <Badge variant="yellow">⭐ Featured</Badge>}
                                    </div>
                                    {track.titleAm && <p className="text-xs text-gray-400">አማርኛ: {track.titleAm}</p>}
                                    <div className="flex gap-3 mt-1 flex-wrap">
                                        {track.durationSeconds && track.durationSeconds > 0 && (
                                            <span className="text-xs text-gray-400 flex items-center gap-1">
                                                ⏱ {Math.floor(track.durationSeconds / 60)}:{String(track.durationSeconds % 60).padStart(2, '0')}
                                            </span>
                                        )}
                                        {track.audioEnUrl && <span className="text-xs text-green-600">🎵 EN</span>}
                                        {track.audioAmUrl && <span className="text-xs text-purple-600">🎵 AM</span>}
                                        {track.audioOmUrl && <span className="text-xs text-teal-600">🎵 OM</span>}
                                        {track.audioSoUrl && <span className="text-xs text-pink-600">🎵 SO</span>}
                                    </div>
                                </div>
                                {/* Actions */}
                                <div className="flex gap-2 shrink-0">
                                    <button
                                        onClick={() => toggleActive(track)}
                                        className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${isAct ? 'bg-amber-50 text-amber-700 hover:bg-amber-100' : 'bg-green-50 text-green-700 hover:bg-green-100'}`}
                                    >
                                        {isAct ? 'Deactivate' : 'Activate'}
                                    </button>
                                    <button onClick={() => openEdit(track)} className="p-2 rounded-lg hover:bg-blue-50 text-blue-600 transition-colors" title="Edit">
                                        <Edit2 className="w-4 h-4" />
                                    </button>
                                    <button onClick={() => handleDelete(track.id)} className="p-2 rounded-lg hover:bg-red-50 text-red-500 transition-colors" title="Delete">
                                        <Trash2 className="w-4 h-4" />
                                    </button>
                                </div>
                            </Card>
                        );
                    })}
                </div>
            )}

            {/* ── Modal ── */}
            <Modal
                isOpen={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Edit Audio Track' : 'New Audio Track'}
                size="xl"
            >
                <div className="space-y-5">
                    {/* Row 1: Category + Duration + Display Order */}
                    <div className="grid grid-cols-3 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Category *</label>
                            <select
                                value={form.category}
                                onChange={e => setForm(f => ({ ...f, category: e.target.value }))}
                                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-[#61183e]"
                            >
                                {CATEGORIES.map(c => <option key={c} value={c}>{c[0].toUpperCase() + c.slice(1)}</option>)}
                            </select>
                        </div>
                        <Input
                            label="Duration (minutes)"
                            type="number"
                            min={0}
                            step="any"
                            value={form.durationSeconds ? Math.round(form.durationSeconds / 60 * 10) / 10 : ''}
                            onChange={e => setForm(f => ({ ...f, durationSeconds: Math.round(parseFloat(e.target.value) * 60) || 0 }))}
                            placeholder="5"
                        />
                        <Input
                            label="Display Order"
                            type="number"
                            min={0}
                            value={form.displayOrder || ''}
                            onChange={e => setForm(f => ({ ...f, displayOrder: parseInt(e.target.value) || 0 }))}
                            placeholder="1"
                        />
                    </div>

                    {/* Cover Image URL */}
                    <MediaInput
                        label="Cover Image"
                        type="image"
                        value={form.imageUrl || ''}
                        onChange={url => setForm(f => ({ ...f, imageUrl: url }))}
                    />

                    {/* Language tabs */}
                    <div>
                        <div className="flex items-center gap-1 mb-3">
                            <Globe className="w-4 h-4 text-gray-400" />
                            <span className="text-sm font-semibold text-gray-600">Content by Language</span>
                        </div>
                        <div className="flex gap-2 mb-4">
                            {LANG_TABS.map(lt => (
                                <button
                                    key={lt.code}
                                    onClick={() => setActiveLang(lt.code)}
                                    className={`px-3 py-1.5 text-sm rounded-lg font-medium transition-all ${activeLang === lt.code ? 'text-white shadow-sm' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}
                                    style={activeLang === lt.code ? { backgroundColor: lt.color } : {}}
                                >
                                    {lt.label}
                                </button>
                            ))}
                        </div>

                        {/* EN */}
                        {activeLang === 'en' && (
                            <div className="space-y-4 p-4 bg-blue-50 rounded-xl border border-blue-100">
                                <Input label="Title (English) *" value={form.titleEn || ''} onChange={e => setForm(f => ({ ...f, titleEn: e.target.value }))} placeholder="Calming Nature Sounds" />
                                <TextArea label="Description (English)" value={form.descriptionEn || ''} onChange={e => setForm(f => ({ ...f, descriptionEn: e.target.value }))} rows={2} placeholder="Describe this track in English…" />
                                <Input label="Audio URL (English)" value={form.audioEnUrl || ''} onChange={e => setForm(f => ({ ...f, audioEnUrl: e.target.value }))} placeholder="https://…/audio-en.mp3" />
                                <TextArea label="Benefits (English)" value={form.benefitsEn || ''} onChange={e => setForm(f => ({ ...f, benefitsEn: e.target.value }))} rows={2} placeholder="Health benefits of listening…" />
                            </div>
                        )}
                        {/* AM */}
                        {activeLang === 'am' && (
                            <div className="space-y-4 p-4 bg-purple-50 rounded-xl border border-purple-100">
                                <Input label="Title (አማርኛ) *" value={form.titleAm || ''} onChange={e => setForm(f => ({ ...f, titleAm: e.target.value }))} placeholder="የተፈጥሮ ማረጋጋት ድምፆች" />
                                <TextArea label="Description (አማርኛ)" value={form.descriptionAm || ''} onChange={e => setForm(f => ({ ...f, descriptionAm: e.target.value }))} rows={2} placeholder="የዜማ ዝርዝር…" />
                                <Input label="Audio URL (Amharic)" value={form.audioAmUrl || ''} onChange={e => setForm(f => ({ ...f, audioAmUrl: e.target.value }))} placeholder="https://…/audio-am.mp3" />
                                <TextArea label="Benefits (አማርኛ)" value={form.benefitsAm || ''} onChange={e => setForm(f => ({ ...f, benefitsAm: e.target.value }))} rows={2} placeholder="ጥቅሞች…" />
                            </div>
                        )}
                        {/* OM */}
                        {activeLang === 'om' && (
                            <div className="space-y-4 p-4 bg-green-50 rounded-xl border border-green-100">
                                <Input label="Title (Afaan Oromo)" value={form.titleOm || ''} onChange={e => setForm(f => ({ ...f, titleOm: e.target.value }))} placeholder="Sagalee Uamaa Sagantaa" />
                                <TextArea label="Description (Afaan Oromo)" value={form.descriptionOm || ''} onChange={e => setForm(f => ({ ...f, descriptionOm: e.target.value }))} rows={2} placeholder="Ibsa muziiqaa…" />
                                <Input label="Audio URL (Oromo)" value={form.audioOmUrl || ''} onChange={e => setForm(f => ({ ...f, audioOmUrl: e.target.value }))} placeholder="https://…/audio-om.mp3" />
                                <TextArea label="Benefits (Afaan Oromo)" value={form.benefitsOm || ''} onChange={e => setForm(f => ({ ...f, benefitsOm: e.target.value }))} rows={2} placeholder="Faayidaalee…" />
                            </div>
                        )}
                        {/* SO */}
                        {activeLang === 'so' && (
                            <div className="space-y-4 p-4 bg-pink-50 rounded-xl border border-pink-100">
                                <Input label="Title (Af-Soomaali)" value={form.titleSo || ''} onChange={e => setForm(f => ({ ...f, titleSo: e.target.value }))} placeholder="Dhawaa Dabiiciga Ah" />
                                <TextArea label="Description (Af-Soomaali)" value={form.descriptionSo || ''} onChange={e => setForm(f => ({ ...f, descriptionSo: e.target.value }))} rows={2} placeholder="Faahfaahinta muusikada…" />
                                <Input label="Audio URL (Somali)" value={form.audioSoUrl || ''} onChange={e => setForm(f => ({ ...f, audioSoUrl: e.target.value }))} placeholder="https://…/audio-so.mp3" />
                                <TextArea label="Benefits (Af-Soomaali)" value={form.benefitsSo || ''} onChange={e => setForm(f => ({ ...f, benefitsSo: e.target.value }))} rows={2} placeholder="Faaiidooyinka…" />
                            </div>
                        )}
                    </div>

                    {/* Toggles */}
                    <div className="flex gap-6">
                        <label className="flex items-center gap-3 cursor-pointer">
                            <div
                                onClick={() => setForm(f => ({ ...f, isActive: !f.isActive }))}
                                className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${form.isActive ? 'bg-[#61183e]' : 'bg-gray-300'}`}
                            >
                                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${form.isActive ? 'left-6' : 'left-1'}`} />
                            </div>
                            <span className="text-sm font-medium text-gray-700">Active</span>
                        </label>
                        <label className="flex items-center gap-3 cursor-pointer">
                            <div
                                onClick={() => setForm(f => ({ ...f, isFeatured: !f.isFeatured }))}
                                className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${form.isFeatured ? 'bg-amber-500' : 'bg-gray-300'}`}
                            >
                                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${form.isFeatured ? 'left-6' : 'left-1'}`} />
                            </div>
                            <span className="text-sm font-medium text-gray-700">⭐ Featured</span>
                        </label>
                    </div>

                    {/* Actions */}
                    <div className="flex justify-end gap-3 pt-2 border-t border-gray-100">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave} disabled={saving}>
                            {saving ? 'Saving…' : editing ? 'Save Changes' : 'Add Track'}
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
