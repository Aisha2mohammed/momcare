import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
    PlusCircle, Search, X, Utensils, CheckCircle2,
    Edit2, Trash2, Eye, EyeOff, Loader2, Sparkles, Filter,
    BookOpen, Image as ImageIcon, Video as VideoIcon,
    Calendar, AlertTriangle
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

export interface FoodItem {
    labelSo: string | number | readonly string[];
    labelOr: string | number | readonly string[];
    labelAm: string | number | readonly string[];
    labelEn: string | number | readonly string[];
    id?: string;
    nameEn: string;
    nameOr: string;
    nameSo: string;
    nameAm: string;
    descEn: string;
    descOr: string;
    descSo: string;
    descAm: string;
    imageUrl?: string;
    videoUrl?: string;
}

export interface NutrientSection {
    healthTipsAm: string;
    healthTipsOr: string;
    healthTipsSo: string;
    healthTipsEn: string;
    id?: string;
    parentId?: string | number; // Parent nutrition_content row ID
    week: number;
    trimester: string; // '1st' | '2nd' | '3rd'
    month: number;
    type: 'eat' | 'avoid';
    nutrientType: string;
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

    // Media
    imageUrl?: string;
    videoUrl?: string;

    // Benefit Value (4 languages) & Labels (4 languages)
    benefitValueEn?: string;
    benefitValueOr?: string;
    benefitValueSo?: string;
    benefitValueAm?: string;
    benefitLabelEn?: string;
    benefitLabelOr?: string;
    benefitLabelSo?: string;
    benefitLabelAm?: string;
    // Why Important (4 Languages)
    whyImportantEn?: string;
    whyImportantOr?: string;
    whyImportantSo?: string;
    whyImportantAm?: string;

    // Health Tips (multi-language array from API, stored as single EN string in form)
    healthTips?: string;

    // Foods List
    foods: FoodItem[];
}

// Use a flexible record type to avoid TypeScript errors on dynamic backend field names
type BackendNutritionRow = Record<string, any> & {
    id: string | number;
    type?: 'eat' | 'avoid';
    is_published?: boolean;
    isPublished?: boolean;
};

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

// Icon dropdown options for nutrient type — selecting one sets both emoji + nutrient name
const NUTRIENT_OPTIONS: { emoji: string; label: string }[] = [
    { emoji: '🥩', label: 'Iron' },
    { emoji: '🥛', label: 'Calcium' },
    { emoji: '🍳', label: 'Protein' },
    { emoji: '🍊', label: 'Vitamin C' },
    { emoji: '🌾', label: 'Folate / Folic Acid' },
    { emoji: '☀️', label: 'Vitamin D' },
    { emoji: '🐟', label: 'Omega-3 / DHA' },
    { emoji: '💧', label: 'Hydration / Water' },
    { emoji: '🥗', label: 'Fiber' },
    { emoji: '🧂', label: 'Sodium' },
    { emoji: '🍬', label: 'Sugar' },
    { emoji: '☕', label: 'Caffeine' },
    { emoji: '🍷', label: 'Alcohol' },
    { emoji: '🐠', label: 'Mercury / High-Mercury Fish' },
    { emoji: '🥑', label: 'Healthy Fats' },
    { emoji: '🍌', label: 'Potassium' },
    { emoji: '🧀', label: 'Vitamin B12' },
    { emoji: '🥕', label: 'Vitamin A' },
    { emoji: '🚫', label: 'General Avoid' },
];

const EMPTY_NUTRIENT: Omit<NutrientSection, 'id'> = {
    week: 1,
    trimester: '1st',
    month: 1,
    type: 'eat',
    nutrientType: NUTRIENT_OPTIONS[0].label,
    emoji: NUTRIENT_OPTIONS[0].emoji,
    isPublished: true,
    titleEn: '',
    titleOr: '',
    titleSo: '',
    titleAm: '',
    bodyEn: '',
    bodyOr: '',
    bodySo: '',
    bodyAm: '',
    imageUrl: '',
    videoUrl: '',
    benefitValueEn: '',
    benefitValueOr: '',
    benefitValueSo: '',
    benefitValueAm: '',
    benefitLabelEn: '',
    benefitLabelOr: '',
    benefitLabelSo: '',
    benefitLabelAm: '',
    whyImportantEn: '',
    whyImportantOr: '',
    whyImportantSo: '',
    whyImportantAm: '',
    healthTipsEn: '',
    healthTipsOr: '',
    healthTipsSo: '',
    healthTipsAm: '',
    foods: [],
};

const EMPTY_FOOD: FoodItem = {
    nameEn: '', nameOr: '', nameSo: '', nameAm: '',
    descEn: '', descOr: '', descSo: '', descAm: '',
    labelEn : '', labelOr: '', labelSo: '', labelAm: '',
    imageUrl: '', videoUrl: ''
};

// ─────────────────────────────────────────────────────────────────────────────
// Component
// ─────────────────────────────────────────────────────────────────────────────

export default function AddNutritionPage() {
    const { showToast } = useToast();

    // State
    const [rawRows, setRawRows] = useState<BackendNutritionRow[]>([]);
    const [loading, setLoading] = useState(true);

    // Filters
    const [filterTrimester, setFilterTrimester] = useState<string>('all');
    const [filterMonth, setFilterMonth] = useState<string>('all');
    const [filterWeek, setFilterWeek] = useState<string>('all');
    const [filterType, setFilterType] = useState<string>('all');
    const [searchQuery, setSearchQuery] = useState<string>('');

    // Modals
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);

    // Active Nutrient for Add/Edit/Delete
    const [formData, setFormData] = useState<NutrientSection>({ ...EMPTY_NUTRIENT });
    const [nutrientToDelete, setNutrientToDelete] = useState<NutrientSection | null>(null);
    const [submitting, setSubmitting] = useState(false);

    // Success Modal Feedback
    const [successModal, setSuccessModal] = useState<{ open: boolean; title: string; message: string }>({
        open: false, title: '', message: ''
    });

    // ─── Nutrition Weeks (for dropdown) ──────────────────────────────────────
    const [nutritionWeeks, setNutritionWeeks] = useState<{id: number; week: number; month: number; trimester: string}[]>([]);

    useEffect(() => {
        cmsClient.list('nutrition-weeks', { limit: 500 }).then(res => {
            const rows = res.items || [];
            setNutritionWeeks(rows.map((r: any) => ({
                id: Number(r.id),
                week: Number(r.week),
                month: Number(r.month),
                trimester: r.trimester || '',
            })));
            // Set form default to first week
            if (rows.length > 0) {
                const first = rows[0];
                setFormData(prev => ({ ...prev, week: Number(first.id), month: Number(first.month), trimester: String(first.trimester) }));
            }
        }).catch(() => {});
    }, []);
    const [cardLang, setCardLang] = useState<Record<string, 'en' | 'or' | 'so' | 'am'>>({});

    // ── Fetch Data ────────────────────────────────────────────────────────────
    const loadNutritionData = useCallback(async () => {
        setLoading(true);
        try {
            const res = await cmsClient.list<BackendNutritionRow>('nutrition-tips', { limit: 500 });
            setRawRows(res.items || []);
        } catch (err: any) {
            showToast(err.message || 'Failed to load nutrients', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        loadNutritionData();
    }, [loadNutritionData]);

    // ── Flatten Rows into Individual Nutrient Cards ───────────────────────────
    const nutrientsList = useMemo(() => {
        const list: NutrientSection[] = [];

        rawRows.forEach(row => {
            // Backend localize() returns: id, type, nutrition_week_id, trimester, month, week,
            // image_url, title, description, description_label, description_value, why_important,
            // health_tips (array), list_food (array)
            const weekNum = Number(row.week || row.nutritionWeekId || row.nutrition_week_id || 1);
            const { month, trimester } = calculateMonthAndTrimester(weekNum);
            const rowMonth = Number(row.month || month);
            const rowTrimester = String(row.trimester || trimester);
            const isPub = row.is_published ?? row.isPublished ?? true;

            // Parse listFood
           // Parse listFood — use the RAW multi-language version, not the localized flat one
// Parse listFood — MUST use the raw multi-language version, not the flattened one,
// or name/description/label will only ever populate for the requested locale (usually EN).
let listFood: any[] = [];
const rawListFood = row.list_food_raw || row.listFoodRaw || row.list_food || row.listFood;
if (Array.isArray(rawListFood)) listFood = rawListFood;
else if (typeof rawListFood === 'string') { try { listFood = JSON.parse(rawListFood); } catch { listFood = []; } }

// Parse healthTips — same fix: use the raw multi-language version
let rawTipsFull: any[] = [];
const rawTipsSource = row.health_tips_raw || row.healthTipsRaw || row.health_tips || row.healthTips;
if (Array.isArray(rawTipsSource)) rawTipsFull = rawTipsSource;
else if (typeof rawTipsSource === 'string') { try { rawTipsFull = JSON.parse(rawTipsSource); } catch { rawTipsFull = []; } }

const firstTip = rawTipsFull.length > 0 ? rawTipsFull[0] : null;

// Fallback display string (used only if no per-language field exists yet)
let healthTipStr = '';
if (rawTipsFull.length > 0) {
    healthTipStr = rawTipsFull.map((t: any) => {
        if (typeof t === 'string') return t;
        return t?.label?.en || '';
    }).filter(Boolean).join(' | ');
}

            const foodsList: FoodItem[] = listFood.map((f: any, fi: number) => ({
    id: f.id || `f-${fi}`,
    nameEn: f.name?.en || f.nameEn || (typeof f.name === 'string' ? f.name : '') || '',
    nameAm: f.name?.am || f.nameAm || '',
    nameOr: f.name?.or || f.nameOr || '',
    nameSo: f.name?.so || f.nameSo || '',
    descEn: f.description?.en || f.descEn || (typeof f.description === 'string' ? f.description : '') || '',
    descAm: f.description?.am || f.descAm || '',
    descOr: f.description?.or || f.descOr || '',
    descSo: f.description?.so || f.descSo || '',
    labelEn: f.label?.en || f.labelEn || (typeof f.label === 'string' ? f.label : '') || '',
    labelAm: f.label?.am || f.labelAm || '',
    labelOr: f.label?.or || f.labelOr || '',
    labelSo: f.label?.so || f.labelSo || '',
    imageUrl: f.image?.url || f.imageUrl || '',
    videoUrl: f.video?.url || f.videoUrl || '',
}));

            list.push({
                id: String(row.id),
                week: weekNum,
                trimester: rowTrimester,
                month: rowMonth,
                type: (row.type || 'eat') as 'eat' | 'avoid',
                nutrientType: row.nutrient_type || row.nutrientType || row.description_label || row.title || 'Nutrient',
                emoji: row.emoji || '🥗',
                isPublished: isPub,

                // Title fields — localized response returns 'title', raw fields may also exist
                titleEn: row.title_en || row.titleEn || row.title || '',
                titleOr: row.title_or || row.titleOr || '',
                titleSo: row.title_so || row.titleSo || '',
                titleAm: row.title_am || row.titleAm || '',

                // Body / Description
                bodyEn: row.description_en || row.descriptionEn || row.body_en || row.bodyEn || row.description || '',
                bodyOr: row.description_or || row.descriptionOr || row.body_or || row.bodyOr || '',
                bodySo: row.description_so || row.descriptionSo || row.body_so || row.bodySo || '',
                bodyAm: row.description_am || row.descriptionAm || row.body_am || row.bodyAm || '',

                imageUrl: row.image_url || row.imageUrl || '',
                videoUrl: row.video_url || row.videoUrl || '',

                // Benefit Value (4 languages)
                benefitValueEn: row.description_value_en || row.descriptionValueEn || row.benefit_value_en || row.benefitValueEn || row.benefit_value || row.benefitValue || '',
                benefitValueOr: row.description_value_or || row.descriptionValueOr || row.benefit_value_or || row.benefitValueOr || '',
                benefitValueSo: row.description_value_so || row.descriptionValueSo || row.benefit_value_so || row.benefitValueSo || '',
                benefitValueAm: row.description_value_am || row.descriptionValueAm || row.benefit_value_am || row.benefitValueAm || '',

                // Benefit Label (4 languages)
                benefitLabelEn: row.description_label_en || row.descriptionLabelEn || row.benefit_label_en || row.benefitLabelEn || row.description_label || '',
                benefitLabelOr: row.description_label_or || row.descriptionLabelOr || row.benefit_label_or || row.benefitLabelOr || '',
                benefitLabelSo: row.description_label_so || row.descriptionLabelSo || row.benefit_label_so || row.benefitLabelSo || '',
                benefitLabelAm: row.description_label_am || row.descriptionLabelAm || row.benefit_label_am || row.benefitLabelAm || '',

                // Why Important
                whyImportantEn: row.why_important_en || row.whyImportantEn || row.why_important || '',
                whyImportantOr: row.why_important_or || row.whyImportantOr || '',
                whyImportantSo: row.why_important_so || row.whyImportantSo || '',
                whyImportantAm: row.why_important_am || row.whyImportantAm || '',

              healthTipsEn: firstTip?.label?.en || row.health_tips_en || row.healthTipsEn || healthTipStr || '',
healthTipsOr: firstTip?.label?.or || row.health_tips_or || row.healthTipsOr || '',
healthTipsSo: firstTip?.label?.so || row.health_tips_so || row.healthTipsSo || '',
healthTipsAm: firstTip?.label?.am || row.health_tips_am || row.healthTipsAm || '',
                foods: foodsList,
            });
        });

        return list;
    }, [rawRows]);


    // ── Filter Nutrients List ─────────────────────────────────────────────────
    const filteredNutrients = useMemo(() => {
        return nutrientsList.filter(item => {
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
            // Type Filter
            if (filterType !== 'all') {
                if (item.type !== filterType) return false;
            }
            // Search Query
            if (searchQuery.trim()) {
                const q = searchQuery.toLowerCase().trim();
                const match = (
                    item.nutrientType.toLowerCase().includes(q) ||
                    item.titleEn.toLowerCase().includes(q) ||
                    item.titleAm.toLowerCase().includes(q) ||
                    item.titleOr.toLowerCase().includes(q) ||
                    item.titleSo.toLowerCase().includes(q) ||
                    item.bodyEn.toLowerCase().includes(q) ||
                    item.bodyAm.toLowerCase().includes(q) ||
                    item.emoji.includes(q) ||
                    `week ${item.week}`.includes(q) ||
                    `month ${item.month}`.includes(q)
                );
                if (!match) return false;
            }
            return true;
        });
    }, [nutrientsList, filterTrimester, filterMonth, filterWeek, filterType, searchQuery]);

    // ── Handlers for Modal Form ───────────────────────────────────────────────
    const handleOpenAddModal = () => {
        const firstWeek = nutritionWeeks[0];
        setFormData({
            ...EMPTY_NUTRIENT,
            week: firstWeek ? firstWeek.id : 1,
            month: firstWeek ? firstWeek.month : 1,
            trimester: firstWeek ? firstWeek.trimester : '1st',
            foods: [{ ...EMPTY_FOOD }],
        });
        setIsAddModalOpen(true);
    };

    const handleOpenEditModal = (nutrient: NutrientSection) => {
        setFormData({
            ...nutrient,
            foods: nutrient.foods.length > 0 ? nutrient.foods.map(f => ({ ...f })) : [{ ...EMPTY_FOOD }],
        });
        setIsEditModalOpen(true);
    };

    const handleOpenDeleteModal = (nutrient: NutrientSection) => {
        setNutrientToDelete(nutrient);
        setIsDeleteModalOpen(true);
    };

    const handleWeekChangeInForm = (weekId: number) => {
        const wk = nutritionWeeks.find(w => w.id === weekId);
        setFormData(prev => ({
            ...prev,
            week: weekId,
            month: wk ? wk.month : prev.month,
            trimester: wk ? wk.trimester : prev.trimester,
        }));
    };

    // Handle nutrient icon dropdown — sets both emoji and nutrientType (name) together
    const handleNutrientOptionChange = (label: string) => {
        const opt = NUTRIENT_OPTIONS.find(o => o.label === label);
        setFormData(prev => ({
            ...prev,
            nutrientType: opt ? opt.label : label,
            emoji: opt ? opt.emoji : prev.emoji,
        }));
    };

    // Food array management inside form
    const handleAddFood = () => {
        setFormData(prev => ({
            ...prev,
            foods: [...prev.foods, { ...EMPTY_FOOD }],
        }));
    };

    const handleRemoveFood = (idx: number) => {
        setFormData(prev => ({
            ...prev,
            foods: prev.foods.filter((_, i) => i !== idx),
        }));
    };

    const handleFoodChange = (idx: number, field: keyof FoodItem, val: string) => {
        setFormData(prev => {
            const nextFoods = [...prev.foods];
            nextFoods[idx] = { ...nextFoods[idx], [field]: val };
            return { ...prev, foods: nextFoods };
        });
    };

    // ── Save / Update Action ─────────────────────────────────────────────────
    const handleSaveNutrient = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!formData.nutrientType.trim()) {
            showToast('Please select a Nutrient Icon (e.g. Iron, Protein)', 'error');
            return;
        }

        setSubmitting(true);
        try {
            const payload = {
                type: formData.type,
                nutritionWeekId: formData.week, // this is now the DB id of nutrition_weeks row
                imageUrl: formData.imageUrl || '',
                titleEn: formData.titleEn,
                titleAm: formData.titleAm,
                titleOr: formData.titleOr,
                titleSo: formData.titleSo,
                descriptionEn: formData.bodyEn,
                descriptionAm: formData.bodyAm,
                descriptionOr: formData.bodyOr,
                descriptionSo: formData.bodySo,
                descriptionLabelEn: formData.benefitLabelEn || 'Nutrient',
                descriptionLabelAm: formData.benefitLabelAm || 'ንጥረ ነገር',
                descriptionLabelOr: formData.benefitLabelOr || 'Nyaata Madaalawaa',
                descriptionLabelSo: formData.benefitLabelSo || 'Nafaqada',
                descriptionValueEn: formData.benefitValueEn || '',
                descriptionValueAm: formData.benefitValueAm || '',
                descriptionValueOr: formData.benefitValueOr || '',
                descriptionValueSo: formData.benefitValueSo || '',
                whyImportantEn: formData.whyImportantEn || '',
                whyImportantAm: formData.whyImportantAm || '',
                whyImportantOr: formData.whyImportantOr || '',
                whyImportantSo: formData.whyImportantSo || '',
              healthTips: (formData.healthTipsEn || formData.healthTipsAm || formData.healthTipsOr || formData.healthTipsSo) ? [
    {
        label: {
            en: formData.healthTipsEn || '',
            am: formData.healthTipsAm || '',
            or: formData.healthTipsOr || '',
            so: formData.healthTipsSo || ''
        }
    }
] : [],
                listFood: formData.foods.map(f => ({
                    type: formData.type,
                    name: { en: f.nameEn, am: f.nameAm, or: f.nameOr, so: f.nameSo },
                    description: { en: f.descEn, am: f.descAm, or: f.descOr, so: f.descSo },
                    label: {
                        en: formData.type === 'eat' ? 'Recommended' : 'Avoid',
                        am: formData.type === 'eat' ? 'የሚመከር' : 'ያስወግዱ',
                        or: formData.type === 'eat' ? 'Kan gorfamu' : 'Irraa Fagaadhaa',
                        so: formData.type === 'eat' ? 'La talinayo' : 'Ka fogow'
                    },
                    image: f.imageUrl ? { type: 'url', url: f.imageUrl } : null,
                    video: f.videoUrl ? { type: 'url', url: f.videoUrl } : null
                }))
            };

            if (isEditModalOpen && formData.id) {
                await cmsClient.update('nutrition-tips', formData.id, payload);
                setIsEditModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Nutrient Updated Successfully!',
                    message: `Nutrient "${formData.nutrientType}" for Week ${formData.week} has been updated.`,
                });
            } else {
                await cmsClient.create('nutrition-tips', payload);
                setIsAddModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Nutrient Added Successfully!',
                    message: `New nutrient "${formData.nutrientType}" added to Week ${formData.week}!`,
                });
            }

            await loadNutritionData();
        } catch (err: any) {
            showToast(err.message || 'Failed to save nutrient', 'error');
        } finally {
            setSubmitting(false);
        }
    };

    // ── Delete Action ────────────────────────────────────────────────────────
    const handleDeleteConfirm = async () => {
        if (!nutrientToDelete) return;
        setSubmitting(true);
        try {
            await cmsClient.delete('nutrition-tips', nutrientToDelete.id);

            setIsDeleteModalOpen(false);
            setSuccessModal({
                open: true,
                title: 'Nutrient Deleted',
                message: `Nutrient "${nutrientToDelete.nutrientType}" was successfully deleted.`,
            });
            setNutrientToDelete(null);
            await loadNutritionData();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete nutrient', 'error');
        } finally {
            setSubmitting(false);
        }
    };

    // ── Toggle Publish Action ────────────────────────────────────────────────
    const handleTogglePublish = async (nutrient: NutrientSection) => {
        if (!nutrient.id) return;
        try {
            const newStatus = !nutrient.isPublished;
            await cmsClient.update('nutrition-tips', nutrient.id, {
                isPublished: newStatus,
            });
            showToast(`Status updated to ${newStatus ? 'Published' : 'Draft'}`, 'success');
            await loadNutritionData();
        } catch (err: any) {
            showToast(err.message || 'Failed to update status', 'error');
        }
    };

    // Helper for card language switcher
    const getActiveCardLang = (id: string) => cardLang[id] || 'en';
    const setCardLanguage = (id: string, lang: 'en' | 'or' | 'so' | 'am') => {
        setCardLang(prev => ({ ...prev, [id]: lang }));
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
                        <Utensils className="w-6 h-6" />
                    </div>
                    <div>
                        <h1 className="text-xl font-bold text-gray-900 leading-tight">Nutrient Management</h1>
                        <p className="text-xs text-gray-500">Filter, edit, delete, and add pregnancy nutrients in 4 languages.</p>
                    </div>
                </div>

                <Button
                    onClick={handleOpenAddModal}
                    className="bg-[#61183e] hover:bg-[#4a122f] text-white font-semibold flex items-center gap-2 px-5 py-2.5 rounded-xl shadow-md transition-all hover:scale-[1.02]"
                >
                    <PlusCircle className="w-5 h-5" />
                    + Add Nutrient
                </Button>
            </div>

            {/* FILTER BAR CONTAINER */}
            <Card className="p-4 space-y-4 bg-white border border-gray-100 shadow-sm rounded-2xl">
                <div className="flex items-center gap-2 text-xs font-bold text-gray-700 uppercase tracking-wider">
                    <Filter className="w-4 h-4 text-[#61183e]" />
                    Filter Nutrients List
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
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
                            <option value="all">
                                {nutritionWeeks.length > 0 ? `All Created Weeks (${nutritionWeeks.length})` : 'All Weeks (1–40)'}
                            </option>
                            {(nutritionWeeks.length > 0 ? nutritionWeeks : Array.from({ length: 40 }, (_, i) => i + 1)).map((w: any) => {
                                const weekNum = typeof w === 'object' ? w.week : w;
                                const weekId = typeof w === 'object' ? w.id : w;
                                return <option key={weekId} value={weekNum}>Week {weekNum}</option>;
                            })}
                        </select>
                    </div>

                    {/* Type Filter */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Type</label>
                        <select
                            value={filterType}
                            onChange={e => setFilterType(e.target.value)}
                            className="w-full text-xs rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
                        >
                            <option value="all">All Types</option>
                            <option value="eat">✅ What to Eat</option>
                            <option value="avoid">🚫 What NOT to Eat</option>
                        </select>
                    </div>

                    {/* Search Query */}
                    <div>
                        <label className="block text-[11px] font-semibold text-gray-500 mb-1">Search</label>
                        <div className="relative">
                            <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                            <input
                                type="text"
                                placeholder="Search nutrient..."
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

            {/* NUTRIENT CONTAINERS LIST */}
            {loading ? (
                <div className="flex flex-col items-center justify-center py-16 bg-white rounded-2xl border border-gray-100 shadow-sm space-y-3">
                    <Loader2 className="w-8 h-8 text-[#61183e] animate-spin" />
                    <p className="text-sm font-medium text-gray-500">Loading nutrients...</p>
                </div>
            ) : filteredNutrients.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-16 bg-white rounded-2xl border border-gray-100 shadow-sm text-center space-y-3 p-6">
                    <div className="w-14 h-14 rounded-full bg-pink-50 flex items-center justify-center text-[#61183e]">
                        <Utensils className="w-7 h-7" />
                    </div>
                    <h3 className="text-base font-bold text-gray-800">No Nutrients Found</h3>
                    <p className="text-xs text-gray-400 max-w-sm">No nutrient entries match your selected filter criteria. Try resetting filters or add a new nutrient.</p>
                    <Button onClick={handleOpenAddModal} className="bg-[#61183e] text-white text-xs px-4 py-2 rounded-xl">
                        + Add Nutrient Now
                    </Button>
                </div>
            ) : (
                <div className="space-y-4">
                    <div className="flex items-center justify-between text-xs text-gray-500 px-1 font-medium">
                        <span>Showing {filteredNutrients.length} nutrient container(s)</span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {filteredNutrients.map((item) => {
                            const cardId = item.id || `card-${Math.random()}`;
                            const lang = getActiveCardLang(cardId);
                            const title = lang === 'am' ? item.titleAm : lang === 'or' ? item.titleOr : lang === 'so' ? item.titleSo : item.titleEn;
                            const bodyDesc = lang === 'am' ? item.bodyAm : lang === 'or' ? item.bodyOr : lang === 'so' ? item.bodySo : item.bodyEn;
                            const benefitLabel = lang === 'am' ? item.benefitLabelAm : lang === 'or' ? item.benefitLabelOr : lang === 'so' ? item.benefitLabelSo : item.benefitLabelEn;
                            const benefitValue = lang === 'am' ? item.benefitValueAm : lang === 'or' ? item.benefitValueOr : lang === 'so' ? item.benefitValueSo : item.benefitValueEn;

                            return (
                                <Card key={cardId} className="p-5 space-y-4 border border-gray-100 shadow-sm hover:shadow-md transition-all rounded-2xl bg-white flex flex-col justify-between">

                                    {/* CARD TOP HEADER */}
                                    <div className="space-y-3">
                                        <div className="flex items-start justify-between gap-3">
                                            <div className="flex items-center gap-3">
                                                <div className="w-12 h-12 rounded-2xl bg-pink-50 border border-pink-100 flex items-center justify-center text-2xl shrink-0 shadow-xs">
                                                    {item.emoji || '🥗'}
                                                </div>
                                                <div>
                                                    <div className="flex items-center gap-2 flex-wrap">
                                                        <h3 className="font-bold text-gray-900 text-base leading-snug">{item.nutrientType}</h3>
                                                        <span className={`text-[10px] font-extrabold px-2 py-0.5 rounded-md border ${item.type === 'eat' ? 'bg-green-50 text-green-700 border-green-200' : 'bg-red-50 text-red-700 border-red-200'}`}>
                                                            {item.type === 'eat' ? '✅ Eat' : '🚫 Avoid'}
                                                        </span>
                                                    </div>
                                                    <p className="text-xs text-gray-500 font-medium">
                                                        Week {item.week} • Month {item.month} • {item.trimester} Trimester
                                                    </p>
                                                </div>
                                            </div>

                                            {/* ACTION ICONS */}
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
                                                    title="Edit Nutrient"
                                                    className="p-1.5 text-blue-600 bg-blue-50 border border-blue-200 rounded-lg hover:bg-blue-100 transition-colors"
                                                >
                                                    <Edit2 className="w-4 h-4" />
                                                </button>

                                                <button
                                                    onClick={() => handleOpenDeleteModal(item)}
                                                    title="Delete Nutrient"
                                                    className="p-1.5 text-red-600 bg-red-50 border border-red-200 rounded-lg hover:bg-red-100 transition-colors"
                                                >
                                                    <Trash2 className="w-4 h-4" />
                                                </button>
                                            </div>
                                        </div>

                                        {/* LANGUAGE SELECTOR TABS FOR CARD PREVIEW */}
                                        <div className="flex items-center gap-1 bg-gray-50 p-1 rounded-xl w-fit text-[11px] font-bold">
                                            {(['en', 'or', 'so', 'am'] as const).map(l => (
                                                <button
                                                    key={l}
                                                    onClick={() => setCardLanguage(cardId, l)}
                                                    className={`px-2.5 py-0.5 rounded-lg transition-all ${lang === l ? 'bg-white text-[#61183e] shadow-xs' : 'text-gray-400 hover:text-gray-600'}`}
                                                >
                                                    {l === 'en' ? 'EN' : l === 'or' ? 'OR' : l === 'so' ? 'SO' : 'AM'}
                                                </button>
                                            ))}
                                        </div>

                                        {/* TITLE & BODY */}
                                        <div className="space-y-1.5 bg-gray-50/60 p-3 rounded-xl border border-gray-100">
                                            {title && <h4 className="text-xs font-bold text-gray-800">{title}</h4>}
                                            <p className="text-xs text-gray-600 leading-relaxed line-clamp-3">
                                                {bodyDesc || <span className="italic text-gray-400">No description provided in this language.</span>}
                                            </p>
                                        </div>

                                        {/* MEDIA PREVIEW & BENEFITS */}
                                        <div className="flex flex-wrap gap-2 text-xs">
                                            {item.imageUrl && (
                                                <div className="flex items-center gap-1 px-2.5 py-1 bg-purple-50 text-purple-700 rounded-lg border border-purple-100 font-medium">
                                                    <ImageIcon className="w-3.5 h-3.5" />
                                                    <span>Image attached</span>
                                                </div>
                                            )}
                                            {item.videoUrl && (
                                                <div className="flex items-center gap-1 px-2.5 py-1 bg-blue-50 text-blue-700 rounded-lg border border-blue-100 font-medium">
                                                    <VideoIcon className="w-3.5 h-3.5" />
                                                    <span>Video attached</span>
                                                </div>
                                            )}
                                            {benefitValue && (
                                                <div className="flex items-center gap-1 px-2.5 py-1 bg-emerald-50 text-emerald-700 rounded-lg border border-emerald-100 font-bold">
                                                    <Sparkles className="w-3.5 h-3.5" />
                                                    <span>{benefitLabel ? `${benefitLabel}: ` : ''}{benefitValue}</span>
                                                </div>
                                            )}
                                        </div>

                                        {/* ATTACHED FOODS LIST PREVIEW */}
                                        {item.foods && item.foods.length > 0 && (
                                            <div className="space-y-1.5 pt-1">
                                                <p className="text-[11px] font-bold text-gray-500 uppercase tracking-wide">
                                                    Attached Foods ({item.foods.length})
                                                </p>
                                                <div className="flex flex-wrap gap-1.5">
                                                    {item.foods.map((food, fIdx) => {
                                                        const fName = lang === 'am' ? food.nameAm : lang === 'or' ? food.nameOr : lang === 'so' ? food.nameSo : food.nameEn;
                                                        return (
                                                            <span key={fIdx} className="text-xs bg-pink-50/80 text-[#61183e] px-2.5 py-1 rounded-lg border border-pink-100 font-semibold flex items-center gap-1">
                                                                <Utensils className="w-3 h-3 text-[#61183e]" />
                                                                {fName || food.nameEn || `Food ${fIdx + 1}`}
                                                            </span>
                                                        );
                                                    })}
                                                </div>
                                            </div>
                                        )}
                                    </div>

                                    {/* CARD FOOTER */}
                                    <div className="pt-3 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-400">
                                        <span>Status: {item.isPublished ? 'Published' : 'Draft'}</span>
                                        <span className="font-semibold text-[#61183e]">Week {item.week} Guide</span>
                                    </div>
                                </Card>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* ─────────────────────────────────────────────────────────────────
               ADD / EDIT NUTRIENT MODAL
            ───────────────────────────────────────────────────────────────── */}
            <Modal
                isOpen={isAddModalOpen || isEditModalOpen}
                onClose={() => { setIsAddModalOpen(false); setIsEditModalOpen(false); }}
                title={isEditModalOpen ? 'Edit Nutrient Entry' : '+ Add New Nutrient'}
                size="xl"
            >
                <form onSubmit={handleSaveNutrient} className="space-y-6 py-2 max-h-[80vh] overflow-y-auto pr-1">

                    {/* SECTION 1: CONTEXT (Week, Trimester, Month, Type) */}
                    <div className="p-4 bg-pink-50/50 rounded-2xl border border-pink-100 space-y-4">
                        <h4 className="text-xs font-bold text-[#61183e] uppercase tracking-wider flex items-center gap-2">
                            <Calendar className="w-4 h-4" />
                            1. Select Pregnancy Week & Guide Type
                        </h4>

                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                            <div>
                                <label className="block text-xs font-bold text-gray-700 mb-1">
                                    Pregnancy Week * {nutritionWeeks.length > 0 ? `(${nutritionWeeks.length} Created Weeks)` : '(No weeks yet — create weeks first)'}
                                </label>
                                <select
                                    value={formData.week}
                                    onChange={e => handleWeekChangeInForm(Number(e.target.value))}
                                    className="w-full text-xs font-semibold rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
                                >
                                    {nutritionWeeks.length === 0 && (
                                        <option value="">No nutrition weeks created yet</option>
                                    )}
                                    {nutritionWeeks.map(wk => (
                                        <option key={wk.id} value={wk.id}>
                                            Week {wk.week} (Month {wk.month}, {wk.trimester} Trim)
                                        </option>
                                    ))}
                                </select>
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-700 mb-1">Guide Type *</label>
                                <select
                                    value={formData.type}
                                    onChange={e => setFormData(prev => ({ ...prev, type: e.target.value as 'eat' | 'avoid' }))}
                                    className="w-full text-xs font-semibold rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
                                >
                                    <option value="eat">✅ What to Eat</option>
                                    <option value="avoid">🚫 What NOT to Eat</option>
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

                    {/* SECTION 2: NUTRIENT ICON DROPDOWN */}
                    <div className="space-y-4">
                        <h4 className="text-xs font-bold text-gray-800 uppercase tracking-wider flex items-center gap-2">
                            <Utensils className="w-4 h-4 text-[#61183e]" />
                            2. Nutrient Icon & Type
                        </h4>

                        <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                            <div className="sm:col-span-4">
                                <label className="block text-xs font-bold text-gray-700 mb-1">Select Nutrient Icon *</label>
                                <select
                                    value={formData.nutrientType}
                                    onChange={e => handleNutrientOptionChange(e.target.value)}
                                    className="w-full text-xs font-semibold rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
                                    required
                                >
                                    {NUTRIENT_OPTIONS.map(opt => (
                                        <option key={opt.label} value={opt.label}>
                                            {opt.emoji} — {opt.label}
                                        </option>
                                    ))}
                                </select>
                            </div>
                        </div>
                    </div>

                    {/* SECTION 3: 4-LANGUAGE TITLES */}
                    <div className="space-y-3 bg-gray-50 p-4 rounded-2xl border border-gray-100">
                        <h4 className="text-xs font-bold text-gray-800 uppercase tracking-wider">
                            3. Nutrient Title (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 English Title</label>
                                <Input
                                    value={formData.titleEn}
                                    onChange={e => setFormData(prev => ({ ...prev, titleEn: e.target.value }))}
                                    placeholder="e.g. Essential Iron for Blood & Baby Growth"
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Amharic (አማርኛ) Title</label>
                                <Input
                                    value={formData.titleAm}
                                    onChange={e => setFormData(prev => ({ ...prev, titleAm: e.target.value }))}
                                    placeholder="ለምሳሌ፡ አስፈላጊ ብረት ለሕፃኑ እድገት"
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Afaan Oromo Title</label>
                                <Input
                                    value={formData.titleOr}
                                    onChange={e => setFormData(prev => ({ ...prev, titleOr: e.target.value }))}
                                    placeholder="e.g. Sibiila barbaachisaa guddina daa'imaaf"
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Afan Somali Title</label>
                                <Input
                                    value={formData.titleSo}
                                    onChange={e => setFormData(prev => ({ ...prev, titleSo: e.target.value }))}
                                    placeholder="e.g. Bir muhiim ah koritaanka ilmaha"
                                    className="text-xs rounded-xl"
                                />
                            </div>
                        </div>
                    </div>

                    {/* SECTION 4: 4-LANGUAGE BODY DESCRIPTIONS */}
                    <div className="space-y-3 bg-gray-50 p-4 rounded-2xl border border-gray-100">
                        <h4 className="text-xs font-bold text-gray-800 uppercase tracking-wider">
                            4. Body Nutrient Description (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 English Body Description</label>
                                <TextArea
                                    value={formData.bodyEn}
                                    onChange={e => setFormData(prev => ({ ...prev, bodyEn: e.target.value }))}
                                    placeholder="Detailed explanation of why this nutrient matters..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Amharic Body Description</label>
                                <TextArea
                                    value={formData.bodyAm}
                                    onChange={e => setFormData(prev => ({ ...prev, bodyAm: e.target.value }))}
                                    placeholder="ስለዚህ ንጥረ ነገር ዝርዝር ማብራሪያ..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Afaan Oromo Body Description</label>
                                <TextArea
                                    value={formData.bodyOr}
                                    onChange={e => setFormData(prev => ({ ...prev, bodyOr: e.target.value }))}
                                    placeholder="Ibsa bal'aa waa'ee nutrient kanaa..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Afan Somali Body Description</label>
                                <TextArea
                                    value={formData.bodySo}
                                    onChange={e => setFormData(prev => ({ ...prev, bodySo: e.target.value }))}
                                    placeholder="Fahfaahin ku saabsan nafaqadan..."
                                    rows={3}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                        </div>
                    </div>

                    {/* SECTION 5: MEDIA ATTACHMENTS (IMAGE & VIDEO) */}
                    <div className="space-y-3 p-4 bg-purple-50/40 rounded-2xl border border-purple-100">
                        <h4 className="text-xs font-bold text-purple-900 uppercase tracking-wider flex items-center gap-2">
                            <ImageIcon className="w-4 h-4" />
                            5. Nutrient Media (Image & Video Upload)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <MediaInput
                                    label="Nutrient Image (Upload or URL)"
                                    value={formData.imageUrl || ''}
                                    onChange={url => setFormData(prev => ({ ...prev, imageUrl: url }))}
                                    type="image"
                                />
                            </div>
                            <div>

                            </div>
                        </div>
                    </div>

                    {/* SECTION 6: BENEFIT VALUE & LABELS (4 LANGUAGES EACH) */}
                    <div className="space-y-4 p-4 bg-emerald-50/40 rounded-2xl border border-emerald-100">
                        <h4 className="text-xs font-bold text-emerald-900 uppercase tracking-wider flex items-center gap-2">
                            <Sparkles className="w-4 h-4" />
                            6. Benefit Value & Labels (4 Languages)
                        </h4>

                        {/* Benefit Value — 4 languages */}
                        <div className="space-y-2">
                            <p className="text-[11px] font-bold text-gray-500 uppercase tracking-wide">Benefit Value (e.g. 27 mg/day)</p>
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                <div>
                                    <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 Benefit Value (EN)</label>
                                    <Input
                                        value={formData.benefitValueEn}
                                        onChange={e => setFormData(prev => ({ ...prev, benefitValueEn: e.target.value }))}
                                        placeholder="e.g. 27 mg/day"
                                        className="text-xs rounded-xl"
                                    />
                                </div>
                                <div>
                                    <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Benefit Value (AM)</label>
                                    <Input
                                        value={formData.benefitValueAm}
                                        onChange={e => setFormData(prev => ({ ...prev, benefitValueAm: e.target.value }))}
                                        placeholder="ለምሳሌ፡ 27 mg/ቀን"
                                        className="text-xs rounded-xl"
                                    />
                                </div>
                                <div>
                                    <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Benefit Value (OR)</label>
                                    <Input
                                        value={formData.benefitValueOr}
                                        onChange={e => setFormData(prev => ({ ...prev, benefitValueOr: e.target.value }))}
                                        placeholder="fkn. 27 mg/guyyaa"
                                        className="text-xs rounded-xl"
                                    />
                                </div>
                                <div>
                                    <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Benefit Value (SO)</label>
                                    <Input
                                        value={formData.benefitValueSo}
                                        onChange={e => setFormData(prev => ({ ...prev, benefitValueSo: e.target.value }))}
                                        placeholder="tusaale: 27 mg/maalintii"
                                        className="text-xs rounded-xl"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Benefit Label — 4 languages */}
                        <div className="space-y-2">
                            <p className="text-[11px] font-bold text-gray-500 uppercase tracking-wide">Benefit Label</p>
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                <div>
                                    <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 Benefit Label (EN)</label>
                                    <Input
                                        value={formData.benefitLabelEn}
                                        onChange={e => setFormData(prev => ({ ...prev, benefitLabelEn: e.target.value }))}
                                        placeholder="Daily Target"
                                        className="text-xs rounded-xl"
                                    />
                                </div>
                                <div>
                                    <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Benefit Label (AM)</label>
                                    <Input
                                        value={formData.benefitLabelAm}
                                        onChange={e => setFormData(prev => ({ ...prev, benefitLabelAm: e.target.value }))}
                                        placeholder="የቀን ግብ"
                                        className="text-xs rounded-xl"
                                    />
                                </div>
                                <div>
                                    <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Benefit Label (OR)</label>
                                    <Input
                                        value={formData.benefitLabelOr}
                                        onChange={e => setFormData(prev => ({ ...prev, benefitLabelOr: e.target.value }))}
                                        placeholder="Galma Guyyaa"
                                        className="text-xs rounded-xl"
                                    />
                                </div>
                                <div>
                                    <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Benefit Label (SO)</label>
                                    <Input
                                        value={formData.benefitLabelSo}
                                        onChange={e => setFormData(prev => ({ ...prev, benefitLabelSo: e.target.value }))}
                                        placeholder="Hadaafka Maalinta"
                                        className="text-xs rounded-xl"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* SECTION 6b: WHY IMPORTANT (4 Languages) */}
                    <div className="space-y-3 p-4 bg-amber-50/40 rounded-2xl border border-amber-100">
                        <h4 className="text-xs font-bold text-amber-900 uppercase tracking-wider flex items-center gap-2">
                            <Sparkles className="w-4 h-4" />
                            6b. Why Important (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇬🇧 Why Important (EN)</label>
                                <TextArea
                                    value={formData.whyImportantEn || ''}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantEn: e.target.value }))}
                                    placeholder="e.g. Helps regulate blood pressure and muscle function."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇪🇹 Why Important (AM)</label>
                                <TextArea
                                    value={formData.whyImportantAm || ''}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantAm: e.target.value }))}
                                    placeholder="ለምሳሌ፡ የደም ግፊትን ለመቆጣጠር ይረዳል"
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🌳 Why Important (OR)</label>
                                <TextArea
                                    value={formData.whyImportantOr || ''}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantOr: e.target.value }))}
                                    placeholder="e.g. Dhiibbaa dhiigaa to'achuuf gargaara."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                            <div>
                                <label className="block text-[11px] font-bold text-gray-600 mb-1">🇸🇴 Why Important (SO)</label>
                                <TextArea
                                    value={formData.whyImportantSo || ''}
                                    onChange={e => setFormData(prev => ({ ...prev, whyImportantSo: e.target.value }))}
                                    placeholder="e.g. Waxay caawisaa xakamaynta cadaadiska dhiigga."
                                    rows={2}
                                    className="text-xs rounded-xl"
                                />
                            </div>
                        </div>
                        </div>

  <div className="space-y-3 p-4 bg-Red-50/40 rounded-2xl border border-amber-100">
                        <h4 className="text-xs font-bold text-amber-900 uppercase tracking-wider flex items-center gap-2">
                            <Sparkles className="w-4 h-4" />
                            7b. Health Tips (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                             <label className="block text-xs font-bold text-gray-700 mb-1">Health Tip (EN)</label>
                            <TextArea
                                value={formData.healthTipsEn || ''}
                                onChange={e => setFormData(prev => ({ ...prev, healthTipsEn: e.target.value }))}
                                placeholder="e.g. Eat one banana daily. Best eaten in the morning."
                                rows={2}
                                className="text-xs rounded-xl"
                            />
                            </div>
                            <div>
                                 <label className="block text-xs font-bold text-gray-700 mb-1">Health Tip (Am)</label>
                            <TextArea
                                value={formData.healthTipsAm || ''}
                                onChange={e => setFormData(prev => ({ ...prev, healthTipsAm: e.target.value }))}
                                placeholder="e.g. Eat one banana daily. Best eaten in the morning."
                                rows={2}
                                className="text-xs rounded-xl"
                            />
                            </div>
                           <div>
                                 <label className="block text-xs font-bold text-gray-700 mb-1">Health Tip (Or)</label>
                            <TextArea
                                value={formData.healthTipsOr || ''}
                                onChange={e => setFormData(prev => ({ ...prev, healthTipsOr: e.target.value }))}
                                placeholder="e.g. Eat one banana daily. Best eaten in the morning."
                                rows={2}
                                className="text-xs rounded-xl"
                            />
                            </div>
                            <div>
                                 <label className="block text-xs font-bold text-gray-700 mb-1">Health Tip (So)</label>
                            <TextArea
                                value={formData.healthTipsSo || ''}
                                onChange={e => setFormData(prev => ({ ...prev, healthTipsSo: e.target.value }))}
                                placeholder="e.g. Eat one banana daily. Best eaten in the morning."
                                rows={2}
                                className="text-xs rounded-xl"
                            />
                            </div>
                        </div>
                    </div>

                    {/* SECTION 7: ATTACHED FOODS LIST */}
                    <div className="space-y-4 p-4 bg-gray-50 rounded-2xl border border-gray-200">
                        <div className="flex items-center justify-between">
                            <h4 className="text-xs font-bold text-gray-800 uppercase tracking-wider flex items-center gap-2">
                                <BookOpen className="w-4 h-4 text-[#61183e]" />
                                7. List of Attached Foods
                            </h4>
                            <Button
                                type="button"
                                onClick={handleAddFood}
                                className="text-xs bg-[#61183e] text-white px-3 py-1.5 rounded-xl font-semibold flex items-center gap-1"
                            >
                                <PlusCircle className="w-3.5 h-3.5" /> + Add Food
                            </Button>
                        </div>

                        {formData.foods.map((food, fIdx) => (
                            <div key={fIdx} className="bg-white p-4 rounded-xl border border-gray-200 space-y-3 relative">
                                <div className="flex items-center justify-between border-b border-gray-100 pb-2">
                                    <span className="text-xs font-bold text-gray-700">Food Item #{fIdx + 1}</span>
                                    {formData.foods.length > 1 && (
                                        <button
                                            type="button"
                                            onClick={() => handleRemoveFood(fIdx)}
                                            className="text-xs text-red-500 hover:text-red-700 font-semibold flex items-center gap-1"
                                        >
                                            <X className="w-3.5 h-3.5" /> Remove
                                        </button>
                                    )}
                                </div>

                                {/* Food Names */}
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇬🇧 Food Name (EN)</label>
                                        <Input
                                            value={food.nameEn}
                                            onChange={e => handleFoodChange(fIdx, 'nameEn', e.target.value)}
                                            placeholder="e.g. Banana, Spinach, Lentils"
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇪🇹 Food Name (AM)</label>
                                        <Input
                                            value={food.nameAm}
                                            onChange={e => handleFoodChange(fIdx, 'nameAm', e.target.value)}
                                            placeholder="ለምሳሌ፡ ሙዝ፣ ስፒናች"
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🌳 Food Name (OR)</label>
                                        <Input
                                            value={food.nameOr}
                                            onChange={e => handleFoodChange(fIdx, 'nameOr', e.target.value)}
                                            placeholder="e.g. Muuza, Isbiinaaqii"
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇸🇴 Food Name (SO)</label>
                                        <Input
                                            value={food.nameSo}
                                            onChange={e => handleFoodChange(fIdx, 'nameSo', e.target.value)}
                                            placeholder="e.g. Moos, Isbanaaj"
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                </div>

                                {/* Food Descriptions */}
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇬🇧 Description (EN)</label>
                                        <TextArea
                                            value={food.descEn}
                                            onChange={e => handleFoodChange(fIdx, 'descEn', e.target.value)}
                                            placeholder="e.g. Rich in potassium and fiber"
                                            rows={2}
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇪🇹 Description (AM)</label>
                                        <TextArea
                                            value={food.descAm}
                                            onChange={e => handleFoodChange(fIdx, 'descAm', e.target.value)}
                                            placeholder="ለምሳሌ፡ በፖታስየም እና ፋይበር የበለፀገ"
                                            rows={2}
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🌳 Description (OR)</label>
                                        <TextArea
                                            value={food.descOr}
                                            onChange={e => handleFoodChange(fIdx, 'descOr', e.target.value)}
                                            placeholder="e.g. Potaasiyeemii fi fiibaraan badhaadhaa"
                                            rows={2}
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇸🇴 Description (SO)</label>
                                        <TextArea
                                            value={food.descSo}
                                            onChange={e => handleFoodChange(fIdx, 'descSo', e.target.value)}
                                            placeholder="e.g. Ku hodan botassiyum iyo fiber"
                                            rows={2}
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                </div>
                                 <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇬🇧 Label (EN)</label>
                                        <TextArea
                                            value={food.labelEn}
                                            onChange={e => handleFoodChange(fIdx, 'labelEn', e.target.value)}
                                            placeholder="e.g. Rich in potassium and fiber"
                                            rows={2}
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇪🇹 Label (AM)</label>
                                        <TextArea
                                            value={food.labelAm}
                                            onChange={e => handleFoodChange(fIdx, 'labelAm', e.target.value)}
                                            placeholder="ለምሳሌ፡ በፖታስየም እና ፋይበር የበለፀገ"
                                            rows={2}
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🌳 Label (OR)</label>
                                        <TextArea
                                            value={food.labelOr}
                                            onChange={e => handleFoodChange(fIdx, 'labelOr', e.target.value)}
                                            placeholder="e.g. Potaasiyeemii fi fiibaraan badhaadhaa"
                                            rows={2}
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇸🇴 Label (SO)</label>
                                        <TextArea
                                            value={food.labelSo}
                                        onChange={e => handleFoodChange(fIdx, 'labelSo', e.target.value)}
                                            placeholder="e.g. Ku hodan botassiyum iyo fiber"
                                            rows={2}
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                </div>
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <MediaInput
                                        label="Food Image (Upload or URL)"
                                        value={food.imageUrl || ''}
                                        onChange={url => handleFoodChange(fIdx, 'imageUrl', url)}
                                        type="image"
                                    />
                                    <MediaInput
                                        label="Food Video (Upload or URL)"
                                        value={food.videoUrl || ''}
                                        onChange={url => handleFoodChange(fIdx, 'videoUrl', url)}
                                        type="video"
                                    />
                                </div>
                            </div>
                        ))}
                    </div>

                    {/* MODAL ACTIONS */}
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
                            {isEditModalOpen ? 'Update Nutrient' : 'Save Nutrient'}
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
                title="Delete Nutrient"
            >
                <div className="space-y-4 py-3">
                    <div className="flex items-center gap-3 bg-red-50 p-4 rounded-xl text-red-700 border border-red-100">
                        <AlertTriangle className="w-6 h-6 shrink-0" />
                        <div>
                            <p className="text-sm font-bold">Are you sure you want to delete this nutrient?</p>
                            <p className="text-xs text-red-600 mt-0.5">
                                "{nutrientToDelete?.nutrientType}" from Week {nutrientToDelete?.week} will be permanently deleted.
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
                            Delete Nutrient
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