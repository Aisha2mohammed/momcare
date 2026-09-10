import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
    PlusCircle, Search, Calendar, Moon, BookOpen,
    Edit2, Trash2, Eye, EyeOff, Loader2, CheckCircle2,
    Filter, AlertTriangle
} from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input, TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

// ─────────────────────────────────────────────────────────────────────────────
// Interfaces & Types
// ─────────────────────────────────────────────────────────────────────────────

export interface SleepWeekEntry {
    id: string | number;
    week: number;
    trimester: string; // '1st' | '2nd' | '3rd'
    month: number;
    isPublished: boolean;

    // Title (4 Languages)
    titleEn: string;
    titleAm: string;
    titleOr: string;
    titleSo: string;

    // Why It Is Important (4 Languages)
    whyImportantEn: string;
    whyImportantAm: string;
    whyImportantOr: string;
    whyImportantSo: string;

    // Sleep Tips (4 Languages)
    tipsEn: string;
    tipsAm: string;
    tipsOr: string;
    tipsSo: string;
}

interface BackendSleepRow {
    id: string | number;
    week?: number | string | null;
    trimester?: number | string | null;

    title_en?: string; titleEn?: string;
    title_am?: string; titleAm?: string;
    title_or?: string; titleOr?: string;
    title_so?: string; titleSo?: string;

    why_important_en?: string; whyImportantEn?: string;
    why_important_am?: string; whyImportantAm?: string;
    why_important_or?: string; whyImportantOr?: string;
    why_important_so?: string; whyImportantSo?: string;

    tips_en?: string; tipsEn?: string;
    tips_am?: string; tipsAm?: string;
    tips_or?: string; tipsOr?: string;
    tips_so?: string; tipsSo?: string;

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

const EMPTY_WEEK_ENTRY: Omit<SleepWeekEntry, 'id'> = {
    week: 18,
    trimester: '2nd',
    month: 5,
    isPublished: true,
    titleEn: '',
    titleAm: '',
    titleOr: '',
    titleSo: '',
    whyImportantEn: '',
    whyImportantAm: '',
    whyImportantOr: '',
    whyImportantSo: '',
    tipsEn: '',
    tipsAm: '',
    tipsOr: '',
    tipsSo: '',
};

// ─────────────────────────────────────────────────────────────────────────────
// Component
// ─────────────────────────────────────────────────────────────────────────────

export default function SleepPositionManager() {
    const { showToast } = useToast();

    // Data State
    const [rawRows, setRawRows] = useState<BackendSleepRow[]>([]);
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
    const [formData, setFormData] = useState<SleepWeekEntry>({ id: '', ...EMPTY_WEEK_ENTRY });
    const [entryToDelete, setEntryToDelete] = useState<SleepWeekEntry | null>(null);
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
            const res = await cmsClient.list<BackendSleepRow>('sleep-weeks', { limit: 500 });
            setRawRows(res.items || []);
        } catch (err: any) {
            showToast(err.message || 'Failed to load sleep weeks', 'error');
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

                titleEn: row.title_en || row.titleEn || '',
                titleAm: row.title_am || row.titleAm || '',
                titleOr: row.title_or || row.titleOr || '',
                titleSo: row.title_so || row.titleSo || '',

                whyImportantEn: row.why_important_en || row.whyImportantEn || '',
                whyImportantAm: row.why_important_am || row.whyImportantAm || '',
                whyImportantOr: row.why_important_or || row.whyImportantOr || '',
                whyImportantSo: row.why_important_so || row.whyImportantSo || '',

                tipsEn: row.tips_en || row.tipsEn || '',
                tipsAm: row.tips_am || row.tipsAm || '',
                tipsOr: row.tips_or || row.tipsOr || '',
                tipsSo: row.tips_so || row.tipsSo || '',
            } as SleepWeekEntry;
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
                    item.titleEn.toLowerCase().includes(q) ||
                    item.titleAm.toLowerCase().includes(q) ||
                    item.titleOr.toLowerCase().includes(q) ||
                    item.titleSo.toLowerCase().includes(q) ||
                    item.whyImportantEn.toLowerCase().includes(q) ||
                    item.whyImportantAm.toLowerCase().includes(q) ||
                    item.whyImportantOr.toLowerCase().includes(q) ||
                    item.whyImportantSo.toLowerCase().includes(q) ||
                    item.tipsEn.toLowerCase().includes(q) ||
                    item.tipsAm.toLowerCase().includes(q)
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

    const handleOpenEditModal = (entry: SleepWeekEntry) => {
        setFormData({ ...entry });
        setIsEditModalOpen(true);
    };

    const handleOpenDeleteModal = (entry: SleepWeekEntry) => {
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
                month: formData.month,
                trimester: formData.trimester,
                titleEn: formData.titleEn,
                titleAm: formData.titleAm,
                titleOr: formData.titleOr,
                titleSo: formData.titleSo,
                whyImportantEn: formData.whyImportantEn,
                whyImportantAm: formData.whyImportantAm,
                whyImportantOr: formData.whyImportantOr,
                whyImportantSo: formData.whyImportantSo,
                tipsEn: formData.tipsEn,
                tipsAm: formData.tipsAm,
                tipsOr: formData.tipsOr,
                tipsSo: formData.tipsSo,
                isPublished: formData.isPublished,
            };

            if (isEditModalOpen && formData.id) {
                await cmsClient.update('sleep-weeks', formData.id, payload);
                setIsEditModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Sleep Guide Updated',
                    message: `Sleep Guide for Week ${formData.week} updated successfully.`
                });
            } else {
                await cmsClient.create('sleep-weeks', payload);
                setIsAddModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Sleep Guide Created',
                    message: `New Sleep Guide for Week ${formData.week} created successfully.`
                });
            }
            loadWeekGuidesData();
        } catch (err: any) {
            showToast(err.message || 'Failed to save sleep guide', 'error');
        } finally {
            setSubmitting(false);
        }
    };

    // ── Delete Action ────────────────────────────────────────────────────────
    const handleConfirmDelete = async () => {
        if (!entryToDelete) return;
        try {
            await cmsClient.delete('sleep-weeks', entryToDelete.id);
            setIsDeleteModalOpen(false);
            setEntryToDelete(null);
            showToast(`Week ${entryToDelete.week} Sleep Guide deleted.`, 'success');
            loadWeekGuidesData();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete sleep guide', 'error');
        }
    };

    // ── Toggle Publish Status ────────────────────────────────────────────────
    const handleTogglePublish = async (entry: SleepWeekEntry) => {
        try {
            const newStatus = !entry.isPublished;
            await cmsClient.update('sleep-weeks', entry.id, { isPublished: newStatus });
            showToast(`Week ${entry.week} Guide ${newStatus ? 'published' : 'moved to drafts'}.`, 'success');
            loadWeekGuidesData();
        } catch (err: any) {
            showToast(err.message || 'Failed to toggle visibility', 'error');
        }
    };

    // ── Per Card Language Switcher Helper ────────────────────────────────────
    const setCardLanguage = (cardId: string | number, lang: 'en' | 'or' | 'so' | 'am') => {
        setCardLang(prev => ({ ...prev, [cardId]: lang }));
    };

    const getActiveCardLang = (cardId: string | number): 'en' | 'or' | 'so' | 'am' => {
        return cardLang[cardId] || 'en';
    };

    return (
        <div className="space-y-6">
            {/* TOP HEADER */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-[#312e81]">Sleep Week Guides</h2>
                    <p className="text-gray-500 text-sm mt-0.5">
                        Manage weekly maternal sleep importance, trimester changes, and sleep posture tips in 4 languages
                    </p>
                </div>
                <Button
                    onClick={handleOpenAddModal}
                    className="bg-[#312e81] text-white hover:bg-[#1e1b4b] text-sm px-5 py-2.5 rounded-xl font-bold flex items-center gap-2 shadow-sm"
                >
                    <PlusCircle className="w-5 h-5" />
                    + Add Sleep Week
                </Button>
            </div>

            {/* FILTER BAR */}
            <Card className="p-4 space-y-4 bg-white border border-gray-100 shadow-sm rounded-2xl">
                <div className="flex items-center gap-2 text-xs font-bold text-gray-700 uppercase tracking-wider">
                    <Filter className="w-4 h-4 text-[#312e81]" />
                    Filter Sleep Weeks
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                    {/* Trimester Filter */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Trimester</label>
                        <select
                            value={filterTrimester}
                            onChange={e => setFilterTrimester(e.target.value)}
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
                        >
                            <option value="all">All Trimesters</option>
                            <option value="1st">1st Trimester</option>
                            <option value="2nd">2nd Trimester</option>
                            <option value="3rd">3rd Trimester</option>
                        </select>
                    </div>

                    {/* Month Filter */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Month</label>
                        <select
                            value={filterMonth}
                            onChange={e => setFilterMonth(e.target.value)}
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
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
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
                        >
                            <option value="all">All Weeks (1–40)</option>
                            {Array.from({ length: 40 }, (_, i) => i + 1).map(w => (
                                <option key={w} value={w}>Week {w}</option>
                            ))}
                        </select>
                    </div>

                    {/* Search Filter */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Search Guides</label>
                        <div className="relative">
                            <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                            <input
                                type="text"
                                placeholder="Search by week, tips, or why important..."
                                value={searchQuery}
                                onChange={e => setSearchQuery(e.target.value)}
                                className="w-full text-xs rounded-xl pl-9 pr-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
                            />
                        </div>
                    </div>
                </div>
            </Card>

            {/* LIST OF WEEK CARDS */}
            {loading ? (
                <div className="flex flex-col items-center justify-center p-16 text-gray-400">
                    <Loader2 className="w-8 h-8 animate-spin text-[#312e81] mb-2" />
                    <p className="text-sm font-medium">Loading sleep week guides...</p>
                </div>
            ) : filteredEntries.length === 0 ? (
                <div className="text-center p-12 bg-white rounded-2xl border border-gray-100 shadow-sm space-y-3">
                    <p className="text-sm text-gray-500 font-medium">No sleep week guides found matching your filters.</p>
                    <Button
                        onClick={handleOpenAddModal}
                        className="bg-[#312e81] text-white hover:bg-[#1e1b4b] text-xs px-4 py-2 rounded-xl font-bold"
                    >
                        Create Week Guide
                    </Button>
                </div>
            ) : (
                <div className="space-y-3">
                    <div className="flex items-center justify-between text-xs text-gray-500 px-1">
                        <span>Showing <strong>{filteredEntries.length}</strong> sleep week guides</span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {filteredEntries.map((item) => {
                            const lang = getActiveCardLang(item.id);
                            const title = lang === 'am' ? (item.titleAm || item.titleEn) : lang === 'or' ? (item.titleOr || item.titleEn) : lang === 'so' ? (item.titleSo || item.titleEn) : item.titleEn;
                            const whyImp = lang === 'am' ? item.whyImportantAm : lang === 'or' ? item.whyImportantOr : lang === 'so' ? item.whyImportantSo : item.whyImportantEn;
                            const tips = lang === 'am' ? item.tipsAm : lang === 'or' ? item.tipsOr : lang === 'so' ? item.tipsSo : item.tipsEn;

                            return (
                                <Card key={item.id} className="p-5 space-y-4 border border-gray-100 shadow-sm hover:shadow-md transition-all rounded-2xl bg-white flex flex-col justify-between">

                                    <div className="space-y-4">
                                        {/* HEADER */}
                                        <div className="flex items-start justify-between gap-3 border-b border-gray-100 pb-3">
                                            <div className="flex items-center gap-3">
                                                <div className="w-12 h-12 rounded-2xl bg-indigo-50 border border-indigo-100 text-[#312e81] flex flex-col items-center justify-center shrink-0 shadow-xs">
                                                    <span className="text-base font-extrabold leading-none">{item.week}</span>
                                                    <span className="text-[9px] font-bold uppercase tracking-wider text-indigo-700">Week</span>
                                                </div>
                                                <div>
                                                    <h3 className="font-bold text-gray-900 text-base">{title || `Week ${item.week} Sleep Guide`}</h3>
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
                                                    className={`px-2.5 py-0.5 rounded-lg transition-all ${lang === l ? 'bg-white text-[#312e81] shadow-xs' : 'text-gray-400 hover:text-gray-600'}`}
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

                                        {/* SLEEP TIPS */}
                                        <div className="space-y-1.5 bg-indigo-50/50 p-3.5 rounded-xl border border-indigo-100">
                                            <h4 className="text-xs font-bold text-indigo-900 flex items-center gap-1.5">
                                                <Moon className="w-3.5 h-3.5 text-indigo-600" />
                                                Sleep Tips ({lang.toUpperCase()})
                                            </h4>
                                            <p className="text-xs text-gray-700 leading-relaxed line-clamp-2">
                                                {tips || <span className="italic text-gray-400">No sleep tips provided for this language.</span>}
                                            </p>
                                        </div>
                                    </div>

                                    {/* FOOTER */}
                                    <div className="pt-3 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-400 font-medium">
                                        <span>Status: {item.isPublished ? 'Published' : 'Draft'}</span>
                                        <span className="text-[#312e81] font-bold">Month {item.month}</span>
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
                title={isEditModalOpen ? `Edit Week ${formData.week} Sleep Guide` : '+ Add Sleep Week Guide'}
                size="xl"
            >
                <form onSubmit={handleSaveWeekGuide} className="space-y-6 py-2 max-h-[80vh] overflow-y-auto pr-1">

                    {/* SECTION 1: CONTEXT (Week, Trimester, Month) */}
                    <div className="p-4 bg-indigo-50/50 rounded-2xl border border-indigo-100 space-y-4">
                        <h4 className="text-xs font-bold text-[#312e81] uppercase tracking-wider flex items-center gap-2">
                            <Calendar className="w-4 h-4" />
                            1. Select Pregnancy Week
                        </h4>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label className="block text-xs font-bold text-gray-700 mb-1">Pregnancy Week (1–40) *</label>
                                <select
                                    value={formData.week}
                                    onChange={e => handleWeekChangeInForm(Number(e.target.value))}
                                    className="w-full text-xs font-semibold rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
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

                    {/* SECTION 2: SLEEP WEEK TITLE (4 LANGUAGES) */}
                    <div className="space-y-3 bg-indigo-50/40 p-4 rounded-2xl border border-indigo-100">
                        <h4 className="text-xs font-bold text-indigo-900 uppercase tracking-wider flex items-center gap-2">
                            <Moon className="w-4 h-4 text-indigo-700" />
                            2. Sleep Week Title (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 English Title</label>
                                <Input
                                    value={formData.titleEn}
                                    onChange={e => setFormData(prev => ({ ...prev, titleEn: e.target.value }))}
                                    placeholder="e.g. Safe Sleep Positions for Week 18..."
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Amharic (አማርኛ) Title</label>
                                <Input
                                    value={formData.titleAm}
                                    onChange={e => setFormData(prev => ({ ...prev, titleAm: e.target.value }))}
                                    placeholder="ለምሳሌ፡ ለ18ኛ ሳምንት ነዓድ የቐረቀጩ የነዓድ ጫፌ..."
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Afaan Oromo Title</label>
                                <Input
                                    value={formData.titleOr}
                                    onChange={e => setFormData(prev => ({ ...prev, titleOr: e.target.value }))}
                                    placeholder="Fkn. Bakka Hirribaa Nagaa Torban 18 Keessatti..."
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Afan Somali Title</label>
                                <Input
                                    value={formData.titleSo}
                                    onChange={e => setFormData(prev => ({ ...prev, titleSo: e.target.value }))}
                                    placeholder="Tusaale. Goobaha Seexashada Amaan ah Toddobaadka 18aad..."
                                    className="text-xs rounded-xl"
                                />
                            </div>
                        </div>
                    </div>

                    {/* SECTION 3: WHY IT IS IMPORTANT (4 LANGUAGES) */}
                    <div className="space-y-3 bg-amber-50/40 p-4 rounded-2xl border border-amber-100">
                        <h4 className="text-xs font-bold text-amber-900 uppercase tracking-wider flex items-center gap-2">
                            <BookOpen className="w-4 h-4 text-amber-700" />
                            3. Why It Is Important (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 English Explanation</label>
                                <TextArea
                                    value={formData.whyImportantEn}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantEn: e.target.value }))}
                                    placeholder="Explain why proper sleep and rest are essential during this week..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Amharic (አማርኛ) Explanation</label>
                                <TextArea
                                    value={formData.whyImportantAm}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantAm: e.target.value }))}
                                    placeholder="በዚህ ሳምንት እንቅልፍና እረፍት ለምን አስፈላጊ እንደሆነ ያብራሩ..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Afaan Oromo Explanation</label>
                                <TextArea
                                    value={formData.whyImportantOr}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantOr: e.target.value }))}
                                    placeholder="Ibsa maaliif hirriibni gaariin torban kana keessatti barbaachisaa ta'e..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Afan Somali Explanation</label>
                                <TextArea
                                    value={formData.whyImportantSo}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantSo: e.target.value }))}
                                    placeholder="Fahfaahin sababta hurmada saxda ah u muhiimka tahay todobaadkan..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                        </div>
                    </div>

                    {/* SECTION 4: SLEEP TIPS (4 LANGUAGES) */}
                    <div className="space-y-3 bg-indigo-50/40 p-4 rounded-2xl border border-indigo-100">
                        <h4 className="text-xs font-bold text-indigo-900 uppercase tracking-wider flex items-center gap-2">
                            <Moon className="w-4 h-4 text-indigo-700" />
                            4. Sleep Tips (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 English Sleep Tips</label>
                                <TextArea
                                    value={formData.tipsEn}
                                    onChange={e => setFormData(prev => ({ ...prev, tipsEn: e.target.value }))}
                                    placeholder="e.g. Sleep on your left side (SOS), support with pregnancy pillow, elevate head slightly..."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Amharic Sleep Tips</label>
                                <TextArea
                                    value={formData.tipsAm}
                                    onChange={e => setFormData(prev => ({ ...prev, tipsAm: e.target.value }))}
                                    placeholder="ለምሳሌ፡ በግራ ጎንዎ መተኛት፣ ትራሶችን ለእግርና ጀርባ መጠቀም..."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Afaan Oromo Sleep Tips</label>
                                <TextArea
                                    value={formData.tipsOr}
                                    onChange={e => setFormData(prev => ({ ...prev, tipsOr: e.target.value }))}
                                    placeholder="e.g. Cinaacha bitaatiin rafuu, boraatii deeggarsaatiif fayyadamuu..."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Afan Somali Sleep Tips</label>
                                <TextArea
                                    value={formData.tipsSo}
                                    onChange={e => setFormData(prev => ({ ...prev, tipsSo: e.target.value }))}
                                    placeholder="e.g. Dhinaca bidix u seexo, barkimooyin isticmaal si aad u nasato..."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                        </div>
                    </div>

                    {/* SECTION 4: PUBLISHING STATUS */}
                    <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl border border-gray-200/60">
                        <div>
                            <span className="text-xs font-bold text-gray-700 block">Publish Status</span>
                            <span className="text-[11px] text-gray-500">Make this sleep guide visible on the mobile app</span>
                        </div>
                        <label className="flex items-center gap-2 cursor-pointer">
                            <input
                                type="checkbox"
                                checked={formData.isPublished}
                                onChange={e => setFormData(prev => ({ ...prev, isPublished: e.target.checked }))}
                                className="w-4 h-4 text-[#312e81] rounded border-gray-300 focus:ring-[#312e81]"
                            />
                            <span className="text-xs font-semibold text-gray-700">
                                {formData.isPublished ? 'Published' : 'Draft'}
                            </span>
                        </label>
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
                            className="bg-[#312e81] text-white hover:bg-[#1e1b4b] text-xs px-6 py-2 rounded-xl font-bold flex items-center gap-2"
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
                title="Delete Sleep Week Guide"
            >
                <div className="space-y-4 py-3">
                    <div className="flex items-center gap-3 bg-red-50 p-4 rounded-xl text-red-700 border border-red-100">
                        <AlertTriangle className="w-6 h-6 shrink-0" />
                        <div>
                            <p className="text-sm font-bold">Are you sure you want to delete this week guide?</p>
                            <p className="text-xs text-red-600 mt-0.5">
                                Sleep Guide for Week {entryToDelete?.week} will be permanently removed.
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
                            onClick={handleConfirmDelete}
                            className="bg-red-600 text-white hover:bg-red-700 text-xs px-4 py-2 rounded-xl font-bold"
                        >
                            Yes, Delete Guide
                        </Button>
                    </div>
                </div>
            </Modal>

            {/* ─────────────────────────────────────────────────────────────────
               SUCCESS FEEDBACK MODAL
            ───────────────────────────────────────────────────────────────── */}
            <Modal
                isOpen={successModal.open}
                onClose={() => setSuccessModal({ open: false, title: '', message: '' })}
                title={successModal.title}
            >
                <div className="p-6 text-center space-y-4">
                    <div className="w-12 h-12 bg-indigo-100 text-indigo-600 rounded-full flex items-center justify-center mx-auto">
                        <CheckCircle2 className="w-7 h-7" />
                    </div>
                    <div>
                        <h4 className="text-base font-bold text-gray-800">{successModal.title}</h4>
                        <p className="text-xs text-gray-500 mt-1">{successModal.message}</p>
                    </div>
                    <Button
                        onClick={() => setSuccessModal({ open: false, title: '', message: '' })}
                        className="bg-[#312e81] text-white hover:bg-[#1e1b4b] text-xs px-6 py-2 rounded-xl font-bold mx-auto"
                    >
                        Done
                    </Button>
                </div>
            </Modal>
        </div>
    );
}
