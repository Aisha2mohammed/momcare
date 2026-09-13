import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
    PlusCircle, Search, X, Moon, CheckCircle2,
    Edit2, Trash2, Loader2, Filter, Calendar,
    Image as ImageIcon, Video as VideoIcon,
    HeartPulse, HelpCircle
} from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input, TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { MediaInput } from '../components/ui/MediaInput';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

// ─────────────────────────────────────────────────────────────────────────────
// Interfaces & Types
// ─────────────────────────────────────────────────────────────────────────────

export interface SleepItem {
    id?: string;
    nameEn: string;
    nameOr: string;
    nameSo: string;
    nameAm: string;
    descEn: string;
    descOr: string;
    descSo: string;
    descAm: string;
    labelEn?: string;
    labelOr?: string;
    labelSo?: string;
    labelAm?: string;
    imageUrl?: string;
    videoUrl?: string;
}

export interface SleepSection {
    id?: string;
    parentId?: string | number;
    week: number;
    trimester: string;
    month: number;
    type: 'recommended' | 'avoid' | 'tip';
    sleepType: string;
    emoji: string;
    isPublished?: boolean;

    // 4 Language Titles
    titleEn: string;
    titleOr: string;
    titleSo: string;
    titleAm: string;

    // 4 Language Body Descriptions
    bodyEn: string;
    bodyOr: string;
    bodySo: string;
    bodyAm: string;

    // 4 Language Why Important
    whyImportantEn: string;
    whyImportantOr: string;
    whyImportantSo: string;
    whyImportantAm: string;

    // 4 Language Health Tips
    tipsEn: string;
    tipsOr: string;
    tipsSo: string;
    tipsAm: string;

    // Media
    imageUrl?: string;
    videoUrl?: string;

    // Description Label & Value (4 languages)
    benefitValueEn?: string;
    benefitValueOr?: string;
    benefitValueSo?: string;
    benefitValueAm?: string;
    benefitLabelEn?: string;
    benefitLabelOr?: string;
    benefitLabelSo?: string;
    benefitLabelAm?: string;

    // Sleep Duration (plain text, e.g. "8 hours / night")
    sleepDuration?: string;

    // Sleep Items List
    items: SleepItem[];
}

interface BackendSleepRow {
    id: string | number;
    week?: number | string | null;
    trimester?: string | number | null;
    position?: string;
    type?: 'recommended' | 'avoid' | 'tip' | string;
    emoji?: string;

    title_en?: string; titleEn?: string;
    title_or?: string; titleOr?: string;
    title_so?: string; titleSo?: string;
    title_am?: string; titleAm?: string;

    description_en?: string; descriptionEn?: string;
    description_or?: string; descriptionOr?: string;
    description_so?: string; descriptionSo?: string;
    description_am?: string; descriptionAm?: string;

    description_label_en?: string; description_label_am?: string;
    description_label_or?: string; description_label_so?: string;
    description_value_en?: string; description_value_am?: string;
    description_value_or?: string; description_value_so?: string;

    why_important_en?: string; whyImportantEn?: string;
    why_important_or?: string; whyImportantOr?: string;
    why_important_so?: string; whyImportantSo?: string;
    why_important_am?: string; whyImportantAm?: string;

    health_tips?: any[];
    list_sleep?: any[];

    illustration_url?: string; illustrationUrl?: string;
    image_url?: string; imageUrl?: string;
    video_url?: string; videoUrl?: string;

    sleep_duration?: string; sleepDuration?: string;
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

// Dropdown options for the sleep guide icon
const SLEEP_EMOJI_OPTIONS: { value: string; label: string }[] = [
    { value: '🌙', label: 'Crescent Moon' },
    { value: '😴', label: 'Sleeping Face' },
    { value: '🛌', label: 'Person in Bed' },
    { value: '🛏️', label: 'Bed' },
    { value: '💤', label: 'Zzz' },
    { value: '😪', label: 'Sleepy Face' },
    { value: '🌛', label: 'Moon Face (First Quarter)' },
    { value: '🌜', label: 'Moon Face (Last Quarter)' },
    { value: '⭐', label: 'Star' },
    { value: '🧸', label: 'Teddy Bear' },
    { value: '🤰', label: 'Pregnant Woman' },
    { value: '🚫', label: 'Avoid / Not Recommended' },
    { value: '✅', label: 'Recommended' },
];

const EMPTY_SLEEP_SECTION: Omit<SleepSection, 'id'> = {
    week: 18,
    trimester: '2nd',
    month: 5,
    type: 'recommended',
    sleepType: 'Safe Sleep Position',
    emoji: '🌙',
    isPublished: true,
    titleEn: '', titleOr: '', titleSo: '', titleAm: '',
    bodyEn: '', bodyOr: '', bodySo: '', bodyAm: '',
    whyImportantEn: '', whyImportantOr: '', whyImportantSo: '', whyImportantAm: '',
    tipsEn: '', tipsOr: '', tipsSo: '', tipsAm: '',
    imageUrl: '', videoUrl: '',
    benefitValueEn: '', benefitValueOr: '', benefitValueSo: '', benefitValueAm: '',
    benefitLabelEn: '', benefitLabelOr: '', benefitLabelSo: '', benefitLabelAm: '',
    sleepDuration: '',
    items: [],
};

const EMPTY_SLEEP_ITEM: SleepItem = {
    nameEn: '', nameOr: '', nameSo: '', nameAm: '',
    descEn: '', descOr: '', descSo: '', descAm: '',
    labelEn: '', labelOr: '', labelSo: '', labelAm: '',
    imageUrl: '', videoUrl: ''
};

export default function AddSleepPage() {
    const { showToast } = useToast();

    const [rawRows, setRawRows] = useState<BackendSleepRow[]>([]);
    const [loading, setLoading] = useState(true);

    // Filters
    const [filterTrimester, setFilterTrimester] = useState<string>('all');
    const [filterMonth, setFilterMonth] = useState<string>('all');
    const [filterWeek, setFilterWeek] = useState<string>('all');
    const [filterType, setFilterType] = useState<string>('all');
    const [searchQuery, setSearchQuery] = useState<string>('');

    // Modal state
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
    const [activeLangTab, setActiveLangTab] = useState<'en' | 'or' | 'so' | 'am'>('en');

    const [formData, setFormData] = useState<SleepSection>({ ...EMPTY_SLEEP_SECTION });
    const [itemToDelete, setItemToDelete] = useState<SleepSection | null>(null);
    const [submitting, setSubmitting] = useState(false);

    const [successModal, setSuccessModal] = useState<{ open: boolean; title: string; message: string }>({
        open: false, title: '', message: ''
    });

    const [cardLang, setCardLang] = useState<Record<string, 'en' | 'or' | 'so' | 'am'>>({});

    const loadData = useCallback(async () => {
        setLoading(true);
        try {
            const res = await cmsClient.list<BackendSleepRow>('sleep', { limit: 500 });
            setRawRows(res.items || []);
        } catch (err: any) {
            showToast(err.message || 'Failed to load sleep tips', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        loadData();
    }, [loadData]);

    // Flatten DB rows into SleepSection cards
 const sleepList = useMemo(() => {
    const list: SleepSection[] = [];

    rawRows.forEach(row => {
        const weekNum = Number(row.week || 1);
        const { month, trimester } = calculateMonthAndTrimester(weekNum);
        const parentType = (row.type || 'recommended') as 'recommended' | 'avoid' | 'tip';
        const isPub = row.is_published ?? row.isPublished ?? true;

        // Parse list_sleep (the real backend field)
        const rawItems = row.list_sleep || (row as any).listSleep;
        let parsedItems: any[] = [];
        if (Array.isArray(rawItems)) parsedItems = rawItems;
        else if (typeof rawItems === 'string') {
            try { parsedItems = JSON.parse(rawItems); } catch { parsedItems = []; }
        }

        const itemsList: SleepItem[] = parsedItems.map((it: any, ii: number) => ({
            id: it.id || `item-${row.id}-${ii}`,
            nameEn: it.name?.en || it.nameEn || '',
            nameOr: it.name?.or || it.nameOr || '',
            nameSo: it.name?.so || it.nameSo || '',
            nameAm: it.name?.am || it.nameAm || '',
            descEn: it.description?.en || it.descEn || '',
            descOr: it.description?.or || it.descOr || '',
            descSo: it.description?.so || it.descSo || '',
            descAm: it.description?.am || it.descAm || '',
            labelEn: it.label?.en || it.labelEn || '',
            labelOr: it.label?.or || it.labelOr || '',
            labelSo: it.label?.so || it.labelSo || '',
            labelAm: it.label?.am || it.labelAm || '',
            imageUrl: it.image?.url || it.imageUrl || '',
            videoUrl: it.video?.url || it.videoUrl || '',
        }));

        // Parse health_tips
        const rawTipsSource = row.health_tips || (row as any).healthTips;
        let rawTipsFull: any[] = [];
        if (Array.isArray(rawTipsSource)) rawTipsFull = rawTipsSource;
        else if (typeof rawTipsSource === 'string') {
            try { rawTipsFull = JSON.parse(rawTipsSource); } catch { rawTipsFull = []; }
        }
        const firstTip = rawTipsFull.length > 0 ? rawTipsFull[0] : null;

        list.push({
            id: `row-${row.id}`,
            parentId: row.id,
            week: weekNum,
            trimester: String(row.trimester ?? trimester),
            month,
            type: parentType,
            sleepType: (row as any).position || 'Sleep Posture',
            emoji: row.emoji || '🌙',
            isPublished: isPub,

            titleEn: row.title_en || row.titleEn || '',
            titleOr: row.title_or || row.titleOr || '',
            titleSo: row.title_so || row.titleSo || '',
            titleAm: row.title_am || row.titleAm || '',

            bodyEn: row.description_en || row.descriptionEn || '',
            bodyOr: row.description_or || row.descriptionOr || '',
            bodySo: row.description_so || row.descriptionSo || '',
            bodyAm: row.description_am || row.descriptionAm || '',

            whyImportantEn: row.why_important_en || row.whyImportantEn || '',
            whyImportantOr: row.why_important_or || row.whyImportantOr || '',
            whyImportantSo: row.why_important_so || row.whyImportantSo || '',
            whyImportantAm: row.why_important_am || row.whyImportantAm || '',

            tipsEn: firstTip?.label?.en || '',
            tipsOr: firstTip?.label?.or || '',
            tipsSo: firstTip?.label?.so || '',
            tipsAm: firstTip?.label?.am || '',

            imageUrl: row.illustration_url || (row as any).illustrationUrl || row.image_url || row.imageUrl || '',
            videoUrl: row.video_url || row.videoUrl || '',

            benefitValueEn: (row as any).description_value_en || '',
            benefitValueOr: (row as any).description_value_or || '',
            benefitValueSo: (row as any).description_value_so || '',
            benefitValueAm: (row as any).description_value_am || '',

            benefitLabelEn: (row as any).description_label_en || '',
            benefitLabelOr: (row as any).description_label_or || '',
            benefitLabelSo: (row as any).description_label_so || '',
            benefitLabelAm: (row as any).description_label_am || '',

            sleepDuration: row.sleep_duration || row.sleepDuration || '',

            items: itemsList,
        });
    });

    return list;
}, [rawRows]);

    const createdWeeks = useMemo(() => {
        const set = new Set<number>();
        rawRows.forEach(row => {
            if (row.week !== null && row.week !== undefined && row.week !== '') {
                set.add(Number(row.week));
            }
        });
        return Array.from(set).sort((a, b) => a - b);
    }, [rawRows]);

    const filteredSleepList = useMemo(() => {
        return sleepList.filter(item => {
            if (filterTrimester !== 'all') {
                if (!String(item.trimester).toLowerCase().includes(filterTrimester.toLowerCase())) return false;
            }
            if (filterMonth !== 'all') {
                if (item.month !== Number(filterMonth)) return false;
            }
            if (filterWeek !== 'all') {
                if (item.week !== Number(filterWeek)) return false;
            }
            if (filterType !== 'all') {
                if (item.type !== filterType) return false;
            }
            if (searchQuery.trim()) {
                const q = searchQuery.toLowerCase().trim();
                const match = (
                    item.sleepType.toLowerCase().includes(q) ||
                    item.titleEn.toLowerCase().includes(q) ||
                    item.titleAm.toLowerCase().includes(q) ||
                    item.titleOr.toLowerCase().includes(q) ||
                    item.bodyEn.toLowerCase().includes(q) ||
                    `week ${item.week}`.includes(q)
                );
                if (!match) return false;
            }
            return true;
        });
    }, [sleepList, filterTrimester, filterMonth, filterWeek, filterType, searchQuery]);

    // Modal Action Handlers
    const handleOpenAddModal = () => {
        const initialWeek = createdWeeks.length > 0 ? createdWeeks[0] : 18;
        const { month, trimester } = calculateMonthAndTrimester(initialWeek);
        setFormData({
            ...EMPTY_SLEEP_SECTION,
            week: initialWeek,
            month,
            trimester,
            items: [{ ...EMPTY_SLEEP_ITEM }],
        });
        setActiveLangTab('en');
        setIsAddModalOpen(true);
    };

    const handleOpenEditModal = (item: SleepSection) => {
        setFormData({
            ...item,
            items: item.items.length > 0 ? item.items.map(i => ({ ...i })) : [{ ...EMPTY_SLEEP_ITEM }],
        });
        setActiveLangTab('en');
        setIsEditModalOpen(true);
    };

    const handleOpenDeleteModal = (item: SleepSection) => {
        setItemToDelete(item);
        setIsDeleteModalOpen(true);
    };

    const handleWeekChangeInForm = (weekNum: number) => {
        const { month, trimester } = calculateMonthAndTrimester(weekNum);
        setFormData(prev => ({ ...prev, week: weekNum, month, trimester }));
    };

    const handleAddItem = () => {
        setFormData(prev => ({ ...prev, items: [...prev.items, { ...EMPTY_SLEEP_ITEM }] }));
    };

    const handleRemoveItem = (idx: number) => {
        setFormData(prev => ({ ...prev, items: prev.items.filter((_, i) => i !== idx) }));
    };

    const handleItemChange = (idx: number, field: keyof SleepItem, val: string) => {
        setFormData(prev => {
            const next = [...prev.items];
            next[idx] = { ...next[idx], [field]: val };
            return { ...prev, items: next };
        });
    };

    // Save Action
   const handleSaveSleep = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.sleepType.trim()) {
        showToast('Please enter a Title / Category (e.g. Side Sleeping, Back Sleeping)', 'error');
        return;
    }

    setSubmitting(true);
    try {
        const trimesterMap: Record<string, number> = { '1st': 1, '2nd': 2, '3rd': 3 };
        const trimesterNumber = trimesterMap[formData.trimester] ?? Number(formData.trimester);

        const payload = {
            trimester: trimesterNumber,
            position: formData.sleepType || 'other',
            illustrationUrl: formData.imageUrl || '',
            isPublished: true,

            titleEn: formData.titleEn,
            titleAm: formData.titleAm,
            titleOr: formData.titleOr,
            titleSo: formData.titleSo,

            descriptionEn: formData.bodyEn,
            descriptionAm: formData.bodyAm,
            descriptionOr: formData.bodyOr,
            descriptionSo: formData.bodySo,

            descriptionLabelEn: formData.benefitLabelEn || '',
            descriptionLabelAm: formData.benefitLabelAm || '',
            descriptionLabelOr: formData.benefitLabelOr || '',
            descriptionLabelSo: formData.benefitLabelSo || '',

            descriptionValueEn: formData.benefitValueEn || '',
            descriptionValueAm: formData.benefitValueAm || '',
            descriptionValueOr: formData.benefitValueOr || '',
            descriptionValueSo: formData.benefitValueSo || '',

            whyImportantEn: formData.whyImportantEn,
            whyImportantAm: formData.whyImportantAm,
            whyImportantOr: formData.whyImportantOr,
            whyImportantSo: formData.whyImportantSo,

            healthTips: (formData.tipsEn || formData.tipsAm || formData.tipsOr || formData.tipsSo) ? [
                {
                    label: {
                        en: formData.tipsEn || '',
                        am: formData.tipsAm || '',
                        or: formData.tipsOr || '',
                        so: formData.tipsSo || ''
                    }
                }
            ] : [],

            listSleep: formData.items.map(item => ({
                type: formData.type,
                name: { en: item.nameEn, am: item.nameAm, or: item.nameOr, so: item.nameSo },
                description: { en: item.descEn, am: item.descAm, or: item.descOr, so: item.descSo },
                label: { en: item.labelEn, am: item.labelAm, or: item.labelOr, so: item.labelSo },
                image: item.imageUrl ? { type: 'url', url: item.imageUrl } : null,
                video: item.videoUrl ? { type: 'url', url: item.videoUrl } : null,
            })),
        };

        if (isEditModalOpen && formData.parentId) {
            await cmsClient.update('sleep', formData.parentId, payload);
            setIsEditModalOpen(false);
            setSuccessModal({
                open: true,
                title: 'Sleep Guide Updated!',
                message: `Sleep position "${formData.sleepType}" for Week ${formData.week} updated.`
            });
        } else {
            await cmsClient.create('sleep', payload);
            setIsAddModalOpen(false);
            setSuccessModal({
                open: true,
                title: 'Sleep Guide Created!',
                message: `Sleep position "${formData.sleepType}" added for Week ${formData.week}.`
            });
        }

        await loadData();
    } catch (err: any) {
        showToast(err.message || 'Failed to save sleep guide', 'error');
    } finally {
        setSubmitting(false);
    }
};

    const handleDeleteConfirm = async () => {
        if (!itemToDelete || !itemToDelete.parentId) return;
        setSubmitting(true);
        try {
            await cmsClient.delete('sleep', itemToDelete.parentId);
            setIsDeleteModalOpen(false);
            setSuccessModal({
                open: true,
                title: 'Sleep Tip Deleted',
                message: `Sleep tip "${itemToDelete.sleepType}" was deleted.`
            });
            setItemToDelete(null);
            await loadData();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete sleep tip', 'error');
        } finally {
            setSubmitting(false);
        }
    };

    const getActiveCardLang = (id: string) => cardLang[id] || 'en';
    const setCardLanguage = (id: string, lang: 'en' | 'or' | 'so' | 'am') => {
        setCardLang(prev => ({ ...prev, [id]: lang }));
    };

    // Ensure the currently selected emoji always shows in the dropdown,
    // even if it isn't one of the predefined options (e.g. legacy data).
    const emojiSelectOptions = SLEEP_EMOJI_OPTIONS.some(o => o.value === formData.emoji)
        ? SLEEP_EMOJI_OPTIONS
        : [{ value: formData.emoji || '🌙', label: 'Current' }, ...SLEEP_EMOJI_OPTIONS];

    return (
        <div className="space-y-6 max-w-7xl mx-auto pb-12 px-2 sm:px-4">

            {/* HEADER BAR */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-gray-100 shadow-sm">
                <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#1e1b4b] to-[#312e81] text-white flex items-center justify-center shrink-0 shadow-md">
                        <Moon className="w-6 h-6" />
                    </div>
                    <div>
                        <h1 className="text-xl font-bold text-gray-900 leading-tight">Sleep Guide & Positions Manager</h1>
                        <p className="text-xs text-gray-500">Manage safe sleeping positions, pillows, why important & tips in 4 languages.</p>
                    </div>
                </div>

                <Button
                    onClick={handleOpenAddModal}
                    className="bg-[#312e81] hover:bg-[#1e1b4b] text-white font-semibold flex items-center gap-2 px-5 py-2.5 rounded-xl shadow-md transition-all hover:scale-[1.02]"
                >
                    <PlusCircle className="w-5 h-5" />
                    + Add Sleep Guide
                </Button>
            </div>

            {/* FILTER BAR */}
            <Card className="p-4 space-y-4 bg-white border border-gray-100 shadow-sm rounded-2xl">
                <div className="flex items-center gap-2 text-xs font-bold text-gray-700 uppercase tracking-wider">
                    <Filter className="w-4 h-4 text-[#312e81]" />
                    Filter Sleep Guides
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
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

                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Week</label>
                        <select
                            value={filterWeek}
                            onChange={e => setFilterWeek(e.target.value)}
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
                        >
                            <option value="all">All Weeks</option>
                            {(createdWeeks.length > 0 ? createdWeeks : Array.from({ length: 40 }, (_, i) => i + 1)).map(w => (
                                <option key={w} value={w}>Week {w}</option>
                            ))}
                        </select>
                    </div>

                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Type</label>
                        <select
                            value={filterType}
                            onChange={e => setFilterType(e.target.value)}
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
                        >
                            <option value="all">All Sleep Types</option>
                            <option value="recommended">✅ How to Sleep (Recommended)</option>
                            <option value="avoid">🚫 How NOT to Sleep (Avoid)</option>
                            <option value="tip">💡 Sleep Position Tip</option>
                        </select>
                    </div>

                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Search</label>
                        <div className="relative">
                            <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                            <input
                                type="text"
                                placeholder="Search sleep guide..."
                                value={searchQuery}
                                onChange={e => setSearchQuery(e.target.value)}
                                className="w-full pl-8 pr-3 py-2 text-xs border border-gray-200 rounded-xl focus:outline-none focus:border-[#312e81]"
                            />
                        </div>
                    </div>
                </div>
            </Card>

            {/* LIST CARDS */}
            {loading ? (
                <div className="flex flex-col items-center justify-center p-16 text-gray-400 bg-white rounded-2xl border border-gray-100">
                    <Loader2 className="w-8 h-8 animate-spin text-[#312e81] mb-2" />
                    <p className="text-sm font-medium">Loading sleep position guides...</p>
                </div>
            ) : filteredSleepList.length === 0 ? (
                <div className="text-center p-16 bg-white rounded-2xl border border-gray-100">
                    <Moon className="w-12 h-12 mx-auto text-gray-300 mb-3" />
                    <p className="text-gray-600 font-semibold text-base">No Sleep Guides Found</p>
                    <p className="text-gray-400 text-xs mt-1">Try adjusting your filters or click "+ Add Sleep Guide" to create one.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                    {filteredSleepList.map((item) => {
                        const lang = getActiveCardLang(item.id || '');
                        const title = lang === 'en' ? item.titleEn : lang === 'or' ? item.titleOr : lang === 'so' ? item.titleSo : item.titleAm;
                        const body = lang === 'en' ? item.bodyEn : lang === 'or' ? item.bodyOr : lang === 'so' ? item.bodySo : item.bodyAm;
                        const whyImp = lang === 'en' ? item.whyImportantEn : lang === 'or' ? item.whyImportantOr : lang === 'so' ? item.whyImportantSo : item.whyImportantAm;
                        const tipsText = lang === 'en' ? item.tipsEn : lang === 'or' ? item.tipsOr : lang === 'so' ? item.tipsSo : item.tipsAm;
                        const benefitValue = lang === 'en' ? item.benefitValueEn : lang === 'or' ? item.benefitValueOr : lang === 'so' ? item.benefitValueSo : item.benefitValueAm;
                        const benefitLabel = lang === 'en' ? item.benefitLabelEn : lang === 'or' ? item.benefitLabelOr : lang === 'so' ? item.benefitLabelSo : item.benefitLabelAm;

                        return (
                            <Card key={item.id} className="p-5 flex flex-col justify-between space-y-4 hover:shadow-md transition-all border border-gray-100 rounded-2xl">
                                <div className="space-y-3">
                                    <div className="flex items-start justify-between gap-2">
                                        <div className="flex items-center gap-2">
                                            <span className="text-2xl">{item.emoji}</span>
                                            <div>
                                                <h3 className="font-bold text-gray-900 text-base">{item.sleepType}</h3>
                                                <div className="flex items-center gap-2 mt-0.5">
                                                    <span className="text-[11px] font-semibold px-2 py-0.5 rounded-md bg-indigo-50 text-indigo-700">
                                                        Week {item.week} ({item.trimester} Tri.)
                                                    </span>
                                                    <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-md ${item.type === 'avoid' ? 'bg-red-50 text-red-700' : 'bg-emerald-50 text-emerald-700'}`}>
                                                        {item.type === 'avoid' ? '🚫 Avoid' : '✅ Recommended'}
                                                    </span>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Language switcher tabs on card */}
                                        <div className="flex bg-gray-100 p-0.5 rounded-lg text-[10px] font-bold">
                                            {(['en', 'or', 'so', 'am'] as const).map((l) => (
                                                <button
                                                    key={l}
                                                    onClick={() => setCardLanguage(item.id || '', l)}
                                                    className={`px-2 py-1 rounded-md uppercase transition-all ${lang === l ? 'bg-white text-indigo-900 shadow-sm' : 'text-gray-400 hover:text-gray-700'}`}
                                                >
                                                    {l}
                                                </button>
                                            ))}
                                        </div>
                                    </div>

                                    {/* Content preview */}
                                    <div className="bg-gray-50/70 p-3 rounded-xl space-y-2 border border-gray-100 text-xs">
                                        {title && <p className="font-bold text-gray-800">{title}</p>}
                                        <p className="text-gray-600 leading-relaxed">{body || 'No description provided for this language.'}</p>

                                        {whyImp && (
                                            <div className="pt-1 text-[11px] text-amber-800 font-medium flex items-start gap-1">
                                                <HelpCircle className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                                                <span><strong>Why Important:</strong> {whyImp}</span>
                                            </div>
                                        )}

                                        {tipsText && (
                                            <div className="text-[11px] text-teal-800 font-medium flex items-start gap-1">
                                                <HeartPulse className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                                                <span><strong>Health Tips:</strong> {tipsText}</span>
                                            </div>
                                        )}

                                        {(benefitValue || item.sleepDuration) && (
                                            <div className="pt-1 flex flex-wrap items-center gap-2">
                                                {benefitValue && (
                                                    <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-indigo-100 text-indigo-800">
                                                        {benefitLabel ? `${benefitLabel}: ` : ''}{benefitValue}
                                                    </span>
                                                )}
                                                {item.sleepDuration && (
                                                    <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-gray-100 text-gray-700">
                                                        ⏱ {item.sleepDuration}
                                                    </span>
                                                )}
                                            </div>
                                        )}
                                    </div>

                                    {/* Media preview & items count */}
                                    <div className="flex items-center justify-between text-xs text-gray-500 pt-1">
                                        <div className="flex items-center gap-3">
                                            {item.imageUrl && (
                                                <span className="flex items-center gap-1 text-indigo-600 font-medium">
                                                    <ImageIcon className="w-3.5 h-3.5" /> Image
                                                </span>
                                            )}
                                            {item.videoUrl && (
                                                <span className="flex items-center gap-1 text-purple-600 font-medium">
                                                    <VideoIcon className="w-3.5 h-3.5" /> Video
                                                </span>
                                            )}
                                        </div>
                                        <span className="font-semibold bg-gray-100 text-gray-700 px-2 py-0.5 rounded-full text-[10px]">
                                            {item.items.length} Sleeping Position Items
                                        </span>
                                    </div>
                                </div>

                                {/* Actions */}
                                <div className="flex items-center justify-end gap-2 pt-3 border-t border-gray-100">
                                    <Button
                                        size="sm"
                                        variant="secondary"
                                        onClick={() => handleOpenEditModal(item)}
                                        className="text-xs flex items-center gap-1"
                                    >
                                        <Edit2 className="w-3.5 h-3.5" /> Edit
                                    </Button>
                                    <Button
                                        size="sm"
                                        variant="danger"
                                        onClick={() => handleOpenDeleteModal(item)}
                                        className="text-xs flex items-center gap-1"
                                    >
                                        <Trash2 className="w-3.5 h-3.5" /> Delete
                                    </Button>
                                </div>
                            </Card>
                        );
                    })}
                </div>
            )}

            {/* ADD / EDIT MODAL */}
            <Modal
                isOpen={isAddModalOpen || isEditModalOpen}
                onClose={() => { setIsAddModalOpen(false); setIsEditModalOpen(false); }}
                title={isEditModalOpen ? 'Edit Sleep Position Guide' : 'Add New Sleep Position Guide'}
                size="xl"
            >
                <form onSubmit={handleSaveSleep} className="space-y-5">
                    {/* SECTION 1: CONTEXT (Week, Trimester, Month, Type) */}
                    <div className="p-4 bg-indigo-50/50 rounded-2xl border border-indigo-100 space-y-4">
                        <h4 className="text-xs font-bold text-[#312e81] uppercase tracking-wider flex items-center gap-2">
                            <Calendar className="w-4 h-4" />
                            1. Select Pregnancy Week & Guide Type
                        </h4>

                        <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                            <div className="sm:col-span-2">
                                <label className="block text-xs font-bold text-gray-700 mb-1">
                                    Pregnancy Week * {createdWeeks.length > 0 ? `(${createdWeeks.length} Created Weeks)` : ''}
                                </label>
                                <select
                                    value={formData.week}
                                    onChange={e => handleWeekChangeInForm(Number(e.target.value))}
                                    className="w-full text-xs font-semibold rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
                                >
                                    {(
                                        createdWeeks.length > 0
                                            ? (createdWeeks.includes(formData.week) ? createdWeeks : [...createdWeeks, formData.week].sort((a,b) => a-b))
                                            : Array.from({ length: 40 }, (_, i) => i + 1)
                                    ).map(w => {
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
                                <label className="block text-xs font-bold text-gray-700 mb-1">Guide Type *</label>
                                <select
                                    value={formData.type}
                                    onChange={e => setFormData(prev => ({ ...prev, type: e.target.value as any }))}
                                    className="w-full text-xs font-semibold rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#312e81]"
                                >
                                    <option value="recommended">✅ How to Sleep (Recommended)</option>
                                    <option value="avoid">🚫 How NOT to Sleep (Avoid)</option>
                                    <option value="tip">💡 Sleep Position Tip</option>
                                </select>
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-700 mb-1">Calculated Info</label>
                                <div className="text-xs bg-white p-2.5 rounded-xl border border-gray-200 font-semibold text-gray-600 flex items-center justify-between">
                                    <span>Month {formData.month}</span>
                                    <span className={`px-2 py-0.5 rounded text-[10px] ${TRIMESTER_BADGE_STYLE[formData.trimester] || 'bg-gray-100 text-gray-700'}`}>
                                        {formData.trimester} Trim
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
    
                        <div>
                            <label className="block text-xs font-semibold text-gray-700 mb-1">Icon</label>
                            <select
                                value={formData.emoji}
                                onChange={e => setFormData(prev => ({ ...prev, emoji: e.target.value }))}
                                className="w-full text-xs p-2 border border-gray-300 rounded-lg text-center bg-white focus:outline-none focus:border-[#312e81]"
                            >
                                {emojiSelectOptions.map(opt => (
                                    <option key={opt.value} value={opt.value}>
                                        {opt.value}  {opt.label}
                                    </option>
                                ))}
                            </select>
                        </div>
                      
                    </div>

                    {/* Media Uploads */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <MediaInput
                            label="Main Cover Image URL"
                            value={formData.imageUrl || ''}
                            onChange={url => setFormData(prev => ({ ...prev, imageUrl: url }))}
                            type="image"
                        />
                        
                    </div>

                    {/* Language Switch Tabs for Multilingual Inputs */}
                    <div className="border border-gray-200 rounded-xl overflow-hidden">
                        <div className="flex bg-gray-100 border-b border-gray-200">
                            {[
                                { key: 'en', label: '🇬🇧 English' },
                                { key: 'or', label: '🇪🇹 Afan Oromo' },
                                { key: 'so', label: '🇸🇴 Somali' },
                                { key: 'am', label: '🇪🇹 Amharic' },
                            ].map(tab => (
                                <button
                                    key={tab.key}
                                    type="button"
                                    onClick={() => setActiveLangTab(tab.key as any)}
                                    className={`flex-1 py-2.5 text-xs font-bold transition-colors ${activeLangTab === tab.key ? 'bg-white text-[#312e81] border-b-2 border-[#312e81]' : 'text-gray-500 hover:text-gray-800'}`}
                                >
                                    {tab.label}
                                </button>
                            ))}
                        </div>

                        <div className="p-4 bg-white space-y-4">
                            {activeLangTab === 'en' && (
                                <>
                                    <Input
                                        label="Title (English)"
                                        value={formData.titleEn}
                                        onChange={e => setFormData(prev => ({ ...prev, titleEn: e.target.value }))}
                                        placeholder="Sleep position title in English..."
                                    />
                                    <TextArea
                                        label="Full Description (English)"
                                        value={formData.bodyEn}
                                        onChange={e => setFormData(prev => ({ ...prev, bodyEn: e.target.value }))}
                                        rows={3}
                                        placeholder="Detailed description of safe sleeping posture..."
                                    />
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <TextArea
                                            label="Why it is Important (English)"
                                            value={formData.whyImportantEn}
                                            onChange={e => setFormData(prev => ({ ...prev, whyImportantEn: e.target.value }))}
                                            rows={2}
                                            placeholder="Increases blood flow to uterus and kidneys..."
                                        />
                                        <TextArea
                                            label="Health Tips (English)"
                                            value={formData.tipsEn}
                                            onChange={e => setFormData(prev => ({ ...prev, tipsEn: e.target.value }))}
                                            rows={2}
                                            placeholder="Use a pillow between knees to support hips..."
                                        />
                                    </div>
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <Input
                                            label="Description Value (English)"
                                            value={formData.benefitValueEn || ''}
                                            onChange={e => setFormData(prev => ({ ...prev, benefitValueEn: e.target.value }))}
                                            placeholder="e.g. 8 Hours / Night"
                                        />
                                        <Input
                                            label="Description Label (English)"
                                            value={formData.benefitLabelEn || ''}
                                            onChange={e => setFormData(prev => ({ ...prev, benefitLabelEn: e.target.value }))}
                                            placeholder="e.g. Recommended Sleep Duration"
                                        />
                                    </div>
                                </>
                            )}

                            {activeLangTab === 'or' && (
                                <>
                                    <Input
                                        label="Title (Afan Oromo)"
                                        value={formData.titleOr}
                                        onChange={e => setFormData(prev => ({ ...prev, titleOr: e.target.value }))}
                                        placeholder="Mata duree rafii..."
                                    />
                                    <TextArea
                                        label="Full Description (Afan Oromo)"
                                        value={formData.bodyOr}
                                        onChange={e => setFormData(prev => ({ ...prev, bodyOr: e.target.value }))}
                                        rows={3}
                                        placeholder="Ibsa guutuu teessuma rafii..."
                                    />
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <TextArea
                                            label="Why it is Important (Afan Oromo)"
                                            value={formData.whyImportantOr}
                                            onChange={e => setFormData(prev => ({ ...prev, whyImportantOr: e.target.value }))}
                                            rows={2}
                                            placeholder="Maaliif barbaachisaa ta'e..."
                                        />
                                        <TextArea
                                            label="Health Tips (Afan Oromo)"
                                            value={formData.tipsOr}
                                            onChange={e => setFormData(prev => ({ ...prev, tipsOr: e.target.value }))}
                                            rows={2}
                                            placeholder="Gorsa fayyaa..."
                                        />
                                    </div>
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <Input
                                            label="Description Value (Afan Oromo)"
                                            value={formData.benefitValueOr || ''}
                                            onChange={e => setFormData(prev => ({ ...prev, benefitValueOr: e.target.value }))}
                                            placeholder="fkn. Sa'aatii 8 / Halkan"
                                        />
                                        <Input
                                            label="Description Label (Afan Oromo)"
                                            value={formData.benefitLabelOr || ''}
                                            onChange={e => setFormData(prev => ({ ...prev, benefitLabelOr: e.target.value }))}
                                            placeholder="Sadarkaa barbaachisummaa"
                                        />
                                    </div>
                                </>
                            )}

                            {activeLangTab === 'so' && (
                                <>
                                    <Input
                                        label="Title (Somali)"
                                        value={formData.titleSo}
                                        onChange={e => setFormData(prev => ({ ...prev, titleSo: e.target.value }))}
                                        placeholder="Cinwaanka jiifka..."
                                    />
                                    <TextArea
                                        label="Full Description (Somali)"
                                        value={formData.bodySo}
                                        onChange={e => setFormData(prev => ({ ...prev, bodySo: e.target.value }))}
                                        rows={3}
                                        placeholder="Faahfaahinta jiifka..."
                                    />
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <TextArea
                                            label="Why it is Important (Somali)"
                                            value={formData.whyImportantSo}
                                            onChange={e => setFormData(prev => ({ ...prev, whyImportantSo: e.target.value }))}
                                            rows={2}
                                            placeholder="Sababta ay muhiim u tahay..."
                                        />
                                        <TextArea
                                            label="Health Tips (Somali)"
                                            value={formData.tipsSo}
                                            onChange={e => setFormData(prev => ({ ...prev, tipsSo: e.target.value }))}
                                            rows={2}
                                            placeholder="Talooyin caafimaad..."
                                        />
                                    </div>
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <Input
                                            label="Description Value (Somali)"
                                            value={formData.benefitValueSo || ''}
                                            onChange={e => setFormData(prev => ({ ...prev, benefitValueSo: e.target.value }))}
                                            placeholder="tusaale. 8 Saacadood / Habeen"
                                        />
                                        <Input
                                            label="Description Label (Somali)"
                                            value={formData.benefitLabelSo || ''}
                                            onChange={e => setFormData(prev => ({ ...prev, benefitLabelSo: e.target.value }))}
                                            placeholder="Waqtiga lagu talinayo"
                                        />
                                    </div>
                                </>
                            )}

                            {activeLangTab === 'am' && (
                                <>
                                    <Input
                                        label="Title (Amharic)"
                                        value={formData.titleAm}
                                        onChange={e => setFormData(prev => ({ ...prev, titleAm: e.target.value }))}
                                        placeholder="የእንቅልፍ አቀማመጥ ርዕስ..."
                                    />
                                    <TextArea
                                        label="Full Description (Amharic)"
                                        value={formData.bodyAm}
                                        onChange={e => setFormData(prev => ({ ...prev, bodyAm: e.target.value }))}
                                        rows={3}
                                        placeholder="ሙሉ መግለጫ..."
                                    />
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <TextArea
                                            label="Why it is Important (Amharic)"
                                            value={formData.whyImportantAm}
                                            onChange={e => setFormData(prev => ({ ...prev, whyImportantAm: e.target.value }))}
                                            rows={2}
                                            placeholder="ለምን አስፈላጊ እንደሆነ..."
                                        />
                                        <TextArea
                                            label="Health Tips (Amharic)"
                                            value={formData.tipsAm}
                                            onChange={e => setFormData(prev => ({ ...prev, tipsAm: e.target.value }))}
                                            rows={2}
                                            placeholder="የጤና ምክሮች..."
                                        />
                                    </div>
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <Input
                                            label="Description Value (Amharic)"
                                            value={formData.benefitValueAm || ''}
                                            onChange={e => setFormData(prev => ({ ...prev, benefitValueAm: e.target.value }))}
                                            placeholder="ለምሳሌ 8 ሰዓት / ሌሊት"
                                        />
                                        <Input
                                            label="Description Label (Amharic)"
                                            value={formData.benefitLabelAm || ''}
                                            onChange={e => setFormData(prev => ({ ...prev, benefitLabelAm: e.target.value }))}
                                            placeholder="ምክር መለያ"
                                        />
                                    </div>
                                </>
                            )}
                        </div>
                    </div>

                    {/* DYNAMIC SLEEP ITEMS LIST */}
                    <div className="space-y-3 pt-2">
                        <div className="flex items-center justify-between">
                            <h4 className="text-xs font-bold text-gray-800 uppercase tracking-wider">
                                Sleeping Position Items & Variations List ({formData.items.length})
                            </h4>
                            <Button type="button" size="sm" variant="secondary" onClick={handleAddItem} className="text-xs">
                                + Add Position Item
                            </Button>
                        </div>

                        {formData.items.map((item, idx) => (
                            <div key={idx} className="p-3 bg-gray-50 border border-gray-200 rounded-xl space-y-3 relative">
                                <button
                                    type="button"
                                    onClick={() => handleRemoveItem(idx)}
                                    className="absolute top-2 right-2 text-red-400 hover:text-red-600 p-1"
                                >
                                    <X className="w-4 h-4" />
                                </button>
                                <p className="text-[11px] font-bold text-indigo-900">Position Item #{idx + 1}</p>

                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                                    <Input
                                        label="Name (English)"
                                        value={item.nameEn}
                                        onChange={e => handleItemChange(idx, 'nameEn', e.target.value)}
                                        placeholder="Left Side Position"
                                    />
                                    <Input
                                        label="Name (Afan Oromo)"
                                        value={item.nameOr}
                                        onChange={e => handleItemChange(idx, 'nameOr', e.target.value)}
                                        placeholder="Maqaa teessuma bitaa..."
                                    />
                                    <Input
                                        label="Name (Somali)"
                                        value={item.nameSo}
                                        onChange={e => handleItemChange(idx, 'nameSo', e.target.value)}
                                        placeholder="Magaca jiifka bidix..."
                                    />
                                    <Input
                                        label="Name (Amharic)"
                                        value={item.nameAm}
                                        onChange={e => handleItemChange(idx, 'nameAm', e.target.value)}
                                        placeholder="በግራ ጎን መተኛት"
                                    />
                                </div>

                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                                    <TextArea
                                        label="Description (English)"
                                        value={item.descEn}
                                        onChange={e => handleItemChange(idx, 'descEn', e.target.value)}
                                        rows={2}
                                    />
                                    <TextArea
                                        label="Description (Afan Oromo)"
                                        value={item.descOr}
                                        onChange={e => handleItemChange(idx, 'descOr', e.target.value)}
                                        rows={2}
                                    />
                                    <TextArea
                                        label="Description (Somali)"
                                        value={item.descSo}
                                        onChange={e => handleItemChange(idx, 'descSo', e.target.value)}
                                        rows={2}
                                    />
                                    <TextArea
                                        label="Description (Amharic)"
                                        value={item.descAm}
                                        onChange={e => handleItemChange(idx, 'descAm', e.target.value)}
                                        rows={2}
                                    />
                                </div>

                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                                    <Input
                                        label="Label (English)"
                                        value={item.labelEn || ''}
                                        onChange={e => handleItemChange(idx, 'labelEn', e.target.value)}
                                        placeholder="e.g. Best Position"
                                    />
                                    <Input
                                        label="Label (Afan Oromo)"
                                        value={item.labelOr || ''}
                                        onChange={e => handleItemChange(idx, 'labelOr', e.target.value)}
                                        placeholder="fkn. Teessuma gaarii"
                                    />
                                    <Input
                                        label="Label (Somali)"
                                        value={item.labelSo || ''}
                                        onChange={e => handleItemChange(idx, 'labelSo', e.target.value)}
                                        placeholder="tusaale. Jiifka ugu fiican"
                                    />
                                    <Input
                                        label="Label (Amharic)"
                                        value={item.labelAm || ''}
                                        onChange={e => handleItemChange(idx, 'labelAm', e.target.value)}
                                        placeholder="ለምሳሌ ምርጥ አቀማመጥ"
                                    />
                                </div>

                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                                    <MediaInput
                                        label="Item Image"
                                        value={item.imageUrl || ''}
                                        onChange={url => handleItemChange(idx, 'imageUrl', url)}
                                        type="image"
                                    />
                                    <MediaInput
                                        label="Item Video"
                                        value={item.videoUrl || ''}
                                        onChange={url => handleItemChange(idx, 'videoUrl', url)}
                                        type="video"
                                    />
                                </div>
                            </div>
                        ))}
                    </div>

                    <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100">
                        <Button type="button" variant="secondary" onClick={() => { setIsAddModalOpen(false); setIsEditModalOpen(false); }}>
                            Cancel
                        </Button>
                        <Button type="submit" className="bg-[#312e81] hover:bg-[#1e1b4b] text-white" disabled={submitting}>
                            {submitting ? 'Saving...' : isEditModalOpen ? 'Update Sleep Guide' : 'Create Sleep Guide'}
                        </Button>
                    </div>
                </form>
            </Modal>

            {/* DELETE MODAL */}
            <Modal isOpen={isDeleteModalOpen} onClose={() => setIsDeleteModalOpen(false)} title="Delete Sleep Position Guide">
                <div className="space-y-4">
                    <p className="text-sm text-gray-600">
                        Are you sure you want to delete <strong>"{itemToDelete?.sleepType}"</strong>? This action cannot be undone.
                    </p>
                    <div className="flex justify-end gap-3 pt-2">
                        <Button variant="secondary" onClick={() => setIsDeleteModalOpen(false)}>Cancel</Button>
                        <Button variant="danger" onClick={handleDeleteConfirm} disabled={submitting}>
                            {submitting ? 'Deleting...' : 'Delete Permanently'}
                        </Button>
                    </div>
                </div>
            </Modal>

            {/* SUCCESS MODAL */}
            <Modal isOpen={successModal.open} onClose={() => setSuccessModal(prev => ({ ...prev, open: false }))} title={successModal.title}>
                <div className="space-y-4 text-center py-2">
                    <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto" />
                    <p className="text-sm text-gray-600">{successModal.message}</p>
                    <Button className="w-full bg-[#312e81] text-white" onClick={() => setSuccessModal(prev => ({ ...prev, open: false }))}>
                        Awesome
                    </Button>
                </div>
            </Modal>
        </div>
    );
}