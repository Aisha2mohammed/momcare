import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
    PlusCircle, Search, X, Calendar, Droplets, BookOpen,
    Edit2, Trash2, Eye, EyeOff, Loader2, CheckCircle2,
    Filter, AlertTriangle
} from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

// ─────────────────────────────────────────────────────────────────────────────
// Interfaces & Types
// ─────────────────────────────────────────────────────────────────────────────

export interface NutritionWeekEntry {
    id: string | number;
    week: number;
    trimester: string; // '1st' | '2nd' | '3rd'
    month: number;
    isPublished: boolean;

    // Why It Is Important (4 Languages)
    whyImportantEn: string;
    whyImportantAm: string;
    whyImportantOr: string;
    whyImportantSo: string;

    // Hydration Guidance (4 Languages)
    hydrationEn: string;
    hydrationAm: string;
    hydrationOr: string;
    hydrationSo: string;
}

interface BackendNutritionRow {
    id: string | number;
    week?: number | string | null;
    trimester?: number | string | null;

    why_important_en?: string; whyImportantEn?: string;
    why_important_am?: string; whyImportantAm?: string;
    why_important_or?: string; whyImportantOr?: string;
    why_important_so?: string; whyImportantSo?: string;

    hydration_en?: string; hydrationEn?: string;
    hydration_am?: string; hydrationAm?: string;
    hydration_or?: string; hydrationOr?: string;
    hydration_so?: string; hydrationSo?: string;

    is_published?: boolean; isPublished?: boolean;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

function calculateMonthAndTrimester(w: number) {
    let month = 1;
    let trimester = '1st';
    if (w <= 4) { month = 1; trimester = '1st'; }
    else if (w <= 8) { month = 2; trimester = '1st'; }
    else if (w <= 13) { month = 3; trimester = '1st'; }
    else if (w <= 17) { month = 4; trimester = '2nd'; }
    else if (w <= 21) { month = 5; trimester = '2nd'; }
    else if (w <= 26) { month = 6; trimester = '2nd'; }
    else if (w <= 30) { month = 7; trimester = '3rd'; }
    else if (w <= 35) { month = 8; trimester = '3rd'; }
    else { month = 9; trimester = '3rd'; }
    return { month, trimester };
}

const TRIMESTER_BADGE_STYLE: Record<string, string> = {
    '1st': 'bg-sky-50 text-sky-700 border-sky-200',
    '2nd': 'bg-purple-50 text-purple-700 border-purple-200',
    '3rd': 'bg-amber-50 text-amber-700 border-amber-200',
};

const EMPTY_WEEK_ENTRY: Omit<NutritionWeekEntry, 'id'> = {
    week: 18,
    trimester: '2nd',
    month: 5,
    isPublished: true,
    whyImportantEn: '',
    whyImportantAm: '',
    whyImportantOr: '',
    whyImportantSo: '',
    hydrationEn: '',
    hydrationAm: '',
    hydrationOr: '',
    hydrationSo: '',
};

// ─────────────────────────────────────────────────────────────────────────────
// Component
// ─────────────────────────────────────────────────────────────────────────────

export default function NutritionManager() {
    const { showToast } = useToast();

    // Data State
    const [rawRows, setRawRows] = useState<BackendNutritionRow[]>([]);
    const [loading, setLoading] = useState(true);

    // Filters
    const [filterTrimester, setFilterTrimester] = useState<string>('all');
    const [filterMonth, setFilterMonth] = useState<string>('all');
    const [filterWeek, setFilterWeek] = useState<string>('all');
    const [searchQuery, setSearchQuery] = useState<string>('');

    // Modals
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);

    // Active Entry for Add/Edit/Delete
    const [formData, setFormData] = useState<NutritionWeekEntry>({ id: '', ...EMPTY_WEEK_ENTRY });
    const [entryToDelete, setEntryToDelete] = useState<NutritionWeekEntry | null>(null);
    const [submitting, setSubmitting] = useState(false);

    // Success Modal Feedback
    const [successModal, setSuccessModal] = useState<{ open: boolean; title: string; message: string }>({
        open: false, title: '', message: ''
    });

    // Per-card active language tab for preview
    const [cardLang, setCardLang] = useState<Record<string, 'en' | 'or' | 'so' | 'am'>>({});

    // ── Load Data ─────────────────────────────────────────────────────────────
    const loadWeekGuidesData = useCallback(async () => {
        setLoading(true);
        try {
            const res = await cmsClient.list<BackendNutritionRow>('nutrition', { limit: 500 });
            setRawRows(res.items || []);
        } catch (err: any) {
            showToast(err.message || 'Failed to load nutrition weeks', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        loadWeekGuidesData();
    }, [loadWeekGuidesData]);

    // ── Process Rows into Week Entries List ───────────────────────────────────
    const weekEntriesList = useMemo(() => {
        return rawRows.map(row => {
            const weekNum = Number(row.week || 1);
            const { month, trimester } = calculateMonthAndTrimester(weekNum);
            const isPub = row.is_published ?? row.isPublished ?? true;

            return {
                id: row.id,
                week: weekNum,
                trimester: String(row.trimester || trimester),
                month,
                isPublished: isPub,

                whyImportantEn: row.why_important_en || row.whyImportantEn || '',
                whyImportantAm: row.why_important_am || row.whyImportantAm || '',
                whyImportantOr: row.why_important_or || row.whyImportantOr || '',
                whyImportantSo: row.why_important_so || row.whyImportantSo || '',

                hydrationEn: row.hydration_en || row.hydrationEn || '',
                hydrationAm: row.hydration_am || row.hydrationAm || '',
                hydrationOr: row.hydration_or || row.hydrationOr || '',
                hydrationSo: row.hydration_so || row.hydrationSo || '',
            } as NutritionWeekEntry;
        });
    }, [rawRows]);

    // ── Filtered Week Entries ────────────────────────────────────────────────
    const filteredEntries = useMemo(() => {
        return weekEntriesList.filter(item => {
            // Trimester Filter
            if (filterTrimester !== 'all') {
                const itemTri = String(item.trimester).toLowerCase();
                if (!itemTri.includes(filterTrimester.toLowerCase())) return false;
            }
            // Month Filter
            if (filterMonth !== 'all') {
                if (item.month !== Number(filterMonth)) return false;
            }
            // Week Filter
            if (filterWeek !== 'all') {
                if (item.week !== Number(filterWeek)) return false;
            }
            // Search Query
            if (searchQuery.trim()) {
                const q = searchQuery.toLowerCase().trim();
                const match = (
                    `week ${item.week}`.includes(q) ||
                    `month ${item.month}`.includes(q) ||
                    item.whyImportantEn.toLowerCase().includes(q) ||
                    item.whyImportantAm.toLowerCase().includes(q) ||
                    item.whyImportantOr.toLowerCase().includes(q) ||
                    item.whyImportantSo.toLowerCase().includes(q) ||
                    item.hydrationEn.toLowerCase().includes(q) ||
                    item.hydrationAm.toLowerCase().includes(q)
                );
                if (!match) return false;
            }
            return true;
        });
    }, [weekEntriesList, filterTrimester, filterMonth, filterWeek, searchQuery]);

    // ── Modal Form Handlers ──────────────────────────────────────────────────
    const handleOpenAddModal = () => {
        setFormData({
            id: '',
            ...EMPTY_WEEK_ENTRY,
        });
        setIsAddModalOpen(true);
    };

    const handleOpenEditModal = (entry: NutritionWeekEntry) => {
        setFormData({ ...entry });
        setIsEditModalOpen(true);
    };

    const handleOpenDeleteModal = (entry: NutritionWeekEntry) => {
        setEntryToDelete(entry);
        setIsDeleteModalOpen(true);
    };

    const handleWeekChangeInForm = (wNum: number) => {
        const { month, trimester } = calculateMonthAndTrimester(wNum);
        setFormData(prev => ({
            ...prev,
            week: wNum,
            month,
            trimester,
        }));
    };

    // ── Save / Update Action ─────────────────────────────────────────────────
    const handleSaveWeekGuide = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            const payload = {
                week: formData.week,
                trimester: formData.trimester,
                whyImportantEn: formData.whyImportantEn,
                whyImportantAm: formData.whyImportantAm,
                whyImportantOr: formData.whyImportantOr,
                whyImportantSo: formData.whyImportantSo,
                hydrationEn: formData.hydrationEn,
                hydrationAm: formData.hydrationAm,
                hydrationOr: formData.hydrationOr,
                hydrationSo: formData.hydrationSo,
                isPublished: formData.isPublished,
            };

            if (isEditModalOpen && formData.id) {
                await cmsClient.update('nutrition', formData.id, payload);
                setIsEditModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Week Guide Updated!',
                    message: `Nutrition Guide for Week ${formData.week} updated successfully.`,
                });
            } else {
                await cmsClient.create('nutrition', payload);
                setIsAddModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Week Guide Created!',
                    message: `New Nutrition Guide for Week ${formData.week} created successfully.`,
                });
            }

            await loadWeekGuidesData();
        } catch (err: any) {
            showToast(err.message || 'Failed to save week guide', 'error');
        } finally {
            setSubmitting(false);
        }
    };

    // ── Delete Action ────────────────────────────────────────────────────────
    const handleDeleteConfirm = async () => {
        if (!entryToDelete) return;
        setSubmitting(true);
        try {
            await cmsClient.delete('nutrition', entryToDelete.id);
            setIsDeleteModalOpen(false);
            setSuccessModal({
                open: true,
                title: 'Week Guide Deleted',
                message: `Nutrition Guide for Week ${entryToDelete.week} has been removed.`,
            });
            setEntryToDelete(null);
            await loadWeekGuidesData();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete week guide', 'error');
        } finally {
            setSubmitting(false);
        }
    };

    // ── Toggle Publish Action ────────────────────────────────────────────────
    const handleTogglePublish = async (entry: NutritionWeekEntry) => {
        try {
            const newStatus = !entry.isPublished;
            await cmsClient.update('nutrition', entry.id, {
                isPublished: newStatus,
            });
            showToast(`Week ${entry.week} status updated to ${newStatus ? 'Published' : 'Draft'}`, 'success');
            await loadWeekGuidesData();
        } catch (err: any) {
            showToast(err.message || 'Failed to update status', 'error');
        }
    };

    // Card Language switcher helper
    const getActiveCardLang = (id: string | number) => cardLang[String(id)] || 'en';
    const setCardLanguage = (id: string | number, lang: 'en' | 'or' | 'so' | 'am') => {
        setCardLang(prev => ({ ...prev, [String(id)]: lang }));
    };

    // ─────────────────────────────────────────────────────────────────────────
    // RENDER
    // ─────────────────────────────────────────────────────────────────────────

    return (
        <div className="space-y-6 max-w-7xl mx-auto pb-12 px-2 sm:px-4">

            {/* HEADER BAR */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-gray-100 shadow-sm">
                <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#61183e] to-[#8a2259] text-white flex items-center justify-center shrink-0 shadow-md">
                        <Calendar className="w-6 h-6" />
                    </div>
                    <div>
                        <h1 className="text-xl font-bold text-gray-900 leading-tight">Nutrition Week Guides</h1>
                        <p className="text-xs text-gray-500">Manage weekly pregnancy guidance: Why it is important & Hydration details in 4 languages.</p>
                    </div>
                </div>

                <Button
                    onClick={handleOpenAddModal}
                    className="bg-[#61183e] hover:bg-[#4a122f] text-white font-semibold flex items-center gap-2 px-5 py-2.5 rounded-xl shadow-md transition-all hover:scale-[1.02]"
                >
                    <PlusCircle className="w-5 h-5" />
                    + Add Week Guide
                </Button>
            </div>

            {/* FILTER BAR CONTAINER */}
            <Card className="p-4 space-y-4 bg-white border border-gray-100 shadow-sm rounded-2xl">
                <div className="flex items-center gap-2 text-xs font-bold text-gray-700 uppercase tracking-wider">
                    <Filter className="w-4 h-4 text-[#61183e]" />
                    Filter Week Guides
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                    {/* Trimester Filter */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Trimester</label>
                        <select
                            value={filterTrimester}
                            onChange={e => setFilterTrimester(e.target.value)}
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
                        >
                            <option value="all">All Trimesters</option>
                            <option value="1st">1st Trimester (W1–W13)</option>
                            <option value="2nd">2nd Trimester (W14–W27)</option>
                            <option value="3rd">3rd Trimester (W28–W40)</option>
                        </select>
                    </div>

                    {/* Month Filter */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Month</label>
                        <select
                            value={filterMonth}
                            onChange={e => setFilterMonth(e.target.value)}
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
                        >
                            <option value="all">All Months (1–9)</option>
                            {Array.from({ length: 9 }, (_, i) => i + 1).map(m => (
                                <option key={m} value={m}>Month {m}</option>
                            ))}
                        </select>
                    </div>

                    {/* Week Filter */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Week</label>
                        <select
                            value={filterWeek}
                            onChange={e => setFilterWeek(e.target.value)}
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
                        >
                            <option value="all">All Weeks (1–40)</option>
                            {Array.from({ length: 40 }, (_, i) => i + 1).map(w => (
                                <option key={w} value={w}>Week {w}</option>
                            ))}
                        </select>
                    </div>

                    {/* Search Query */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Search</label>
                        <div className="relative">
                            <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                            <input
                                type="text"
                                placeholder="Search week guide..."
                                value={searchQuery}
                                onChange={e => setSearchQuery(e.target.value)}
                                className="w-full pl-8 pr-3 py-2 text-xs border border-gray-200 rounded-xl focus:outline-none focus:border-[#61183e]"
                            />
                            {searchQuery && (
                                <button onClick={() => setSearchQuery('')} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                                    <X className="w-3.5 h-3.5" />
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            </Card>

            {/* WEEK GUIDES CONTAINER LIST */}
            {loading ? (
                <div className="flex flex-col items-center justify-center py-16 bg-white rounded-2xl border border-gray-100 shadow-sm space-y-3">
                    <Loader2 className="w-8 h-8 text-[#61183e] animate-spin" />
                    <p className="text-sm font-medium text-gray-500">Loading week guides...</p>
                </div>
            ) : filteredEntries.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-16 bg-white rounded-2xl border border-gray-100 shadow-sm text-center space-y-3 p-6">
                    <div className="w-14 h-14 rounded-full bg-pink-50 flex items-center justify-center text-[#61183e]">
                        <Calendar className="w-7 h-7" />
                    </div>
                    <h3 className="text-base font-bold text-gray-800">No Week Guides Found</h3>
                    <p className="text-xs text-gray-400 max-w-sm">No week guide matches your filter criteria. Add a new week guide to get started.</p>
                    <Button onClick={handleOpenAddModal} className="bg-[#61183e] text-white text-xs px-4 py-2 rounded-xl">
                        + Add Week Guide Now
                    </Button>
                </div>
            ) : (
                <div className="space-y-4">
                    <div className="flex items-center justify-between text-xs text-gray-500 px-1 font-medium">
                        <span>Showing {filteredEntries.length} week guide container(s)</span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {filteredEntries.map((item) => {
                            const lang = getActiveCardLang(item.id);
                            const whyImp = lang === 'am' ? item.whyImportantAm : lang === 'or' ? item.whyImportantOr : lang === 'so' ? item.whyImportantSo : item.whyImportantEn;
                            const hydration = lang === 'am' ? item.hydrationAm : lang === 'or' ? item.hydrationOr : lang === 'so' ? item.hydrationSo : item.hydrationEn;

                            return (
                                <Card key={item.id} className="p-5 space-y-4 border border-gray-100 shadow-sm hover:shadow-md transition-all rounded-2xl bg-white flex flex-col justify-between">

                                    <div className="space-y-4">
                                        {/* HEADER */}
                                        <div className="flex items-start justify-between gap-3 border-b border-gray-100 pb-3">
                                            <div className="flex items-center gap-3">
                                                <div className="w-12 h-12 rounded-2xl bg-[#fdf2f8] border border-pink-100 text-[#61183e] flex flex-col items-center justify-center shrink-0 shadow-xs">
                                                    <span className="text-base font-extrabold leading-none">{item.week}</span>
                                                    <span className="text-[9px] font-bold uppercase tracking-wider text-pink-700">Week</span>
                                                </div>
                                                <div>
                                                    <h3 className="font-bold text-gray-900 text-base">Week {item.week} Guide</h3>
                                                    <p className="text-xs text-gray-500 font-medium">
                                                        Month {item.month} • {item.trimester} Trimester
                                                    </p>
                                                </div>
                                            </div>

                                            {/* ACTIONS */}
                                            <div className="flex items-center gap-1 shrink-0">
                                                <button
                                                    onClick={() => handleTogglePublish(item)}
                                                    title={item.isPublished ? 'Unpublish' : 'Publish'}
                                                    className={`p-1.5 rounded-lg border transition-colors ${item.isPublished ? 'text-green-600 bg-green-50 border-green-200 hover:bg-green-100' : 'text-gray-400 bg-gray-50 border-gray-200 hover:bg-gray-100'}`}
                                                >
                                                    {item.isPublished ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                                                </button>

                                                <button
                                                    onClick={() => handleOpenEditModal(item)}
                                                    title="Edit Week Guide"
                                                    className="p-1.5 text-blue-600 bg-blue-50 border border-blue-200 rounded-lg hover:bg-blue-100 transition-colors"
                                                >
                                                    <Edit2 className="w-4 h-4" />
                                                </button>

                                                <button
                                                    onClick={() => handleOpenDeleteModal(item)}
                                                    title="Delete Week Guide"
                                                    className="p-1.5 text-red-600 bg-red-50 border border-red-200 rounded-lg hover:bg-red-100 transition-colors"
                                                >
                                                    <Trash2 className="w-4 h-4" />
                                                </button>
                                            </div>
                                        </div>

                                        {/* LANGUAGE SELECTOR FOR CARD PREVIEW */}
                                        <div className="flex items-center gap-1 bg-gray-50 p-1 rounded-xl w-fit text-[11px] font-bold">
                                            {(['en', 'or', 'so', 'am'] as const).map(l => (
                                                <button
                                                    key={l}
                                                    onClick={() => setCardLanguage(item.id, l)}
                                                    className={`px-2.5 py-0.5 rounded-lg transition-all ${lang === l ? 'bg-white text-[#61183e] shadow-xs' : 'text-gray-400 hover:text-gray-600'}`}
                                                >
                                                    {l === 'en' ? 'EN' : l === 'or' ? 'OR' : l === 'so' ? 'SO' : 'AM'}
                                                </button>
                                            ))}
                                        </div>

                                        {/* WHY IT IS IMPORTANT */}
                                        <div className="space-y-1.5 bg-amber-50/50 p-3.5 rounded-xl border border-amber-100">
                                            <h4 className="text-xs font-bold text-amber-900 flex items-center gap-1.5">
                                                <BookOpen className="w-3.5 h-3.5 text-amber-600" />
                                                Why It Is Important ({lang.toUpperCase()})
                                            </h4>
                                            <p className="text-xs text-gray-700 leading-relaxed line-clamp-3">
                                                {whyImp || <span className="italic text-gray-400">No text provided for this language.</span>}
                                            </p>
                                        </div>

                                        {/* HYDRATION GUIDANCE */}
                                        <div className="space-y-1.5 bg-sky-50/50 p-3.5 rounded-xl border border-sky-100">
                                            <h4 className="text-xs font-bold text-sky-900 flex items-center gap-1.5">
                                                <Droplets className="w-3.5 h-3.5 text-sky-600" />
                                                Hydration Advice ({lang.toUpperCase()})
                                            </h4>
                                            <p className="text-xs text-gray-700 leading-relaxed line-clamp-2">
                                                {hydration || <span className="italic text-gray-400">No hydration advice provided for this language.</span>}
                                            </p>
                                        </div>
                                    </div>

                                    {/* FOOTER */}
                                    <div className="pt-3 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-400 font-medium">
                                        <span>Status: {item.isPublished ? 'Published' : 'Draft'}</span>
                                        <span className="text-[#61183e] font-bold">Month {item.month}</span>
                                    </div>
                                </Card>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* ─────────────────────────────────────────────────────────────────
               ADD / EDIT WEEK GUIDE MODAL
            ───────────────────────────────────────────────────────────────── */}
            <Modal
                isOpen={isAddModalOpen || isEditModalOpen}
                onClose={() => { setIsAddModalOpen(false); setIsEditModalOpen(false); }}
                title={isEditModalOpen ? `Edit Week ${formData.week} Guide` : '+ Add Week Guide'}
                size="xl"
            >
                <form onSubmit={handleSaveWeekGuide} className="space-y-6 py-2 max-h-[80vh] overflow-y-auto pr-1">

                    {/* SECTION 1: CONTEXT (Week, Trimester, Month) */}
                    <div className="p-4 bg-pink-50/50 rounded-2xl border border-pink-100 space-y-4">
                        <h4 className="text-xs font-bold text-[#61183e] uppercase tracking-wider flex items-center gap-2">
                            <Calendar className="w-4 h-4" />
                            1. Select Pregnancy Week
                        </h4>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label className="block text-xs font-bold text-gray-700 mb-1">Pregnancy Week (1–40) *</label>
                                <select
                                    value={formData.week}
                                    onChange={e => handleWeekChangeInForm(Number(e.target.value))}
                                    className="w-full text-xs font-semibold rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
                                >
                                    {Array.from({ length: 40 }, (_, i) => i + 1).map(w => {
                                        const { month, trimester } = calculateMonthAndTrimester(w);
                                        return (
                                            <option key={w} value={w}>
                                                Week {w} (Month {month}, {trimester} Trim)
                                            </option>
                                        );
                                    })}
                                </select>
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-700 mb-1">Calculated Info</label>
                                <div className="text-xs bg-white p-2.5 rounded-xl border border-gray-200 font-semibold text-gray-600 flex items-center justify-between">
                                    <span>Month {formData.month}</span>
                                    <span className={`px-2 py-0.5 rounded text-[10px] ${TRIMESTER_BADGE_STYLE[formData.trimester]}`}>
                                        {formData.trimester} Trim
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* SECTION 2: WHY IT IS IMPORTANT (4 LANGUAGES) */}
                    <div className="space-y-3 bg-amber-50/40 p-4 rounded-2xl border border-amber-100">
                        <h4 className="text-xs font-bold text-amber-900 uppercase tracking-wider flex items-center gap-2">
                            <BookOpen className="w-4 h-4 text-amber-700" />
                            2. Why It Is Important (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 English Explanation</label>
                                <TextArea
                                    value={formData.whyImportantEn}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantEn: e.target.value }))}
                                    placeholder="Explain why nutrition is essential during this week..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Amharic (አማርኛ) Explanation</label>
                                <TextArea
                                    value={formData.whyImportantAm}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantAm: e.target.value }))}
                                    placeholder="በዚህ ሳምንት አመጋገብ ለምን አስፈላጊ እንደሆነ ያብራሩ..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Afaan Oromo Explanation</label>
                                <TextArea
                                    value={formData.whyImportantOr}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantOr: e.target.value }))}
                                    placeholder="Ibsa maaliif nyaanni torban kana keessatti barbaachisaa ta'e..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Afan Somali Explanation</label>
                                <TextArea
                                    value={formData.whyImportantSo}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantSo: e.target.value }))}
                                    placeholder="Fahfaahin sababta nafaqadu muhiimka u tahay todobaadkan..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                        </div>
                    </div>

                    {/* SECTION 3: HYDRATION GUIDANCE (4 LANGUAGES) */}
                    <div className="space-y-3 bg-sky-50/40 p-4 rounded-2xl border border-sky-100">
                        <h4 className="text-xs font-bold text-sky-900 uppercase tracking-wider flex items-center gap-2">
                            <Droplets className="w-4 h-4 text-sky-700" />
                            3. Hydration Guidance (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 English Hydration Advice</label>
                                <TextArea
                                    value={formData.hydrationEn}
                                    onChange={e => setFormData(prev => ({ ...prev, hydrationEn: e.target.value }))}
                                    placeholder="e.g. Drink at least 8-10 glasses of water daily..."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Amharic Hydration Advice</label>
                                <TextArea
                                    value={formData.hydrationAm}
                                    onChange={e => setFormData(prev => ({ ...prev, hydrationAm: e.target.value }))}
                                    placeholder="ለምሳሌ፡ በቀን ቢያንስ 8-10 ብርጭቆ ውሃ ይጠጡ..."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Afaan Oromo Hydration Advice</label>
                                <TextArea
                                    value={formData.hydrationOr}
                                    onChange={e => setFormData(prev => ({ ...prev, hydrationOr: e.target.value }))}
                                    placeholder="e.g. Guyyaatti xiqqaate kubbaayaa bishaanii 8-10 dhugi..."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Afan Somali Hydration Advice</label>
                                <TextArea
                                    value={formData.hydrationSo}
                                    onChange={e => setFormData(prev => ({ ...prev, hydrationSo: e.target.value }))}
                                    placeholder="e.g. Cab ugu yaraan 8-10 koob oo biyo ah maalintii..."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                        </div>
                    </div>

                    {/* ACTIONS */}
                    <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100">
                        <Button
                            type="button"
                            onClick={() => { setIsAddModalOpen(false); setIsEditModalOpen(false); }}
                            className="bg-gray-100 text-gray-700 hover:bg-gray-200 text-xs px-4 py-2 rounded-xl font-semibold"
                        >
                            Cancel
                        </Button>
                        <Button
                            type="submit"
                            disabled={submitting}
                            className="bg-[#61183e] text-white hover:bg-[#4a122f] text-xs px-6 py-2 rounded-xl font-bold flex items-center gap-2"
                        >
                            {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
                            {isEditModalOpen ? 'Update Week Guide' : 'Save Week Guide'}
                        </Button>
                    </div>
                </form>
            </Modal>

            {/* ─────────────────────────────────────────────────────────────────
               DELETE CONFIRMATION MODAL
            ───────────────────────────────────────────────────────────────── */}
            <Modal
                isOpen={isDeleteModalOpen}
                onClose={() => setIsDeleteModalOpen(false)}
                title="Delete Week Guide"
            >
                <div className="space-y-4 py-3">
                    <div className="flex items-center gap-3 bg-red-50 p-4 rounded-xl text-red-700 border border-red-100">
                        <AlertTriangle className="w-6 h-6 shrink-0" />
                        <div>
                            <p className="text-sm font-bold">Are you sure you want to delete this week guide?</p>
                            <p className="text-xs text-red-600 mt-0.5">
                                Nutrition Guide for Week {entryToDelete?.week} will be permanently removed.
                            </p>
                        </div>
                    </div>

                    <div className="flex items-center justify-end gap-3 pt-3 border-t border-gray-100">
                        <Button
                            type="button"
                            onClick={() => setIsDeleteModalOpen(false)}
                            className="bg-gray-100 text-gray-700 text-xs px-4 py-2 rounded-xl"
                        >
                            Cancel
                        </Button>
                        <Button
                            type="button"
                            onClick={handleDeleteConfirm}
                            disabled={submitting}
                            className="bg-red-600 text-white hover:bg-red-700 text-xs px-5 py-2 rounded-xl font-bold flex items-center gap-2"
                        >
                            {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
                            Delete Week Guide
                        </Button>
                    </div>
                </div>
            </Modal>

            {/* ─────────────────────────────────────────────────────────────────
               SUCCESS FEEDBACK MODAL
            ───────────────────────────────────────────────────────────────── */}
            <Modal
                isOpen={successModal.open}
                onClose={() => setSuccessModal(prev => ({ ...prev, open: false }))}
                title={successModal.title}
            >
                <div className="py-4 text-center space-y-4">
                    <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto text-green-600">
                        <CheckCircle2 className="w-10 h-10" />
                    </div>
                    <p className="text-sm font-medium text-gray-700">{successModal.message}</p>
                    <Button
                        onClick={() => setSuccessModal(prev => ({ ...prev, open: false }))}
                        className="bg-[#61183e] text-white text-xs px-6 py-2 rounded-xl font-bold"
                    >
                        OK
                    </Button>
                </div>
            </Modal>

        </div>
    );
}
