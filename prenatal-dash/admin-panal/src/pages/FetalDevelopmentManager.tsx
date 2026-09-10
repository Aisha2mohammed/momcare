import { useState, useEffect, useCallback } from 'react';
import { Plus, Edit2, Trash2, Search, Loader2, ChevronLeft, ChevronRight, Globe } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { MediaInput } from '../components/ui/MediaInput';
import { useToast } from '../context/ToastContext';
import { cmsClient } from '../services/api';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface FetalEntry {
    id: string | number;
    week_number?: number;
    weekNumber?: number;
    week?: number;
    trimester?: number;
    // Titles
    title_en?: string; titleEn?: string;
    title_am?: string; titleAm?: string;
    title_om?: string; titleOm?: string;
    title_so?: string; titleSo?: string;
    // Images
    image_url?: string; imageUrl?: string;
    image_alt_en?: string; imageAltEn?: string;
    image_alt_am?: string; imageAltAm?: string;
    image_alt_om?: string; imageAltOm?: string;
    image_alt_so?: string; imageAltSo?: string;
    // Summary
    summary_en?: string; summaryEn?: string;
    summary_am?: string; summaryAm?: string;
    summary_om?: string; summaryOm?: string;
    summary_so?: string; summarySo?: string;
    // Baby measurements
    baby_length_cm?: number; babyLengthCm?: number;
    baby_weight_g?: number; babyWeightG?: number;
    // Size comparison
    size_comparison_en?: string; sizeComparisonEn?: string;
    size_comparison_am?: string; sizeComparisonAm?: string;
    size_comparison_om?: string; sizeComparisonOm?: string;
    size_comparison_so?: string; sizeComparisonSo?: string;
    // Milestone
    milestone_en?: string; milestoneEn?: string;
    milestone_am?: string; milestoneAm?: string;
    milestone_om?: string; milestoneOm?: string;
    milestone_so?: string; milestoneSo?: string;
    // Physical development
    physical_development_en?: string; physicalDevelopmentEn?: string;
    physical_development_am?: string; physicalDevelopmentAm?: string;
    physical_development_om?: string; physicalDevelopmentOm?: string;
    physical_development_so?: string; physicalDevelopmentSo?: string;
    // Brain dev
    brain_dev_en?: string; brainDevEn?: string;
    brain_dev_am?: string; brainDevAm?: string;
    brain_dev_om?: string; brainDevOm?: string;
    brain_dev_so?: string; brainDevSo?: string;
    // Heart dev
    heart_dev_en?: string; heartDevEn?: string;
    heart_dev_am?: string; heartDevAm?: string;
    heart_dev_om?: string; heartDevOm?: string;
    heart_dev_so?: string; heartDevSo?: string;
    // Organ dev
    organ_dev_en?: string; organDevEn?: string;
    organ_dev_am?: string; organDevAm?: string;
    organ_dev_om?: string; organDevOm?: string;
    organ_dev_so?: string; organDevSo?: string;
    // Bone/muscle dev
    bone_muscle_dev_en?: string; boneMuscleDevEn?: string;
    bone_muscle_dev_am?: string; boneMuscleDevAm?: string;
    bone_muscle_dev_om?: string; boneMuscleDevOm?: string;
    bone_muscle_dev_so?: string; boneMuscleDevSo?: string;
    // Movement
    movement_en?: string; movementEn?: string;
    movement_am?: string; movementAm?: string;
    movement_om?: string; movementOm?: string;
    movement_so?: string; movementSo?: string;
    // Maternal changes
    maternal_changes_en?: string; maternalChangesEn?: string;
    maternal_changes_am?: string; maternalChangesAm?: string;
    maternal_changes_om?: string; maternalChangesOm?: string;
    maternal_changes_so?: string; maternalChangesSo?: string;
    // Common symptoms
    common_symptoms_en?: string; commonSymptomsEn?: string;
    common_symptoms_am?: string; commonSymptomsAm?: string;
    common_symptoms_om?: string; commonSymptomsOm?: string;
    common_symptoms_so?: string; commonSymptomsSo?: string;
    // Health tip
    health_tip_en?: string; healthTipEn?: string;
    health_tip_am?: string; healthTipAm?: string;
    health_tip_om?: string; healthTipOm?: string;
    health_tip_so?: string; healthTipSo?: string;
    // Antenatal care
    antenatal_care_en?: string; antenatalCareEn?: string;
    antenatal_care_am?: string; antenatalCareAm?: string;
    antenatal_care_om?: string; antenatalCareOm?: string;
    antenatal_care_so?: string; antenatalCareSo?: string;
    // Screening
    screening_information_en?: string; screeningInformationEn?: string;
    screening_information_am?: string; screeningInformationAm?: string;
    screening_information_om?: string; screeningInformationOm?: string;
    screening_information_so?: string; screeningInformationSo?: string;
    // Bonding activity
    bonding_activity_title_en?: string; bondingActivityTitleEn?: string;
    bonding_activity_title_am?: string; bondingActivityTitleAm?: string;
    bonding_activity_title_om?: string; bondingActivityTitleOm?: string;
    bonding_activity_title_so?: string; bondingActivityTitleSo?: string;
    bonding_activity_description_en?: string; bondingActivityDescriptionEn?: string;
    bonding_activity_description_am?: string; bondingActivityDescriptionAm?: string;
    bonding_activity_description_om?: string; bondingActivityDescriptionOm?: string;
    bonding_activity_description_so?: string; bondingActivityDescriptionSo?: string;
    // Emotional message
    emotional_message_en?: string; emotionalMessageEn?: string;
    emotional_message_am?: string; emotionalMessageAm?: string;
    emotional_message_om?: string; emotionalMessageOm?: string;
    emotional_message_so?: string; emotionalMessageSo?: string;
    // Diary prompt
    diary_prompt_en?: string; diaryPromptEn?: string;
    diary_prompt_am?: string; diaryPromptAm?: string;
    diary_prompt_om?: string; diaryPromptOm?: string;
    diary_prompt_so?: string; diaryPromptSo?: string;
    // Warning signs
    warning_signs_en?: string; warningSignsEn?: string;
    warning_signs_am?: string; warningSignsAm?: string;
    warning_signs_om?: string; warningSignsOm?: string;
    warning_signs_so?: string; warningSignsSo?: string;
    // When to contact
    when_to_contact_provider_en?: string; whenToContactProviderEn?: string;
    when_to_contact_provider_am?: string; whenToContactProviderAm?: string;
    when_to_contact_provider_om?: string; whenToContactProviderOm?: string;
    when_to_contact_provider_so?: string; whenToContactProviderSo?: string;
    // Meta
    is_active?: boolean; isActive?: boolean;
}

type FormData = {
    weekNumber: number;
    imageUrl: string;
    babyLengthCm: string;
    babyWeightG: string;
    isActive: boolean;
    // 4 langs × many fields
    titleEn: string; titleAm: string; titleOm: string; titleSo: string;
    imageAltEn: string; imageAltAm: string; imageAltOm: string; imageAltSo: string;
    summaryEn: string; summaryAm: string; summaryOm: string; summarySo: string;
    sizeComparisonEn: string; sizeComparisonAm: string; sizeComparisonOm: string; sizeComparisonSo: string;
    milestoneEn: string; milestoneAm: string; milestoneOm: string; milestoneSo: string;
    physicalDevelopmentEn: string; physicalDevelopmentAm: string; physicalDevelopmentOm: string; physicalDevelopmentSo: string;
    brainDevEn: string; brainDevAm: string; brainDevOm: string; brainDevSo: string;
    heartDevEn: string; heartDevAm: string; heartDevOm: string; heartDevSo: string;
    organDevEn: string; organDevAm: string; organDevOm: string; organDevSo: string;
    boneMuscleDevEn: string; boneMuscleDevAm: string; boneMuscleDevOm: string; boneMuscleDevSo: string;
    movementEn: string; movementAm: string; movementOm: string; movementSo: string;
    maternalChangesEn: string; maternalChangesAm: string; maternalChangesOm: string; maternalChangesSo: string;
    commonSymptomsEn: string; commonSymptomsAm: string; commonSymptomsOm: string; commonSymptomsSo: string;
    healthTipEn: string; healthTipAm: string; healthTipOm: string; healthTipSo: string;
    antenatalCareEn: string; antenatalCareAm: string; antenatalCareOm: string; antenatalCareSo: string;
    screeningInformationEn: string; screeningInformationAm: string; screeningInformationOm: string; screeningInformationSo: string;
    bondingActivityTitleEn: string; bondingActivityTitleAm: string; bondingActivityTitleOm: string; bondingActivityTitleSo: string;
    bondingActivityDescriptionEn: string; bondingActivityDescriptionAm: string; bondingActivityDescriptionOm: string; bondingActivityDescriptionSo: string;
    emotionalMessageEn: string; emotionalMessageAm: string; emotionalMessageOm: string; emotionalMessageSo: string;
    diaryPromptEn: string; diaryPromptAm: string; diaryPromptOm: string; diaryPromptSo: string;
    warningSignsEn: string; warningSignsAm: string; warningSignsOm: string; warningSignsSo: string;
    whenToContactProviderEn: string; whenToContactProviderAm: string; whenToContactProviderOm: string; whenToContactProviderSo: string;
};

const EMPTY_FORM: FormData = {
    weekNumber: 1, imageUrl: '', babyLengthCm: '', babyWeightG: '', isActive: true,
    titleEn: '', titleAm: '', titleOm: '', titleSo: '',
    imageAltEn: '', imageAltAm: '', imageAltOm: '', imageAltSo: '',
    summaryEn: '', summaryAm: '', summaryOm: '', summarySo: '',
    sizeComparisonEn: '', sizeComparisonAm: '', sizeComparisonOm: '', sizeComparisonSo: '',
    milestoneEn: '', milestoneAm: '', milestoneOm: '', milestoneSo: '',
    physicalDevelopmentEn: '', physicalDevelopmentAm: '', physicalDevelopmentOm: '', physicalDevelopmentSo: '',
    brainDevEn: '', brainDevAm: '', brainDevOm: '', brainDevSo: '',
    heartDevEn: '', heartDevAm: '', heartDevOm: '', heartDevSo: '',
    organDevEn: '', organDevAm: '', organDevOm: '', organDevSo: '',
    boneMuscleDevEn: '', boneMuscleDevAm: '', boneMuscleDevOm: '', boneMuscleDevSo: '',
    movementEn: '', movementAm: '', movementOm: '', movementSo: '',
    maternalChangesEn: '', maternalChangesAm: '', maternalChangesOm: '', maternalChangesSo: '',
    commonSymptomsEn: '', commonSymptomsAm: '', commonSymptomsOm: '', commonSymptomsSo: '',
    healthTipEn: '', healthTipAm: '', healthTipOm: '', healthTipSo: '',
    antenatalCareEn: '', antenatalCareAm: '', antenatalCareOm: '', antenatalCareSo: '',
    screeningInformationEn: '', screeningInformationAm: '', screeningInformationOm: '', screeningInformationSo: '',
    bondingActivityTitleEn: '', bondingActivityTitleAm: '', bondingActivityTitleOm: '', bondingActivityTitleSo: '',
    bondingActivityDescriptionEn: '', bondingActivityDescriptionAm: '', bondingActivityDescriptionOm: '', bondingActivityDescriptionSo: '',
    emotionalMessageEn: '', emotionalMessageAm: '', emotionalMessageOm: '', emotionalMessageSo: '',
    diaryPromptEn: '', diaryPromptAm: '', diaryPromptOm: '', diaryPromptSo: '',
    warningSignsEn: '', warningSignsAm: '', warningSignsOm: '', warningSignsSo: '',
    whenToContactProviderEn: '', whenToContactProviderAm: '', whenToContactProviderOm: '', whenToContactProviderSo: '',
};

// ── Wizard page definitions ────────────────────────────────────────────────────

const LANG_TABS = [
    { code: 'En', label: '🇬🇧 EN', color: '#2563EB' },
    { code: 'Am', label: '🇪🇹 AM', color: '#7C3AED' },
    { code: 'Om', label: '🌿 OM', color: '#059669' },
    { code: 'So', label: '🌊 SO', color: '#DB2777' },
];

function pick(entry: FetalEntry, camel: string, snake: string): string {
    const v = (entry as any)[camel] ?? (entry as any)[snake];
    return (typeof v === 'string' ? v : String(v ?? '')).trim();
}

function entryToForm(e: FetalEntry): FormData {
    const f = (camel: string, snake: string) => pick(e, camel, snake);
    return {
        weekNumber: e.week_number ?? e.weekNumber ?? e.week ?? 1,
        imageUrl: f('imageUrl', 'image_url'),
        babyLengthCm: String(e.baby_length_cm ?? e.babyLengthCm ?? ''),
        babyWeightG: String(e.baby_weight_g ?? e.babyWeightG ?? ''),
        isActive: e.is_active ?? e.isActive ?? true,
        titleEn: f('titleEn', 'title_en'), titleAm: f('titleAm', 'title_am'), titleOm: f('titleOm', 'title_om'), titleSo: f('titleSo', 'title_so'),
        imageAltEn: f('imageAltEn', 'image_alt_en'), imageAltAm: f('imageAltAm', 'image_alt_am'), imageAltOm: f('imageAltOm', 'image_alt_om'), imageAltSo: f('imageAltSo', 'image_alt_so'),
        summaryEn: f('summaryEn', 'summary_en'), summaryAm: f('summaryAm', 'summary_am'), summaryOm: f('summaryOm', 'summary_om'), summarySo: f('summarySo', 'summary_so'),
        sizeComparisonEn: f('sizeComparisonEn', 'size_comparison_en'), sizeComparisonAm: f('sizeComparisonAm', 'size_comparison_am'), sizeComparisonOm: f('sizeComparisonOm', 'size_comparison_om'), sizeComparisonSo: f('sizeComparisonSo', 'size_comparison_so'),
        milestoneEn: f('milestoneEn', 'milestone_en'), milestoneAm: f('milestoneAm', 'milestone_am'), milestoneOm: f('milestoneOm', 'milestone_om'), milestoneSo: f('milestoneSo', 'milestone_so'),
        physicalDevelopmentEn: f('physicalDevelopmentEn', 'physical_development_en'), physicalDevelopmentAm: f('physicalDevelopmentAm', 'physical_development_am'), physicalDevelopmentOm: f('physicalDevelopmentOm', 'physical_development_om'), physicalDevelopmentSo: f('physicalDevelopmentSo', 'physical_development_so'),
        brainDevEn: f('brainDevEn', 'brain_dev_en'), brainDevAm: f('brainDevAm', 'brain_dev_am'), brainDevOm: f('brainDevOm', 'brain_dev_om'), brainDevSo: f('brainDevSo', 'brain_dev_so'),
        heartDevEn: f('heartDevEn', 'heart_dev_en'), heartDevAm: f('heartDevAm', 'heart_dev_am'), heartDevOm: f('heartDevOm', 'heart_dev_om'), heartDevSo: f('heartDevSo', 'heart_dev_so'),
        organDevEn: f('organDevEn', 'organ_dev_en'), organDevAm: f('organDevAm', 'organ_dev_am'), organDevOm: f('organDevOm', 'organ_dev_om'), organDevSo: f('organDevSo', 'organ_dev_so'),
        boneMuscleDevEn: f('boneMuscleDevEn', 'bone_muscle_dev_en'), boneMuscleDevAm: f('boneMuscleDevAm', 'bone_muscle_dev_am'), boneMuscleDevOm: f('boneMuscleDevOm', 'bone_muscle_dev_om'), boneMuscleDevSo: f('boneMuscleDevSo', 'bone_muscle_dev_so'),
        movementEn: f('movementEn', 'movement_en'), movementAm: f('movementAm', 'movement_am'), movementOm: f('movementOm', 'movement_om'), movementSo: f('movementSo', 'movement_so'),
        maternalChangesEn: f('maternalChangesEn', 'maternal_changes_en'), maternalChangesAm: f('maternalChangesAm', 'maternal_changes_am'), maternalChangesOm: f('maternalChangesOm', 'maternal_changes_om'), maternalChangesSo: f('maternalChangesSo', 'maternal_changes_so'),
        commonSymptomsEn: f('commonSymptomsEn', 'common_symptoms_en'), commonSymptomsAm: f('commonSymptomsAm', 'common_symptoms_am'), commonSymptomsOm: f('commonSymptomsOm', 'common_symptoms_om'), commonSymptomsSo: f('commonSymptomsSo', 'common_symptoms_so'),
        healthTipEn: f('healthTipEn', 'health_tip_en'), healthTipAm: f('healthTipAm', 'health_tip_am'), healthTipOm: f('healthTipOm', 'health_tip_om'), healthTipSo: f('healthTipSo', 'health_tip_so'),
        antenatalCareEn: f('antenatalCareEn', 'antenatal_care_en'), antenatalCareAm: f('antenatalCareAm', 'antenatal_care_am'), antenatalCareOm: f('antenatalCareOm', 'antenatal_care_om'), antenatalCareSo: f('antenatalCareSo', 'antenatal_care_so'),
        screeningInformationEn: f('screeningInformationEn', 'screening_information_en'), screeningInformationAm: f('screeningInformationAm', 'screening_information_am'), screeningInformationOm: f('screeningInformationOm', 'screening_information_om'), screeningInformationSo: f('screeningInformationSo', 'screening_information_so'),
        bondingActivityTitleEn: f('bondingActivityTitleEn', 'bonding_activity_title_en'), bondingActivityTitleAm: f('bondingActivityTitleAm', 'bonding_activity_title_am'), bondingActivityTitleOm: f('bondingActivityTitleOm', 'bonding_activity_title_om'), bondingActivityTitleSo: f('bondingActivityTitleSo', 'bonding_activity_title_so'),
        bondingActivityDescriptionEn: f('bondingActivityDescriptionEn', 'bonding_activity_description_en'), bondingActivityDescriptionAm: f('bondingActivityDescriptionAm', 'bonding_activity_description_am'), bondingActivityDescriptionOm: f('bondingActivityDescriptionOm', 'bonding_activity_description_om'), bondingActivityDescriptionSo: f('bondingActivityDescriptionSo', 'bonding_activity_description_so'),
        emotionalMessageEn: f('emotionalMessageEn', 'emotional_message_en'), emotionalMessageAm: f('emotionalMessageAm', 'emotional_message_am'), emotionalMessageOm: f('emotionalMessageOm', 'emotional_message_om'), emotionalMessageSo: f('emotionalMessageSo', 'emotional_message_so'),
        diaryPromptEn: f('diaryPromptEn', 'diary_prompt_en'), diaryPromptAm: f('diaryPromptAm', 'diary_prompt_am'), diaryPromptOm: f('diaryPromptOm', 'diary_prompt_om'), diaryPromptSo: f('diaryPromptSo', 'diary_prompt_so'),
        warningSignsEn: f('warningSignsEn', 'warning_signs_en'), warningSignsAm: f('warningSignsAm', 'warning_signs_am'), warningSignsOm: f('warningSignsOm', 'warning_signs_om'), warningSignsSo: f('warningSignsSo', 'warning_signs_so'),
        whenToContactProviderEn: f('whenToContactProviderEn', 'when_to_contact_provider_en'), whenToContactProviderAm: f('whenToContactProviderAm', 'when_to_contact_provider_am'), whenToContactProviderOm: f('whenToContactProviderOm', 'when_to_contact_provider_om'), whenToContactProviderSo: f('whenToContactProviderSo', 'when_to_contact_provider_so'),
    };
}

// ─── Wizard Pages ────────────────────────────────────────────────────────────

const WIZARD_PAGES = [
    { title: '1. Basic Info', icon: '📋' },
    { title: '2. Milestone & Summary', icon: '⭐' },
    { title: '3. Baby Development', icon: '🧬' },
    { title: '4. Mother & Symptoms', icon: '🤱' },
    { title: '5. Care & Safety', icon: '🏥' },
    { title: '6. Bonding & Emotions', icon: '💕' },
];

// Language Tab Selector
function LangTabs({ active, onChange }: { active: string; onChange: (l: string) => void }) {
    return (
        <div className="flex gap-2 mb-4 flex-wrap">
            {LANG_TABS.map(lt => (
                <button
                    key={lt.code}
                    onClick={() => onChange(lt.code)}
                    className={`px-3 py-1.5 text-sm rounded-lg font-semibold transition-all border ${active === lt.code ? 'text-white border-transparent shadow-sm' : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}`}
                    style={active === lt.code ? { backgroundColor: lt.color, borderColor: lt.color } : {}}
                >
                    {lt.label}
                </button>
            ))}
        </div>
    );
}

// 4-lang TextArea group
function LangTextAreas({ label, field, form, setForm, rows = 3 }: {
    label: string; field: string; form: FormData; setForm: (u: (f: FormData) => FormData) => void; rows?: number;
}) {
    const [lang, setLang] = useState('En');
    const key = `${field}${lang}` as keyof FormData;
    const placeholders: Record<string, string> = { En: 'English…', Am: 'አማርኛ…', Om: 'Afaan Oromo…', So: 'Af-Soomaali…' };
    return (
        <div>
            <div className="flex items-center justify-between mb-1">
                <label className="text-sm font-medium text-gray-700">{label}</label>
                <div className="flex gap-1">
                    {LANG_TABS.map(lt => (
                        <button key={lt.code} onClick={() => setLang(lt.code)}
                            className={`px-2 py-0.5 text-xs rounded font-medium transition-all ${lang === lt.code ? 'text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'}`}
                            style={lang === lt.code ? { backgroundColor: lt.color } : {}}
                        >{lt.label}</button>
                    ))}
                </div>
            </div>
            <TextArea
                label=""
                value={(form[key] as string) || ''}
                onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                rows={rows}
                placeholder={placeholders[lang]}
            />
        </div>
    );
}

// 4-lang Input group
function LangInputs({ label, field, form, setForm }: {
    label: string; field: string; form: FormData; setForm: (u: (f: FormData) => FormData) => void;
}) {
    const [lang, setLang] = useState('En');
    const key = `${field}${lang}` as keyof FormData;
    const placeholders: Record<string, string> = { En: 'English…', Am: 'አማርኛ…', Om: 'Afaan Oromo…', So: 'Af-Soomaali…' };
    return (
        <div>
            <div className="flex items-center justify-between mb-1">
                <label className="text-sm font-medium text-gray-700">{label}</label>
                <div className="flex gap-1">
                    {LANG_TABS.map(lt => (
                        <button key={lt.code} onClick={() => setLang(lt.code)}
                            className={`px-2 py-0.5 text-xs rounded font-medium transition-all ${lang === lt.code ? 'text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'}`}
                            style={lang === lt.code ? { backgroundColor: lt.color } : {}}
                        >{lt.label}</button>
                    ))}
                </div>
            </div>
            <input
                type="text"
                value={(form[key] as string) || ''}
                onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                placeholder={placeholders[lang]}
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-[#61183e]"
            />
        </div>
    );
}

// ─── Main Component ──────────────────────────────────────────────────────────

export default function FetalDevelopmentManager() {
    const { showToast } = useToast();
    const [entries, setEntries] = useState<FetalEntry[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<FetalEntry | null>(null);
    const [form, setForm] = useState<FormData>(EMPTY_FORM);
    const [saving, setSaving] = useState(false);
    const [page, setPage] = useState(0); // wizard page

    // ── Fetch ─────────────────────────────────────────────────────────────────
    const fetchEntries = useCallback(async (search: string) => {
        try {
            setLoading(true);
            const params: any = { limit: 50 };
            if (search.trim()) params.search = search.trim();
            const res = await cmsClient.list<FetalEntry>('fetal', params);
            setEntries(res.items);
        } catch (err: any) {
            showToast(err.message || 'Failed to load fetal data', 'error');
        } finally {
            setLoading(false);
        }
    }, [showToast]);

    useEffect(() => {
        const t = setTimeout(() => fetchEntries(searchTerm), 250);
        return () => clearTimeout(t);
    }, [searchTerm, fetchEntries]);

    const refresh = () => fetchEntries(searchTerm);

    // ── Open modals ───────────────────────────────────────────────────────────
    function openCreate() {
        setEditing(null);
        setForm(EMPTY_FORM);
        setPage(0);
        setModalOpen(true);
    }

    function openEdit(e: FetalEntry) {
        setEditing(e);
        setForm(entryToForm(e));
        setPage(0);
        setModalOpen(true);
    }

    async function handleDelete(id: string | number) {
        if (!window.confirm('Delete this week entry?')) return;
        try {
            await cmsClient.delete('fetal', id);
            showToast('Week entry deleted.', 'success');
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to delete.', 'error');
        }
    }

    // ── Save ──────────────────────────────────────────────────────────────────
    async function handleSave() {
        if (!form.weekNumber || form.weekNumber < 1 || form.weekNumber > 42) {
            showToast('Week number must be between 1 and 42.', 'error');
            setPage(0);
            return;
        }
        try {
            setSaving(true);
            const payload = {
                weekNumber: form.weekNumber,
                imageUrl: form.imageUrl || undefined,
                babyLengthCm: form.babyLengthCm ? parseFloat(form.babyLengthCm) : undefined,
                babyWeightG: form.babyWeightG ? parseFloat(form.babyWeightG) : undefined,
                isActive: form.isActive,
                titleEn: form.titleEn || undefined, titleAm: form.titleAm || undefined, titleOm: form.titleOm || undefined, titleSo: form.titleSo || undefined,
                imageAltEn: form.imageAltEn || undefined, imageAltAm: form.imageAltAm || undefined, imageAltOm: form.imageAltOm || undefined, imageAltSo: form.imageAltSo || undefined,
                summaryEn: form.summaryEn || undefined, summaryAm: form.summaryAm || undefined, summaryOm: form.summaryOm || undefined, summarySo: form.summarySo || undefined,
                sizeComparisonEn: form.sizeComparisonEn || undefined, sizeComparisonAm: form.sizeComparisonAm || undefined, sizeComparisonOm: form.sizeComparisonOm || undefined, sizeComparisonSo: form.sizeComparisonSo || undefined,
                milestoneEn: form.milestoneEn || undefined, milestoneAm: form.milestoneAm || undefined, milestoneOm: form.milestoneOm || undefined, milestoneSo: form.milestoneSo || undefined,
                physicalDevelopmentEn: form.physicalDevelopmentEn || undefined, physicalDevelopmentAm: form.physicalDevelopmentAm || undefined, physicalDevelopmentOm: form.physicalDevelopmentOm || undefined, physicalDevelopmentSo: form.physicalDevelopmentSo || undefined,
                brainDevEn: form.brainDevEn || undefined, brainDevAm: form.brainDevAm || undefined, brainDevOm: form.brainDevOm || undefined, brainDevSo: form.brainDevSo || undefined,
                heartDevEn: form.heartDevEn || undefined, heartDevAm: form.heartDevAm || undefined, heartDevOm: form.heartDevOm || undefined, heartDevSo: form.heartDevSo || undefined,
                organDevEn: form.organDevEn || undefined, organDevAm: form.organDevAm || undefined, organDevOm: form.organDevOm || undefined, organDevSo: form.organDevSo || undefined,
                boneMuscleDevEn: form.boneMuscleDevEn || undefined, boneMuscleDevAm: form.boneMuscleDevAm || undefined, boneMuscleDevOm: form.boneMuscleDevOm || undefined, boneMuscleDevSo: form.boneMuscleDevSo || undefined,
                movementEn: form.movementEn || undefined, movementAm: form.movementAm || undefined, movementOm: form.movementOm || undefined, movementSo: form.movementSo || undefined,
                maternalChangesEn: form.maternalChangesEn || undefined, maternalChangesAm: form.maternalChangesAm || undefined, maternalChangesOm: form.maternalChangesOm || undefined, maternalChangesSo: form.maternalChangesSo || undefined,
                commonSymptomsEn: form.commonSymptomsEn || undefined, commonSymptomsAm: form.commonSymptomsAm || undefined, commonSymptomsOm: form.commonSymptomsOm || undefined, commonSymptomsSo: form.commonSymptomsSo || undefined,
                healthTipEn: form.healthTipEn || undefined, healthTipAm: form.healthTipAm || undefined, healthTipOm: form.healthTipOm || undefined, healthTipSo: form.healthTipSo || undefined,
                antenatalCareEn: form.antenatalCareEn || undefined, antenatalCareAm: form.antenatalCareAm || undefined, antenatalCareOm: form.antenatalCareOm || undefined, antenatalCareSo: form.antenatalCareSo || undefined,
                screeningInformationEn: form.screeningInformationEn || undefined, screeningInformationAm: form.screeningInformationAm || undefined, screeningInformationOm: form.screeningInformationOm || undefined, screeningInformationSo: form.screeningInformationSo || undefined,
                bondingActivityTitleEn: form.bondingActivityTitleEn || undefined, bondingActivityTitleAm: form.bondingActivityTitleAm || undefined, bondingActivityTitleOm: form.bondingActivityTitleOm || undefined, bondingActivityTitleSo: form.bondingActivityTitleSo || undefined,
                bondingActivityDescriptionEn: form.bondingActivityDescriptionEn || undefined, bondingActivityDescriptionAm: form.bondingActivityDescriptionAm || undefined, bondingActivityDescriptionOm: form.bondingActivityDescriptionOm || undefined, bondingActivityDescriptionSo: form.bondingActivityDescriptionSo || undefined,
                emotionalMessageEn: form.emotionalMessageEn || undefined, emotionalMessageAm: form.emotionalMessageAm || undefined, emotionalMessageOm: form.emotionalMessageOm || undefined, emotionalMessageSo: form.emotionalMessageSo || undefined,
                diaryPromptEn: form.diaryPromptEn || undefined, diaryPromptAm: form.diaryPromptAm || undefined, diaryPromptOm: form.diaryPromptOm || undefined, diaryPromptSo: form.diaryPromptSo || undefined,
                warningSignsEn: form.warningSignsEn || undefined, warningSignsAm: form.warningSignsAm || undefined, warningSignsOm: form.warningSignsOm || undefined, warningSignsSo: form.warningSignsSo || undefined,
                whenToContactProviderEn: form.whenToContactProviderEn || undefined, whenToContactProviderAm: form.whenToContactProviderAm || undefined, whenToContactProviderOm: form.whenToContactProviderOm || undefined, whenToContactProviderSo: form.whenToContactProviderSo || undefined,
            };

            if (editing) {
                await cmsClient.update('fetal', editing.id, payload);
                showToast(`Week ${form.weekNumber} updated!`, 'success');
            } else {
                await cmsClient.create('fetal', payload);
                showToast(`Week ${form.weekNumber} created!`, 'success');
            }
            setModalOpen(false);
            refresh();
        } catch (err: any) {
            showToast(err.message || 'Failed to save.', 'error');
        } finally {
            setSaving(false);
        }
    }

    // ── Render ────────────────────────────────────────────────────────────────
    const sorted = [...entries].sort((a, b) =>
        (a.week_number ?? a.weekNumber ?? a.week ?? 0) - (b.week_number ?? b.weekNumber ?? b.week ?? 0)
    );

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Fetal Development Tracker</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage week-by-week development data in 4 languages (Weeks 1–42)</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Week Entry</Button>
            </div>

            {/* Search */}
            <div className="relative bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
                <Search className="w-4 h-4 absolute left-6 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                    type="text"
                    placeholder="Search fetal development weeks…"
                    value={searchTerm}
                    onChange={e => setSearchTerm(e.target.value)}
                    className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-xl focus:outline-none focus:border-[#61183e]"
                />
            </div>

            {/* List */}
            {loading ? (
                <div className="flex flex-col items-center justify-center p-12 text-gray-400">
                    <Loader2 className="w-8 h-8 animate-spin text-[#61183e] mb-2" />
                    <p className="text-sm font-medium">Loading fetal development weeks…</p>
                </div>
            ) : sorted.length === 0 ? (
                <div className="text-center p-12 bg-white rounded-2xl border border-gray-100">
                    <p className="text-gray-500 text-sm">No weeks found. Click "Add Week Entry" to create one.</p>
                </div>
            ) : (
                <div className="grid gap-4">
                    {sorted.map(entry => {
                        const weekNum = entry.week_number ?? entry.weekNumber ?? entry.week ?? 0;
                        const title = entry.title_en ?? entry.titleEn ?? entry.title_am ?? entry.titleAm ?? entry.title_om ?? entry.titleOm ?? entry.title_so ?? entry.titleSo ?? `Week ${weekNum}`;
                        const milestone = entry.milestone_en ?? entry.milestoneEn ?? entry.milestone_am ?? entry.milestoneAm ?? '';
                        const imgUrl = entry.image_url ?? entry.imageUrl ?? '';
                        const trimester = entry.trimester;
                        return (
                            <Card key={entry.id} className="flex items-start gap-5">
                                {/* Week badge */}
                                <div className="shrink-0 w-20 h-20 rounded-2xl bg-gradient-to-br from-[#61183e] to-[#9B2C6B] flex flex-col items-center justify-center">
                                    <span className="text-2xl font-black text-white">{weekNum}</span>
                                    <span className="text-xs text-white/70 font-medium">weeks</span>
                                </div>
                                {/* Info */}
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2 mb-1 flex-wrap">
                                        <h4 className="font-semibold text-gray-900 text-sm truncate">{title}</h4>
                                        {trimester && <Badge variant="pink">T{trimester}</Badge>}
                                        {imgUrl && <span className="text-xs text-green-600">📷</span>}
                                    </div>
                                    {milestone && <p className="text-xs text-gray-600 line-clamp-2">{milestone}</p>}
                                </div>
                                {/* Actions */}
                                <div className="flex gap-2 shrink-0">
                                    <button onClick={() => openEdit(entry)} className="p-2 rounded-lg hover:bg-blue-50 text-blue-600" title="Edit">
                                        <Edit2 className="w-4 h-4" />
                                    </button>
                                    <button onClick={() => handleDelete(entry.id)} className="p-2 rounded-lg hover:bg-red-50 text-red-500" title="Delete">
                                        <Trash2 className="w-4 h-4" />
                                    </button>
                                </div>
                            </Card>
                        );
                    })}
                </div>
            )}

            {/* ── Multi-page Wizard Modal ── */}
            <Modal
                isOpen={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? `Edit Week ${form.weekNumber} Entry` : 'New Fetal Week Entry'}
                size="xl"
            >
                {/* Wizard progress */}
                <div className="flex gap-1 mb-5 overflow-x-auto pb-1">
                    {WIZARD_PAGES.map((wp, i) => (
                        <button
                            key={i}
                            onClick={() => setPage(i)}
                            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium whitespace-nowrap transition-all ${i === page
                                ? 'bg-[#61183e] text-white shadow-sm'
                                : i < page
                                    ? 'bg-green-100 text-green-700'
                                    : 'bg-gray-100 text-gray-500'
                            }`}
                        >
                            <span>{wp.icon}</span>
                            <span>{wp.title}</span>
                        </button>
                    ))}
                </div>

                {/* ── Page 0: Basic Info ── */}
                {page === 0 && (
                    <div className="space-y-4">
                        <div className="grid grid-cols-3 gap-4">
                            <Input
                                label="Week Number (1–42) *"
                                type="number" min={1} max={42}
                                value={form.weekNumber}
                                onChange={e => setForm(f => ({ ...f, weekNumber: parseInt(e.target.value) || 1 }))}
                            />
                            <Input
                                label="Baby Length (cm)"
                                type="number" step="0.1"
                                value={form.babyLengthCm}
                                onChange={e => setForm(f => ({ ...f, babyLengthCm: e.target.value }))}
                                placeholder="14.2"
                            />
                            <Input
                                label="Baby Weight (g)"
                                type="number" step="1"
                                value={form.babyWeightG}
                                onChange={e => setForm(f => ({ ...f, babyWeightG: e.target.value }))}
                                placeholder="190"
                            />
                        </div>
                        <MediaInput
                            label="Cover Image"
                            type="image"
                            value={form.imageUrl}
                            onChange={url => setForm(f => ({ ...f, imageUrl: url }))}
                        />
                        <LangInputs label="Title" field="title" form={form} setForm={setForm} />
                        <LangInputs label="Image Alt Text" field="imageAlt" form={form} setForm={setForm} />
                        <LangInputs label="Size Comparison (e.g. Bell Pepper)" field="sizeComparison" form={form} setForm={setForm} />
                        <label className="flex items-center gap-3 cursor-pointer">
                            <div onClick={() => setForm(f => ({ ...f, isActive: !f.isActive }))}
                                className={`w-11 h-6 rounded-full transition-colors relative ${form.isActive ? 'bg-[#61183e]' : 'bg-gray-300'}`}>
                                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${form.isActive ? 'left-6' : 'left-1'}`} />
                            </div>
                            <span className="text-sm font-medium text-gray-700">Active (visible to mothers)</span>
                        </label>
                    </div>
                )}

                {/* ── Page 1: Milestone & Summary ── */}
                {page === 1 && (
                    <div className="space-y-4">
                        <LangTextAreas label="Summary" field="summary" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Milestone" field="milestone" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Health Tip" field="healthTip" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Movement" field="movement" form={form} setForm={setForm} rows={2} />
                    </div>
                )}

                {/* ── Page 2: Baby Development ── */}
                {page === 2 && (
                    <div className="space-y-4">
                        <LangTextAreas label="Physical Development" field="physicalDevelopment" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Brain Development" field="brainDev" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Heart Development" field="heartDev" form={form} setForm={setForm} rows={2} />
                        <LangTextAreas label="Organ Development" field="organDev" form={form} setForm={setForm} rows={2} />
                        <LangTextAreas label="Bone & Muscle Development" field="boneMuscle" form={form} setForm={setForm} rows={2} />
                    </div>
                )}

                {/* ── Page 3: Mother & Symptoms ── */}
                {page === 3 && (
                    <div className="space-y-4">
                        <LangTextAreas label="Maternal Changes" field="maternalChanges" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Common Symptoms" field="commonSymptoms" form={form} setForm={setForm} rows={3} />
                    </div>
                )}

                {/* ── Page 4: Care & Safety ── */}
                {page === 4 && (
                    <div className="space-y-4">
                        <LangTextAreas label="Antenatal Care" field="antenatalCare" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Screening Information" field="screeningInformation" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="⚠️ Warning Signs" field="warningSigns" form={form} setForm={setForm} rows={2} />
                        <LangTextAreas label="When to Contact Provider" field="whenToContactProvider" form={form} setForm={setForm} rows={2} />
                    </div>
                )}

                {/* ── Page 5: Bonding & Emotions ── */}
                {page === 5 && (
                    <div className="space-y-4">
                        <LangInputs label="Bonding Activity Title" field="bondingActivityTitle" form={form} setForm={setForm} />
                        <LangTextAreas label="Bonding Activity Description" field="bondingActivityDescription" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Emotional Message 💕" field="emotionalMessage" form={form} setForm={setForm} rows={3} />
                        <LangTextAreas label="Diary Prompt" field="diaryPrompt" form={form} setForm={setForm} rows={2} />
                    </div>
                )}

                {/* Navigation footer */}
                <div className="flex items-center justify-between pt-4 border-t border-gray-100 mt-4">
                    <button
                        onClick={() => setPage(p => Math.max(0, p - 1))}
                        disabled={page === 0}
                        className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium bg-gray-100 text-gray-600 disabled:opacity-40 hover:bg-gray-200"
                    >
                        <ChevronLeft className="w-4 h-4" /> Back
                    </button>
                    <span className="text-xs text-gray-400">Step {page + 1} of {WIZARD_PAGES.length}</span>
                    {page < WIZARD_PAGES.length - 1 ? (
                        <button
                            onClick={() => setPage(p => Math.min(WIZARD_PAGES.length - 1, p + 1))}
                            className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium bg-[#61183e] text-white hover:bg-[#7a1f4f]"
                        >
                            Next <ChevronRight className="w-4 h-4" />
                        </button>
                    ) : (
                        <Button onClick={handleSave} disabled={saving}>
                            {saving ? 'Saving…' : editing ? 'Save Changes' : 'Create Entry'}
                        </Button>
                    )}
                </div>
            </Modal>
        </div>
    );
}
