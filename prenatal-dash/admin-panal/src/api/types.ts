// ─── Shared Entity Types ──────────────────────────────────────────────
export type Status = 'Active' | 'Inactive' | 'Suspended';
export type ApprovalStatus = 'Pending' | 'Approved' | 'Rejected';
export type Language = 'English' | 'Amharic' | 'Afan Oromo';

// ─── Mother ───────────────────────────────────────────────────────────
export interface Mother {
    id: string;
    name: string;
    phone: string;
    email: string;
    language: Language;
    week: number;
    dueDate: string;
    status: Status;
    registered: string;
}

// ─── Doctor ───────────────────────────────────────────────────────────
export interface Doctor {
    id: string;
    name: string;
    email: string;
    phone: string;
    specialization: string;
    licenseNumber: string;
    providerId: string;
    providerName: string;
    yearsExperience: number;
    submittedDate: string;
    approvalStatus: ApprovalStatus;
    status: Status;
    rejectionReason?: string;
    credentialImageUrl?: string;
    bio: string;
}

// ─── Health Provider ──────────────────────────────────────────────────
export interface HealthProvider {
    id: string;
    name: string;
    address: string;
    city: string;
    region: string;
    phone: string;
    email: string;
    serviceDescription: string;
    status: Status;
    linkedDoctorCount: number;
    linkedDoctors: string[];
    createdAt: string;
}

// ─── Announcement ─────────────────────────────────────────────────────
export type AnnouncementAudience = 'All' | 'Mothers' | 'Doctors';
export interface Announcement {
    id: string;
    title: string;
    message: string;
    audience: AnnouncementAudience;
    scheduledAt?: string;
    sentAt?: string;
    status: 'Sent' | 'Scheduled' | 'Draft';
    reachCount: number;
    readCount: number;
    createdBy: string;
}

// ─── Audit Log ────────────────────────────────────────────────────────
export type AuditActionType =
    | 'Account Change'
    | 'Content Update'
    | 'Approval'
    | 'Suspension'
    | 'Login'
    | 'Provider Update'
    | 'Announcement Sent'
    | 'Content Delete';

export interface AuditEntry {
    id: string;
    timestamp: string;
    adminUser: string;
    actionType: AuditActionType;
    targetEntity: string;
    beforeSummary?: string;
    afterSummary?: string;
    details: string;
}

// ─── Community ────────────────────────────────────────────────────────
export type TrimesterGroup = 'T1' | 'T2' | 'T3' | 'General';
export interface Post {
    id: string;
    author: string;
    content: string;
    trimesterGroup: TrimesterGroup;
    postedAt: string;
    reportReason?: string;
    isFlagged: boolean;
    reportCount: number;
}

// ─── Analytics ────────────────────────────────────────────────────────
export interface AnalyticsKPIs {
    activeMothers: number;
    activeDoctors: number;
    totalAppointmentsWeek: number;
    totalAppointmentsMonth: number;
    doctorApprovalRate: number;
    mostUsedFeature: string;
}

export interface DateRangeFilter {
    type: '7d' | '30d' | 'custom';
    startDate?: string;
    endDate?: string;
}
