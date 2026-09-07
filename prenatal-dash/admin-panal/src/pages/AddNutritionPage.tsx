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

    // Benefit & Tips
    benefitValue?: string;
    benefitLabelEn?: string;
    benefitLabelOr?: string;
    benefitLabelSo?: string;
    benefitLabelAm?: string;
    helpfulTips?: string;

    // Foods List
    foods: FoodItem[];
}

interface BackendNutritionRow {
    id: string | number;
    week?: number | string | null;
    trimester?: number | string | null;
    type?: 'eat' | 'avoid';
    emoji?: string;
    nutrient_type?: string;
    nutrientType?: string;

    title_en?: string; titleEn?: string;
    title_or?: string; titleOr?: string;
    title_so?: string; titleSo?: string;
    title_am?: string; titleAm?: string;

    body_en?: string; bodyEn?: string;
    body_or?: string; bodyOr?: string;
    body_so?: string; bodySo?: string;
    body_am?: string; bodyAm?: string;

    why_important_en?: string; whyImportantEn?: string;
    why_important_or?: string; whyImportantOr?: string;
    why_important_so?: string; whyImportantSo?: string;
    why_important_am?: string; whyImportantAm?: string;

    hydration_en?: string; hydrationEn?: string;
    hydration_or?: string; hydrationOr?: string;
    hydration_so?: string; hydrationSo?: string;
    hydration_am?: string; hydrationAm?: string;

    image_url?: string; imageUrl?: string;
    video_url?: string; videoUrl?: string;
    benefit_value?: string; benefitValue?: string;
    benefit_label_en?: string; benefitLabelEn?: string;
    benefit_label_or?: string; benefitLabelOr?: string;
    benefit_label_so?: string; benefitLabelSo?: string;
    benefit_label_am?: string; benefitLabelAm?: string;

    nutrient_sections_json?: any;
    nutrientSectionsJson?: any;
    foods_json?: any;
    foodsJson?: any;
    is_published?: boolean;
    isPublished?: boolean;
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

const EMPTY_NUTRIENT: Omit<NutrientSection, 'id'> = {
    week: 18,
    trimester: '2nd',
    month: 5,
    type: 'eat',
    nutrientType: '',
    emoji: '🥗',
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
    benefitValue: '',
    benefitLabelEn: '',
    benefitLabelOr: '',
    benefitLabelSo: '',
    benefitLabelAm: '',
    helpfulTips: '',
    foods: [],
};

const EMPTY_FOOD: FoodItem = {
    nameEn: '', nameOr: '', nameSo: '', nameAm: '',
    descEn: '', descOr: '', descSo: '', descAm: '',
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

    // Language tab state for preview in cards
    const [cardLang, setCardLang] = useState<Record<string, 'en' | 'or' | 'so' | 'am'>>({});

    // ── Fetch Data ────────────────────────────────────────────────────────────
    const loadNutritionData = useCallback(async () => {
        setLoading(true);
        try {
            const res = await cmsClient.list<BackendNutritionRow>('nutrition', { limit: 500 });
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
            const weekNum = Number(row.week || 1);
            const { month, trimester } = calculateMonthAndTrimester(weekNum);
            const parentType = row.type || 'eat';
            const isPub = row.is_published ?? row.isPublished ?? true;

            // Parse nutrient_sections_json
            let sections: any[] = [];
            if (row.nutrient_sections_json || row.nutrientSectionsJson) {
                const rawSec = row.nutrient_sections_json || row.nutrientSectionsJson;
                try {
                    sections = typeof rawSec === 'string' ? JSON.parse(rawSec) : rawSec;
                } catch { sections = []; }
            }

            if (Array.isArray(sections) && sections.length > 0) {
                sections.forEach((sec, idx) => {
                    // Normalize foods
                    let foodsList: FoodItem[] = [];
                    if (Array.isArray(sec.foods)) {
                        foodsList = sec.foods.map((f: any) => ({
                            id: f.id || `f-${Math.random()}`,
                            nameEn: f.nameEn || f.name_en || f.name || '',
                            nameOr: f.nameOr || f.name_or || '',
                            nameSo: f.nameSo || f.name_so || '',
                            nameAm: f.nameAm || f.name_am || '',
                            descEn: f.descEn || f.desc_en || f.description || '',
                            descOr: f.descOr || f.desc_or || '',
                            descSo: f.descSo || f.desc_so || '',
                            descAm: f.descAm || f.desc_am || '',
                            imageUrl: f.imageUrl || f.image_url || '',
                            videoUrl: f.videoUrl || f.video_url || '',
                        }));
                    }

                    list.push({
                        id: sec.id || `sec-${row.id}-${idx}`,
                        parentId: row.id,
                        week: weekNum,
                        trimester: String(row.trimester || trimester),
                        month,
                        type: (sec.type || parentType) as 'eat' | 'avoid',
                        nutrientType: sec.nutrientType || sec.nutrient_type || row.nutrient_type || 'General Nutrient',
                        emoji: sec.emoji || row.emoji || '🥗',
                        isPublished: isPub,

                        titleEn: sec.titleEn || sec.title_en || row.title_en || row.titleEn || '',
                        titleOr: sec.titleOr || sec.title_or || row.title_or || row.titleOr || '',
                        titleSo: sec.titleSo || sec.title_so || row.title_so || row.titleSo || '',
                        titleAm: sec.titleAm || sec.title_am || row.title_am || row.titleAm || '',

                        bodyEn: sec.bodyEn || sec.desc_en || sec.body_en || row.body_en || row.bodyEn || '',
                        bodyOr: sec.bodyOr || sec.desc_or || sec.body_or || row.body_or || row.bodyOr || '',
                        bodySo: sec.bodySo || sec.desc_so || sec.body_so || row.body_so || row.bodySo || '',
                        bodyAm: sec.bodyAm || sec.desc_am || sec.body_am || row.body_am || row.bodyAm || '',

                        imageUrl: sec.imageUrl || sec.image_url || row.image_url || row.imageUrl || '',
                        videoUrl: sec.videoUrl || sec.video_url || row.video_url || row.videoUrl || '',

                        benefitValue: sec.benefitValue || sec.benefit_value || row.benefit_value || row.benefitValue || '',
                        benefitLabelEn: sec.benefitLabelEn || sec.benefit_label_en || row.benefit_label_en || '',
                        benefitLabelOr: sec.benefitLabelOr || sec.benefit_label_or || row.benefit_label_or || '',
                        benefitLabelSo: sec.benefitLabelSo || sec.benefit_label_so || row.benefit_label_so || '',
                        benefitLabelAm: sec.benefitLabelAm || sec.benefit_label_am || row.benefit_label_am || '',

                        helpfulTips: sec.helpfulTips || sec.helpful_tips || '',
                        foods: foodsList,
                    });
                });
            } else {
                // If parent row doesn't have sections json, convert parent row into a single section
                let foodsList: FoodItem[] = [];
                let rawFoods = row.foods_json || row.foodsJson;
                if (rawFoods) {
                    try {
                        const parsed = typeof rawFoods === 'string' ? JSON.parse(rawFoods) : rawFoods;
                        if (Array.isArray(parsed)) {
                            foodsList = parsed.map((f: any) => ({
                                id: f.id || `f-${Math.random()}`,
                                nameEn: f.nameEn || f.name_en || f.name || '',
                                nameOr: f.nameOr || f.name_or || '',
                                nameSo: f.nameSo || f.name_so || '',
                                nameAm: f.nameAm || f.name_am || '',
                                descEn: f.descEn || f.desc_en || f.description || '',
                                descOr: f.descOr || f.desc_or || '',
                                descSo: f.descSo || f.desc_so || '',
                                descAm: f.descAm || f.desc_am || '',
                                imageUrl: f.imageUrl || f.image_url || '',
                                videoUrl: f.videoUrl || f.video_url || '',
                            }));
                        }
                    } catch {}
                }

                list.push({
                    id: `row-${row.id}`,
                    parentId: row.id,
                    week: weekNum,
                    trimester: String(row.trimester || trimester),
                    month,
                    type: parentType,
                    nutrientType: row.nutrient_type || row.nutrientType || 'Nutrient',
                    emoji: row.emoji || '🥗',
                    isPublished: isPub,

                    titleEn: row.title_en || row.titleEn || '',
                    titleOr: row.title_or || row.titleOr || '',
                    titleSo: row.title_so || row.titleSo || '',
                    titleAm: row.title_am || row.titleAm || '',

                    bodyEn: row.body_en || row.bodyEn || '',
                    bodyOr: row.body_or || row.bodyOr || '',
                    bodySo: row.body_so || row.bodySo || '',
                    bodyAm: row.body_am || row.bodyAm || '',

                    imageUrl: row.image_url || row.imageUrl || '',
                    videoUrl: row.video_url || row.videoUrl || '',

                    benefitValue: row.benefit_value || row.benefitValue || '',
                    benefitLabelEn: row.benefit_label_en || row.benefitLabelEn || '',
                    benefitLabelOr: row.benefit_label_or || row.benefitLabelOr || '',
                    benefitLabelSo: row.benefit_label_so || row.benefitLabelSo || '',
                    benefitLabelAm: row.benefit_label_am || row.benefitLabelAm || '',

                    helpfulTips: '',
                    foods: foodsList,
                });
            }
        });

        return list;
    }, [rawRows]);

    // ── Get Created Weeks List ────────────────────────────────────────────────
    const createdWeeks = useMemo(() => {
        const set = new Set<number>();
        rawRows.forEach(row => {
            if (row.week !== null && row.week !== undefined && row.week !== '') {
                set.add(Number(row.week));
            }
        });
        return Array.from(set).sort((a, b) => a - b);
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
        const initialWeek = createdWeeks.length > 0 ? createdWeeks[0] : 18;
        const { month, trimester } = calculateMonthAndTrimester(initialWeek);
        setFormData({
            ...EMPTY_NUTRIENT,
            week: initialWeek,
            month,
            trimester,
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

    const handleWeekChangeInForm = (weekNum: number) => {
        const { month, trimester } = calculateMonthAndTrimester(weekNum);
        setFormData(prev => ({
            ...prev,
            week: weekNum,
            month,
            trimester,
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
            showToast('Please enter a Nutrient Type (e.g. Iron, Protein)', 'error');
            return;
        }

        setSubmitting(true);
        try {
            // Find if there is an existing parent nutrition_content row for this week & type
            const existingRow = rawRows.find(
                r => Number(r.week) === Number(formData.week) && r.type === formData.type
            );

            const nutrientSectionObj = {
                id: formData.id && !formData.id.startsWith('row-') ? formData.id : `sec-${Date.now()}`,
                type: formData.type,
                nutrientType: formData.nutrientType,
                emoji: formData.emoji || '🥗',
                titleEn: formData.titleEn,
                titleAm: formData.titleAm,
                titleOr: formData.titleOr,
                titleSo: formData.titleSo,
                bodyEn: formData.bodyEn,
                bodyAm: formData.bodyAm,
                bodyOr: formData.bodyOr,
                bodySo: formData.bodySo,
                imageUrl: formData.imageUrl || '',
                videoUrl: formData.videoUrl || '',
                benefitValue: formData.benefitValue || '',
                benefitLabelEn: formData.benefitLabelEn || '',
                benefitLabelAm: formData.benefitLabelAm || '',
                benefitLabelOr: formData.benefitLabelOr || '',
                benefitLabelSo: formData.benefitLabelSo || '',
                helpfulTips: formData.helpfulTips || '',
                foods: formData.foods,
            };

            if (isEditModalOpen && formData.parentId) {
                // Editing existing nutrient: fetch parent row, replace the section, save back
                const parentRow = rawRows.find(r => r.id === formData.parentId);
                if (parentRow) {
                    let secArr: any[] = [];
                    if (parentRow.nutrient_sections_json || parentRow.nutrientSectionsJson) {
                        const rawSec = parentRow.nutrient_sections_json || parentRow.nutrientSectionsJson;
                        try { secArr = typeof rawSec === 'string' ? JSON.parse(rawSec) : rawSec; } catch { secArr = []; }
                    }

                    const targetId = formData.id;
                    const matchIdx = secArr.findIndex((s: any) => s.id === targetId);

                    if (matchIdx >= 0) {
                        secArr[matchIdx] = nutrientSectionObj;
                    } else {
                        secArr = [nutrientSectionObj];
                    }

                    await cmsClient.update('nutrition', formData.parentId, {
                        trimester: formData.trimester,
                        week: formData.week,
                        type: formData.type,
                        emoji: formData.emoji,
                        nutrientType: formData.nutrientType,
                        titleEn: formData.titleEn,
                        titleAm: formData.titleAm,
                        titleOr: formData.titleOr,
                        titleSo: formData.titleSo,
                        bodyEn: formData.bodyEn,
                        bodyAm: formData.bodyAm,
                        bodyOr: formData.bodyOr,
                        bodySo: formData.bodySo,
                        imageUrl: formData.imageUrl,
                        videoUrl: formData.videoUrl,
                        benefitValue: formData.benefitValue,
                        benefitLabelEn: formData.benefitLabelEn,
                        benefitLabelAm: formData.benefitLabelAm,
                        benefitLabelOr: formData.benefitLabelOr,
                        benefitLabelSo: formData.benefitLabelSo,
                        nutrientSectionsJson: JSON.stringify(secArr),
                        foodsJson: JSON.stringify(formData.foods),
                    });
                }
                setIsEditModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Nutrient Updated Successfully!',
                    message: `Nutrient "${formData.nutrientType}" for Week ${formData.week} has been updated.`,
                });
            } else if (existingRow) {
                // Parent row exists -> Append nutrient via PATCH endpoint
                await fetch(`/api/v1/admin/cms/nutrition/${existingRow.id}/add-nutrient`, {
                    method: 'PATCH',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(nutrientSectionObj),
                });
                setIsAddModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Nutrient Added Successfully!',
                    message: `New nutrient "${formData.nutrientType}" added to Week ${formData.week}!`,
                });
            } else {
                // No parent row exists -> Create new nutrition row
                await cmsClient.create('nutrition', {
                    trimester: formData.trimester,
                    week: formData.week,
                    type: formData.type,
                    emoji: formData.emoji || '🥗',
                    nutrientType: formData.nutrientType,
                    titleEn: formData.titleEn,
                    titleAm: formData.titleAm,
                    titleOr: formData.titleOr,
                    titleSo: formData.titleSo,
                    bodyEn: formData.bodyEn,
                    bodyAm: formData.bodyAm,
                    bodyOr: formData.bodyOr,
                    bodySo: formData.bodySo,
                    imageUrl: formData.imageUrl,
                    videoUrl: formData.videoUrl,
                    benefitValue: formData.benefitValue,
                    benefitLabelEn: formData.benefitLabelEn,
                    benefitLabelAm: formData.benefitLabelAm,
                    benefitLabelOr: formData.benefitLabelOr,
                    benefitLabelSo: formData.benefitLabelSo,
                    nutrientSectionsJson: JSON.stringify([nutrientSectionObj]),
                    foodsJson: JSON.stringify(formData.foods),
                    isPublished: true,
                });
                setIsAddModalOpen(false);
                setSuccessModal({
                    open: true,
                    title: 'Nutrient Guide Created!',
                    message: `Nutrient "${formData.nutrientType}" created for Week ${formData.week}.`,
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
            const parentRow = rawRows.find(r => r.id === nutrientToDelete.parentId);
            if (parentRow) {
                let secArr: any[] = [];
                if (parentRow.nutrient_sections_json || parentRow.nutrientSectionsJson) {
                    const rawSec = parentRow.nutrient_sections_json || parentRow.nutrientSectionsJson;
                    try { secArr = typeof rawSec === 'string' ? JSON.parse(rawSec) : rawSec; } catch { secArr = []; }
                }

                if (Array.isArray(secArr) && secArr.length > 1) {
                    // Remove section from array
                    const nextSec = secArr.filter((s: any) => s.id !== nutrientToDelete.id);
                    await cmsClient.update('nutrition', parentRow.id, {
                        nutrientSectionsJson: JSON.stringify(nextSec),
                    });
                } else {
                    // Last section -> delete whole parent row
                    await cmsClient.delete('nutrition', parentRow.id);
                }
            }

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
        if (!nutrient.parentId) return;
        try {
            const newStatus = !nutrient.isPublished;
            await cmsClient.update('nutrition', nutrient.parentId, {
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
                                {createdWeeks.length > 0 ? `All Created Weeks (${createdWeeks.length})` : 'All Weeks (1–40)'}
                            </option>
                            {(createdWeeks.length > 0 ? createdWeeks : Array.from({ length: 40 }, (_, i) => i + 1)).map(w => (
                                <option key={w} value={w}>Week {w}</option>
                            ))}
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
                                            {item.benefitValue && (
                                                <div className="flex items-center gap-1 px-2.5 py-1 bg-emerald-50 text-emerald-700 rounded-lg border border-emerald-100 font-bold">
                                                    <Sparkles className="w-3.5 h-3.5" />
                                                    <span>{benefitLabel ? `${benefitLabel}: ` : ''}{item.benefitValue}</span>
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
                                    Pregnancy Week * {createdWeeks.length > 0 ? `(${createdWeeks.length} Created Weeks)` : ''}
                                </label>
                                <select
                                    value={formData.week}
                                    onChange={e => handleWeekChangeInForm(Number(e.target.value))}
                                    className="w-full text-xs font-semibold rounded-xl px-3 py-2 border border-gray-200 bg-white focus:outline-none focus:border-[#61183e]"
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

                    {/* SECTION 2: NUTRIENT IDENTIFIER & EMOJI */}
                    <div className="space-y-4">
                        <h4 className="text-xs font-bold text-gray-800 uppercase tracking-wider flex items-center gap-2">
                            <Utensils className="w-4 h-4 text-[#61183e]" />
                            2. Nutrient Basic Details
                        </h4>

                        <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                            <div className="sm:col-span-3">
                                <label className="block text-xs font-bold text-gray-700 mb-1">Nutrient Type Name (e.g., Iron, Calcium, Protein) *</label>
                                <Input
                                    value={formData.nutrientType}
                                    onChange={e => setFormData(prev => ({ ...prev, nutrientType: e.target.value }))}
                                    placeholder="e.g. Iron, Foliate, Calcium, Hydration"
                                    required
                                    className="w-full text-xs rounded-xl"
                                />
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-700 mb-1">Emoji Icon</label>
                                <Input
                                    value={formData.emoji}
                                    onChange={e => setFormData(prev => ({ ...prev, emoji: e.target.value }))}
                                    placeholder="🥩"
                                    className="w-full text-xs text-center text-lg rounded-xl"
                                />
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
                                <MediaInput
                                    label="Nutrient Video (Upload or URL)"
                                    value={formData.videoUrl || ''}
                                    onChange={url => setFormData(prev => ({ ...prev, videoUrl: url }))}
                                    type="video"
                                />
                            </div>
                        </div>
                    </div>

                    {/* SECTION 6: BENEFITS & HELPFUL TIPS */}
                    <div className="space-y-3 p-4 bg-emerald-50/40 rounded-2xl border border-emerald-100">
                        <h4 className="text-xs font-bold text-emerald-900 uppercase tracking-wider flex items-center gap-2">
                            <Sparkles className="w-4 h-4" />
                            6. Benefit Value & Labels (4 Languages)
                        </h4>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div className="sm:col-span-2">
                                <label className="block text-xs font-bold text-gray-700 mb-1">Benefit Value (e.g. 27 mg/day, 1000 mg)</label>
                                <Input
                                    value={formData.benefitValue}
                                    onChange={e => setFormData(prev => ({ ...prev, benefitValue: e.target.value }))}
                                    placeholder="e.g. 27 mg/day"
                                    className="text-xs rounded-xl"
                                />
                            </div>
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

                        <div className="pt-2">
                            <label className="block text-xs font-bold text-gray-700 mb-1">Helpful Tips / Extra Notes</label>
                            <TextArea
                                value={formData.helpfulTips}
                                onChange={e => setFormData(prev => ({ ...prev, helpfulTips: e.target.value }))}
                                placeholder="e.g. Take with Vitamin C for better absorption..."
                                rows={2}
                                className="text-xs rounded-xl"
                            />
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

                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇬🇧 Food Name (EN)</label>
                                        <Input
                                            value={food.nameEn}
                                            onChange={e => handleFoodChange(fIdx, 'nameEn', e.target.value)}
                                            placeholder="Spinach, Lentils, Red Meat..."
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇪🇹 Food Name (AM)</label>
                                        <Input
                                            value={food.nameAm}
                                            onChange={e => handleFoodChange(fIdx, 'nameAm', e.target.value)}
                                            placeholder="ስፒናች፣ ምስር..."
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🌳 Food Name (OR)</label>
                                        <Input
                                            value={food.nameOr}
                                            onChange={e => handleFoodChange(fIdx, 'nameOr', e.target.value)}
                                            placeholder="Isbiinaaqii..."
                                            className="text-xs rounded-xl"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-semibold text-gray-600 mb-1">🇸🇴 Food Name (SO)</label>
                                        <Input
                                            value={food.nameSo}
                                            onChange={e => handleFoodChange(fIdx, 'nameSo', e.target.value)}
                                            placeholder="Isbanaaj..."
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
