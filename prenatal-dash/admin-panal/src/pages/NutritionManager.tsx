import { useState, useEffect, useCallback } from 'react';
import {
    Plus, Edit2, Trash2, Eye, EyeOff, Search, Loader2,
    ChevronDown, ChevronUp, X, PlusCircle
} from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea, Select } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

export interface FoodItem {
    name: string;
    name_am?: string;
    name_latin?: string;
    image_url?: string;
    benefit?: string;
    benefit_label?: string;
    why_include?: string;
    tip?: string;
}

export interface NutrientSection {
    type: string;
    emoji: string;
    description: string;
    foods: FoodItem[];
    video_url?: string;
    video_title?: string;
}

export interface NutritionEntry {
    id: string | number;
    // Core
    titleAm: string;
    titleOr: string;
    titleEn?: string;
    trimester: string;
    week?: string | number | null;
    // Classification
    type: 'eat' | 'avoid';
    emoji: string;
    nutrientType?: string;
    // Body content
    bodyAm: string;
    bodyOr: string;
    bodyEn?: string;
    // Media
    imageUrl?: string;
    videoUrl?: string;
    videoTitle?: string;
    // Avoid reason
    reasonAm?: string;
    reasonOr?: string;
    reasonEn?: string;
    // Rich structure
    foods?: FoodItem[];
    foodsJson?: FoodItem[];
    nutrientSections?: NutrientSection[];
    nutrientSectionsJson?: NutrientSection[];
    // Status
    published?: boolean;
    isPublished?: boolean;
}

const emptyFood = (): FoodItem => ({
    name: '', name_am: '', name_latin: '',
    image_url: '', benefit: '', benefit_label: '', why_include: '', tip: '',
});

const emptySection = (): NutrientSection => ({
    type: '', emoji: '🥗', description: '',
    foods: [emptyFood()],
    video_url: '', video_title: '',
});

const emptyForm = (): Omit<NutritionEntry, 'id'> => ({
    titleAm: '', titleOr: '', titleEn: '',
    trimester: '1st', week: '',
    type: 'eat', emoji: '🥗', nutrientType: '',
    bodyAm: '', bodyOr: '', bodyEn: '',
    imageUrl: '', videoUrl: '', videoTitle: '',
    reasonAm: '', reasonOr: '', reasonEn: '',
    foods: [emptyFood()],
    nutrientSections: [emptySection()],
    published: false, isPublished: false,
});

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const TRIMESTER_OPTS = [
    { value: '1st', label: '1st Trimester' },
    { value: '2nd', label: '2nd Trimester' },
    { value: '3rd', label: '3rd Trimester' },
];

const TYPE_OPTS = [
    { value: 'eat', label: '✅ What to Eat' },
    { value: 'avoid', label: '🚫 What NOT to Eat' },
];

const WEEK_OPTS = [{ value: '', label: 'Any week' }, ...Array.from({ length: 40 }, (_, i) => ({
    value: String(i + 1), label: `Week ${i + 1}`,
}))];

const EMOJI_LIST = ['🥗','🥛','🥩','🐟','🥦','🥕','🍊','🍋','🫐','🥑','🥚','🌾','🫘','🥜','🫚','🚫','⚠️'];

// ─────────────────────────────────────────────────────────────────────────────
// Main Component
// ─────────────────────────────────────────────────────────────────────────────

export default function NutritionManager() {
    const { showToast } = useToast();
    const [entries, setEntries] = useState<NutritionEntry[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterTrimester, setFilterTrimester] = useState('All');
    const [filterType, setFilterType] = useState('All');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<NutritionEntry | null>(null);
    const [form, setForm] = useState<Omit<NutritionEntry, 'id'>>(emptyForm());
    const [saving, setSaving] = useState(false);
    const [expandedSections, setExpandedSections] = useState<number[]>([0]);

    // ── Data loading ────────────────────────────────────────────────────

    const fetchEntries = useCallback(async (search: string, trimester: string, type: string) => {
        try {
            setLoading(true);
            const params: any = {};
            if (search.trim()) params.search = search.trim();
            if (trimester !== 'All') params.trimester = trimester;
            if (type !== 'All') params.type = type;

            const res = await cmsClient.list<NutritionEntry>('nutrition', params);
            setEntries(res.items);
        } catch (err: any) {
            showToast(err.message || 'Failed to load nutrition entries', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        const timer = setTimeout(() => fetchEntries(searchTerm, filterTrimester, filterType), 250);
        return () => clearTimeout(timer);
    }, [searchTerm, filterTrimester, filterType, fetchEntries]);

    const refresh = () => fetchEntries(searchTerm, filterTrimester, filterType);

    // ── Modal helpers ───────────────────────────────────────────────────

    function openCreate() {
        setEditing(null);
        setForm(emptyForm());
        setExpandedSections([0]);
        setModalOpen(true);
    }

    function openEdit(e: NutritionEntry) {
        setEditing(e);
        const sections: NutrientSection[] = (e.nutrientSections ?? e.nutrientSectionsJson ?? [emptySection()]);
        const foods: FoodItem[] = (e.foods ?? e.foodsJson ?? [emptyFood()]);
        setForm({
            titleAm: e.titleAm || '',
            titleOr: e.titleOr || '',
            titleEn: e.titleEn || '',
            trimester: e.trimester || '1st',
            week: e.week ?? '',
            type: e.type ?? 'eat',
            emoji: e.emoji || '🥗',
            nutrientType: e.nutrientType || '',
            bodyAm: e.bodyAm || '',
            bodyOr: e.bodyOr || '',
            bodyEn: e.bodyEn || '',
            imageUrl: e.imageUrl || '',
            videoUrl: e.videoUrl || '',
            videoTitle: e.videoTitle || '',
            reasonAm: e.reasonAm || '',
            reasonOr: e.reasonOr || '',
            reasonEn: e.reasonEn || '',
            foods: foods.length > 0 ? foods : [emptyFood()],
            nutrientSections: sections.length > 0 ? sections : [emptySection()],
            published: e.published ?? e.isPublished ?? false,
            isPublished: e.published ?? e.isPublished ?? false,
        });
        setExpandedSections([0]);
        setModalOpen(true);
    }

    // ── CRUD ────────────────────────────────────────────────────────────

    async function handleDelete(id: string | number) {
        if (!window.confirm('Delete this nutrition entry?')) return;
        try {
            await cmsClient.delete('nutrition', id);
            showToast('Nutrition entry deleted.', 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete entry.', 'error');
        }
    }

    async function togglePublish(entry: NutritionEntry) {
        const current = Boolean(entry.published ?? entry.isPublished);
        try {
            await cmsClient.togglePublish('nutrition', entry.id, current);
            showToast(`Entry ${!current ? 'published' : 'moved to drafts'}.`, 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to toggle visibility.', 'error');
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
                week: form.week || null,
                type: form.type,
                emoji: form.emoji,
                nutrientType: form.nutrientType,
                bodyAm: form.bodyAm,
                bodyOr: form.bodyOr,
                bodyEn: form.bodyEn,
                imageUrl: form.imageUrl,
                videoUrl: form.videoUrl,
                videoTitle: form.videoTitle,
                reasonAm: form.reasonAm,
                reasonOr: form.reasonOr,
                reasonEn: form.reasonEn,
                foodsJson: form.foods,
                nutrientSectionsJson: form.nutrientSections,
                isPublished: Boolean(form.published ?? form.isPublished),
            };

            if (editing) {
                await cmsClient.update('nutrition', editing.id, payload);
                showToast('Nutrition entry updated!', 'success');
            } else {
                await cmsClient.create('nutrition', payload);
                showToast('Nutrition entry created!', 'success');
            }
            setModalOpen(false);
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to save entry.', 'error');
        } finally {
            setSaving(false);
        }
    }

    // ── Nutrient sections helpers ────────────────────────────────────────

    function updateSection(i: number, patch: Partial<NutrientSection>) {
        setForm(f => {
            const secs = [...(f.nutrientSections || [])];
            secs[i] = { ...secs[i], ...patch };
            return { ...f, nutrientSections: secs };
        });
    }

    function addSection() {
        setForm(f => ({ ...f, nutrientSections: [...(f.nutrientSections || []), emptySection()] }));
        setExpandedSections(prev => [...prev, (form.nutrientSections || []).length]);
    }

    function removeSection(i: number) {
        setForm(f => {
            const secs = [...(f.nutrientSections || [])];
            secs.splice(i, 1);
            return { ...f, nutrientSections: secs };
        });
    }

    function updateFood(secIdx: number, foodIdx: number, patch: Partial<FoodItem>) {
        setForm(f => {
            const secs = [...(f.nutrientSections || [])];
            const foods = [...(secs[secIdx]?.foods || [])];
            foods[foodIdx] = { ...foods[foodIdx], ...patch };
            secs[secIdx] = { ...secs[secIdx], foods };
            return { ...f, nutrientSections: secs };
        });
    }

    function addFood(secIdx: number) {
        setForm(f => {
            const secs = [...(f.nutrientSections || [])];
            secs[secIdx] = { ...secs[secIdx], foods: [...(secs[secIdx].foods || []), emptyFood()] };
            return { ...f, nutrientSections: secs };
        });
    }

    function removeFood(secIdx: number, foodIdx: number) {
        setForm(f => {
            const secs = [...(f.nutrientSections || [])];
            const foods = [...(secs[secIdx]?.foods || [])];
            foods.splice(foodIdx, 1);
            secs[secIdx] = { ...secs[secIdx], foods };
            return { ...f, nutrientSections: secs };
        });
    }

    const toggleSection = (i: number) =>
        setExpandedSections(prev => prev.includes(i) ? prev.filter(x => x !== i) : [...prev, i]);

    const isPub = (e: NutritionEntry) => Boolean(e.published ?? e.isPublished);

    // ─────────────────────────────────────────────────────────────────────
    // Render
    // ─────────────────────────────────────────────────────────────────────

    return (
        <div className="space-y-6">

            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Nutrition Guide</h2>
                    <p className="text-gray-500 text-sm mt-0.5">
                        Manage nutrient entries — What to Eat &amp; What NOT to Eat
                    </p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Entry</Button>
            </div>

            {/* Filters */}
            <div className="flex flex-col sm:flex-row gap-3 bg-white p-3 rounded-2xl border border-gray-100 shadow-sm flex-wrap">
                <div className="relative flex-1 min-w-[220px]">
                    <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Search nutrition by title, nutrient type..."
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
                        className="text-sm border border-gray-200 rounded-xl px-3 py-2 bg-white focus:outline-none focus:border-[#61183e]"
                    >
                        <option value="All">All</option>
                        <option value="1st">1st</option>
                        <option value="2nd">2nd</option>
                        <option value="3rd">3rd</option>
                    </select>
                </div>
                <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-gray-500 uppercase">Type:</span>
                    <select
                        value={filterType}
                        onChange={e => setFilterType(e.target.value)}
                        className="text-sm border border-gray-200 rounded-xl px-3 py-2 bg-white focus:outline-none focus:border-[#61183e]"
                    >
                        <option value="All">All</option>
                        <option value="eat">✅ Eat</option>
                        <option value="avoid">🚫 Avoid</option>
                    </select>
                </div>
            </div>

            {/* List */}
            {loading ? (
                <div className="flex flex-col items-center justify-center p-12 text-gray-400">
                    <Loader2 className="w-8 h-8 animate-spin text-[#61183e] mb-2" />
                    <p className="text-sm font-medium">Loading nutrition entries...</p>
                </div>
            ) : entries.length === 0 ? (
                <div className="text-center p-12 bg-white rounded-2xl border border-gray-100">
                    <p className="text-gray-500 text-sm">No nutrition entries found.</p>
                </div>
            ) : (
                <div className="grid gap-4">
                    {entries.map(entry => (
                        <Card key={entry.id} className="flex items-start justify-between gap-4">
                            <div className="flex-1">
                                <div className="flex items-center gap-2 mb-2 flex-wrap">
                                    <span className="text-xl">{entry.emoji || '🥗'}</span>
                                    <h4 className="font-semibold text-gray-900">
                                        {entry.titleAm || entry.titleEn}
                                    </h4>
                                    {entry.titleOr && (
                                        <span className="text-gray-400 text-sm">/ {entry.titleOr}</span>
                                    )}
                                    <Badge variant={isPub(entry) ? 'green' : 'gray'}>
                                        {isPub(entry) ? 'Published' : 'Draft'}
                                    </Badge>
                                    <Badge variant={entry.type === 'avoid' ? 'red' : 'green'}>
                                        {entry.type === 'avoid' ? '🚫 Avoid' : '✅ Eat'}
                                    </Badge>
                                    <Badge variant="pink">{entry.trimester} Trimester</Badge>
                                    {entry.week && <Badge variant="yellow">Week {entry.week}</Badge>}
                                    {entry.nutrientType && (
                                        <Badge variant="blue">{entry.nutrientType}</Badge>
                                    )}
                                </div>
                                <p className="text-sm text-gray-600 line-clamp-2">
                                    {entry.bodyAm || entry.bodyEn}
                                </p>
                                {entry.bodyOr && (
                                    <p className="text-xs text-gray-400 mt-1 line-clamp-1 italic">{entry.bodyOr}</p>
                                )}
                                {/* Nutrient sections summary */}
                                {(entry.nutrientSections || entry.nutrientSectionsJson || []).length > 0 && (
                                    <div className="flex gap-1 flex-wrap mt-2">
                                        {(entry.nutrientSections ?? entry.nutrientSectionsJson ?? []).map((s, i) => (
                                            <span key={i} className="text-xs bg-[#fdf2f8] text-[#61183e] px-2 py-0.5 rounded-full font-medium">
                                                {s.emoji} {s.type}
                                            </span>
                                        ))}
                                    </div>
                                )}
                                {(entry.videoUrl || entry.imageUrl) && (
                                    <p className="text-xs text-[#61183e] font-medium mt-2 font-mono truncate">
                                        Media: {entry.videoUrl || entry.imageUrl}
                                    </p>
                                )}
                            </div>
                            <div className="flex gap-2 shrink-0">
                                <button
                                    onClick={() => togglePublish(entry)}
                                    className="p-2 rounded-lg hover:bg-[#fdf2f8] text-[#61183e] transition-colors"
                                    title={isPub(entry) ? 'Unpublish' : 'Publish'}
                                >
                                    {isPub(entry) ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
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
                    ))}
                </div>
            )}

            {/* ── Create / Edit Modal ─────────────────────────────────────────── */}
            <Modal
                isOpen={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Edit Nutrition Entry' : 'New Nutrition Entry'}
                size="xl"
            >
                <div className="space-y-6 max-h-[80vh] overflow-y-auto pr-1">

                    {/* ── Section A: Classification ────────────────────────────── */}
                    <FormSection title="📋 Classification">
                        <div className="grid grid-cols-2 gap-4">
                            <Select
                                label="Type"
                                value={form.type}
                                onChange={e => setForm(f => ({ ...f, type: e.target.value as 'eat' | 'avoid' }))}
                                options={TYPE_OPTS}
                            />
                            <Select
                                label="Trimester"
                                value={form.trimester}
                                onChange={e => setForm(f => ({ ...f, trimester: e.target.value }))}
                                options={TRIMESTER_OPTS}
                            />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                            <Select
                                label="Specific Week (optional)"
                                value={String(form.week ?? '')}
                                onChange={e => setForm(f => ({ ...f, week: e.target.value }))}
                                options={WEEK_OPTS}
                            />
                            <Input
                                label="Nutrient Type (e.g. Calcium, Iron)"
                                value={form.nutrientType || ''}
                                onChange={e => setForm(f => ({ ...f, nutrientType: e.target.value }))}
                                placeholder="CALCIUM"
                            />
                        </div>
                        {/* Emoji picker */}
                        <div>
                            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Emoji</p>
                            <div className="flex gap-2 flex-wrap">
                                {EMOJI_LIST.map(em => (
                                    <button
                                        key={em}
                                        type="button"
                                        onClick={() => setForm(f => ({ ...f, emoji: em }))}
                                        className={`w-9 h-9 rounded-lg text-lg flex items-center justify-center border-2 transition-all ${form.emoji === em ? 'border-[#61183e] bg-[#fdf2f8]' : 'border-transparent hover:border-gray-200'}`}
                                    >
                                        {em}
                                    </button>
                                ))}
                                <input
                                    type="text"
                                    value={form.emoji}
                                    onChange={e => setForm(f => ({ ...f, emoji: e.target.value }))}
                                    className="w-16 h-9 border border-gray-200 rounded-lg text-center text-lg focus:outline-none focus:border-[#61183e]"
                                    maxLength={4}
                                    placeholder="✏️"
                                />
                            </div>
                        </div>
                    </FormSection>

                    {/* ── Section B: Titles ────────────────────────────────────── */}
                    <FormSection title="🌍 Titles">
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <p className="text-xs font-semibold text-gray-500 uppercase mb-1">🇪🇹 Amharic</p>
                                <Input
                                    label="Title (Amharic)"
                                    value={form.titleAm}
                                    onChange={e => setForm(f => ({ ...f, titleAm: e.target.value }))}
                                    placeholder="አርዕስት..."
                                />
                            </div>
                            <div>
                                <p className="text-xs font-semibold text-gray-500 uppercase mb-1">🟢 Afan Oromo</p>
                                <Input
                                    label="Title (Afan Oromo)"
                                    value={form.titleOr}
                                    onChange={e => setForm(f => ({ ...f, titleOr: e.target.value }))}
                                    placeholder="Mata duree..."
                                />
                            </div>
                        </div>
                        <Input
                            label="Title (English)"
                            value={form.titleEn || ''}
                            onChange={e => setForm(f => ({ ...f, titleEn: e.target.value }))}
                            placeholder="Title in English..."
                        />
                    </FormSection>

                    {/* ── Section C: Body Description ──────────────────────────── */}
                    <FormSection title="📝 Body Description">
                        <div className="grid grid-cols-2 gap-4">
                            <TextArea
                                label="Body (Amharic)"
                                value={form.bodyAm}
                                onChange={e => setForm(f => ({ ...f, bodyAm: e.target.value }))}
                                rows={3}
                                placeholder="ዝርዝር መረጃ..."
                            />
                            <TextArea
                                label="Body (Afan Oromo)"
                                value={form.bodyOr}
                                onChange={e => setForm(f => ({ ...f, bodyOr: e.target.value }))}
                                rows={3}
                                placeholder="Odeeffannoo..."
                            />
                        </div>
                        <TextArea
                            label="Body (English)"
                            value={form.bodyEn || ''}
                            onChange={e => setForm(f => ({ ...f, bodyEn: e.target.value }))}
                            rows={3}
                            placeholder="Nutritional description in English..."
                        />
                    </FormSection>

                    {/* ── Section D: Avoid Reason (only for 'avoid' type) ─────── */}
                    {form.type === 'avoid' && (
                        <FormSection title="⚠️ Why to Avoid (Reason)">
                            <div className="grid grid-cols-2 gap-4">
                                <TextArea
                                    label="Reason (Amharic)"
                                    value={form.reasonAm || ''}
                                    onChange={e => setForm(f => ({ ...f, reasonAm: e.target.value }))}
                                    rows={3}
                                    placeholder="ምክንያት..."
                                />
                                <TextArea
                                    label="Reason (Afan Oromo)"
                                    value={form.reasonOr || ''}
                                    onChange={e => setForm(f => ({ ...f, reasonOr: e.target.value }))}
                                    rows={3}
                                    placeholder="Sababii..."
                                />
                            </div>
                            <TextArea
                                label="Reason (English)"
                                value={form.reasonEn || ''}
                                onChange={e => setForm(f => ({ ...f, reasonEn: e.target.value }))}
                                rows={3}
                                placeholder="Why mothers should avoid this during pregnancy..."
                            />
                        </FormSection>
                    )}

                    {/* ── Section E: Media ─────────────────────────────────────── */}
                    <FormSection title="🖼️ Media">
                        <div className="grid grid-cols-2 gap-4">
                            <Input
                                label="Thumbnail / Image URL"
                                value={form.imageUrl || ''}
                                onChange={e => setForm(f => ({ ...f, imageUrl: e.target.value }))}
                                placeholder="https://..."
                            />
                            <Input
                                label="Video URL"
                                value={form.videoUrl || ''}
                                onChange={e => setForm(f => ({ ...f, videoUrl: e.target.value }))}
                                placeholder="https://youtube.com/..."
                            />
                        </div>
                        <Input
                            label="Video Title (shown on Video tab)"
                            value={form.videoTitle || ''}
                            onChange={e => setForm(f => ({ ...f, videoTitle: e.target.value }))}
                            placeholder="e.g. Iron-Rich Foods in Pregnancy"
                        />
                    </FormSection>

                    {/* ── Section F: Nutrient Sections (🥛 CALCIUM, etc.) ──────── */}
                    <FormSection title="🧬 Nutrient Sections">
                        <p className="text-xs text-gray-500 mb-3">
                            Each section represents one nutrient type (e.g. 🥛 CALCIUM) with its own food list and video.
                        </p>
                        <div className="space-y-3">
                            {(form.nutrientSections || []).map((sec, si) => (
                                <NutrientSectionEditor
                                    key={si}
                                    index={si}
                                    section={sec}
                                    expanded={expandedSections.includes(si)}
                                    onToggle={() => toggleSection(si)}
                                    onUpdate={patch => updateSection(si, patch)}
                                    onRemove={() => removeSection(si)}
                                    onAddFood={() => addFood(si)}
                                    onUpdateFood={(fi, patch) => updateFood(si, fi, patch)}
                                    onRemoveFood={fi => removeFood(si, fi)}
                                />
                            ))}
                        </div>
                        <button
                            type="button"
                            onClick={addSection}
                            className="flex items-center gap-2 text-sm text-[#61183e] font-medium mt-2 hover:underline"
                        >
                            <PlusCircle className="w-4 h-4" /> Add Nutrient Section
                        </button>
                    </FormSection>

                    {/* ── Publish toggle ───────────────────────────────────────── */}
                    <div className="flex items-center gap-3 p-4 bg-[#fdf2f8] rounded-xl">
                        <label className="flex items-center gap-3 cursor-pointer">
                            <div
                                onClick={() => setForm(f => {
                                    const next = !(f.published ?? f.isPublished);
                                    return { ...f, published: next, isPublished: next };
                                })}
                                className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${(form.published ?? form.isPublished) ? 'bg-[#61183e]' : 'bg-gray-300'}`}
                            >
                                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${(form.published ?? form.isPublished) ? 'left-6' : 'left-1'}`} />
                            </div>
                            <span className="font-medium text-gray-800 text-sm">
                                {(form.published ?? form.isPublished)
                                    ? 'Published — visible to mothers on mobile app'
                                    : 'Draft — not visible to mothers'}
                            </span>
                        </label>
                    </div>

                    {/* Actions */}
                    <div className="flex justify-end gap-3 pt-2 border-t border-gray-100">
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

// ─────────────────────────────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────────────────────────────

function FormSection({ title, children }: { title: string; children: React.ReactNode }) {
    return (
        <div className="space-y-4">
            <h3 className="text-sm font-bold text-gray-700 border-b border-gray-100 pb-2">{title}</h3>
            {children}
        </div>
    );
}

interface NutrientSectionEditorProps {
    index: number;
    section: NutrientSection;
    expanded: boolean;
    onToggle: () => void;
    onUpdate: (patch: Partial<NutrientSection>) => void;
    onRemove: () => void;
    onAddFood: () => void;
    onUpdateFood: (foodIdx: number, patch: Partial<FoodItem>) => void;
    onRemoveFood: (foodIdx: number) => void;
}

function NutrientSectionEditor({
    index, section, expanded, onToggle, onUpdate,
    onRemove, onAddFood, onUpdateFood, onRemoveFood,
}: NutrientSectionEditorProps) {
    return (
        <div className="border border-gray-200 rounded-xl overflow-hidden">
            {/* Header */}
            <div
                className="flex items-center justify-between px-4 py-3 bg-gray-50 cursor-pointer hover:bg-gray-100 transition-colors"
                onClick={onToggle}
            >
                <div className="flex items-center gap-2">
                    <span className="text-lg">{section.emoji || '🌿'}</span>
                    <span className="font-semibold text-sm text-gray-800">
                        {section.type || `Section ${index + 1}`}
                    </span>
                    <span className="text-xs text-gray-400">({section.foods?.length || 0} foods)</span>
                </div>
                <div className="flex items-center gap-2">
                    <button
                        type="button"
                        onClick={e => { e.stopPropagation(); onRemove(); }}
                        className="p-1 text-red-400 hover:text-red-600 rounded"
                        title="Remove section"
                    >
                        <X className="w-3.5 h-3.5" />
                    </button>
                    {expanded ? <ChevronUp className="w-4 h-4 text-gray-400" /> : <ChevronDown className="w-4 h-4 text-gray-400" />}
                </div>
            </div>

            {/* Body */}
            {expanded && (
                <div className="p-4 space-y-4">
                    <div className="grid grid-cols-2 gap-3">
                        <Input
                            label="Nutrient Type Label (e.g. CALCIUM)"
                            value={section.type}
                            onChange={e => onUpdate({ type: e.target.value })}
                            placeholder="IRON"
                        />
                        <div>
                            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Emoji</p>
                            <input
                                type="text"
                                value={section.emoji}
                                onChange={e => onUpdate({ emoji: e.target.value })}
                                className="w-full border border-gray-200 rounded-lg px-3 py-2 text-lg text-center focus:outline-none focus:border-[#61183e]"
                                maxLength={4}
                                placeholder="🥛"
                            />
                        </div>
                    </div>
                    <Input
                        label="Short Description (shown under nutrient label)"
                        value={section.description}
                        onChange={e => onUpdate({ description: e.target.value })}
                        placeholder="Essential for bone development"
                    />
                    <div className="grid grid-cols-2 gap-3">
                        <Input
                            label="Video URL for this section"
                            value={section.video_url || ''}
                            onChange={e => onUpdate({ video_url: e.target.value })}
                            placeholder="https://youtube.com/..."
                        />
                        <Input
                            label="Video Title"
                            value={section.video_title || ''}
                            onChange={e => onUpdate({ video_title: e.target.value })}
                            placeholder="Calcium in Pregnancy"
                        />
                    </div>

                    {/* Food Items */}
                    <div>
                        <p className="text-xs font-bold text-gray-600 uppercase tracking-wide mb-2">
                            Food Items
                        </p>
                        <div className="space-y-3">
                            {(section.foods || []).map((food, fi) => (
                                <FoodItemEditor
                                    key={fi}
                                    food={food}
                                    index={fi}
                                    onUpdate={patch => onUpdateFood(fi, patch)}
                                    onRemove={() => onRemoveFood(fi)}
                                />
                            ))}
                        </div>
                        <button
                            type="button"
                            onClick={onAddFood}
                            className="flex items-center gap-1.5 text-xs text-[#61183e] font-medium mt-2 hover:underline"
                        >
                            <Plus className="w-3.5 h-3.5" /> Add Food Item
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}

function FoodItemEditor({
    food, index, onUpdate, onRemove,
}: {
    food: FoodItem;
    index: number;
    onUpdate: (patch: Partial<FoodItem>) => void;
    onRemove: () => void;
}) {
    const [open, setOpen] = useState(index === 0);

    return (
        <div className="border border-dashed border-gray-200 rounded-lg overflow-hidden">
            <div
                className="flex items-center justify-between px-3 py-2 bg-gray-50 cursor-pointer"
                onClick={() => setOpen(o => !o)}
            >
                <span className="text-sm font-medium text-gray-700">
                    {food.name || `Food ${index + 1}`}
                </span>
                <div className="flex items-center gap-1">
                    <button
                        type="button"
                        onClick={e => { e.stopPropagation(); onRemove(); }}
                        className="p-0.5 text-red-400 hover:text-red-600"
                    >
                        <X className="w-3 h-3" />
                    </button>
                    {open ? <ChevronUp className="w-3.5 h-3.5 text-gray-400" /> : <ChevronDown className="w-3.5 h-3.5 text-gray-400" />}
                </div>
            </div>
            {open && (
                <div className="p-3 grid grid-cols-2 gap-3">
                    <Input
                        label="Name (English)"
                        value={food.name}
                        onChange={e => onUpdate({ name: e.target.value })}
                        placeholder="Lentils"
                    />
                    <Input
                        label="Name (Amharic — ምስር)"
                        value={food.name_am || ''}
                        onChange={e => onUpdate({ name_am: e.target.value })}
                        placeholder="ምስር"
                    />
                    <Input
                        label="Transliteration (Misir)"
                        value={food.name_latin || ''}
                        onChange={e => onUpdate({ name_latin: e.target.value })}
                        placeholder="Misir"
                    />
                    <Input
                        label="Image URL"
                        value={food.image_url || ''}
                        onChange={e => onUpdate({ image_url: e.target.value })}
                        placeholder="https://..."
                    />
                    <Input
                        label="Benefit Label (e.g. Good source of)"
                        value={food.benefit_label || ''}
                        onChange={e => onUpdate({ benefit_label: e.target.value })}
                        placeholder="Good source of"
                    />
                    <Input
                        label="Benefit Value (e.g. Plant-based iron)"
                        value={food.benefit || ''}
                        onChange={e => onUpdate({ benefit: e.target.value })}
                        placeholder="Plant-based iron & protein"
                    />
                    <div className="col-span-2">
                        <TextArea
                            label="Why include / Why avoid it?"
                            value={food.why_include || ''}
                            onChange={e => onUpdate({ why_include: e.target.value })}
                            rows={2}
                            placeholder="Lentils can contribute protein, iron and fiber to a balanced pregnancy diet."
                        />
                    </div>
                    <div className="col-span-2">
                        <TextArea
                            label="💡 Helpful Tip"
                            value={food.tip || ''}
                            onChange={e => onUpdate({ tip: e.target.value })}
                            rows={2}
                            placeholder="Pair plant-based iron foods with Vitamin-C-rich food to help iron absorption."
                        />
                    </div>
                </div>
            )}
        </div>
    );
}
