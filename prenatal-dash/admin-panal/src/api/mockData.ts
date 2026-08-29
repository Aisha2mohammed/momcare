import type {
    Mother, Doctor, HealthProvider, Announcement, AuditEntry, Post
} from './types';

// ─── Mothers ──────────────────────────────────────────────────────────
export const mockMothers: Mother[] = [
    { id: 'M001', name: 'Tigist Alemu', phone: '+251911234567', email: 'tigist@example.com', language: 'Amharic', week: 24, dueDate: '2025-09-12', status: 'Active', registered: '2025-05-01' },
    { id: 'M002', name: 'Chaltu Gemechu', phone: '+251922345678', email: 'chaltu@example.com', language: 'Afan Oromo', week: 16, dueDate: '2025-11-03', status: 'Active', registered: '2025-04-28' },
    { id: 'M003', name: 'Selam Bekele', phone: '+251933456789', email: 'selam@example.com', language: 'Amharic', week: 30, dueDate: '2025-08-20', status: 'Suspended', registered: '2025-04-25' },
    { id: 'M004', name: 'Hirut Tadesse', phone: '+251944567890', email: 'hirut@example.com', language: 'Amharic', week: 20, dueDate: '2025-10-15', status: 'Inactive', registered: '2025-04-20' },
    { id: 'M005', name: 'Dinkinesh Haile', phone: '+251955678901', email: 'dinki@example.com', language: 'Afan Oromo', week: 8, dueDate: '2025-12-01', status: 'Active', registered: '2025-04-18' },
    { id: 'M006', name: 'Mekdes Worku', phone: '+251966789012', email: 'mekdes@example.com', language: 'Amharic', week: 36, dueDate: '2025-07-05', status: 'Active', registered: '2025-04-10' },
    { id: 'M007', name: 'Hawi Gudeta', phone: '+251977890123', email: 'hawi@example.com', language: 'Afan Oromo', week: 12, dueDate: '2025-11-22', status: 'Active', registered: '2025-04-05' },
    { id: 'M008', name: 'Abebe Regassa', phone: '+251988901234', email: 'abebe@example.com', language: 'Afan Oromo', week: 28, dueDate: '2025-09-30', status: 'Active', registered: '2025-03-20' },
];

// ─── Health Providers ─────────────────────────────────────────────────
export const mockProviders: HealthProvider[] = [
    { id: 'P001', name: 'Black Lion Hospital', address: 'Siddist Kilo, Addis Ababa', city: 'Addis Ababa', region: 'Addis Ababa', phone: '+251111234567', email: 'info@blacklion.et', serviceDescription: 'Full obstetric and gynecological services', status: 'Active', linkedDoctorCount: 3, linkedDoctors: ['D001', 'D002', 'D003'], createdAt: '2024-01-15' },
    { id: 'P002', name: 'St. Paul Hospital', address: 'Gulele, Addis Ababa', city: 'Addis Ababa', region: 'Addis Ababa', phone: '+251112345678', email: 'info@stpaul.et', serviceDescription: 'Maternity and pediatric care', status: 'Active', linkedDoctorCount: 2, linkedDoctors: ['D004', 'D005'], createdAt: '2024-02-10' },
    { id: 'P003', name: 'Jugel Hospital', address: 'Harar City', city: 'Harar', region: 'Harari', phone: '+251253456789', email: 'info@jugel.et', serviceDescription: 'General maternal health and emergency obstetrics', status: 'Active', linkedDoctorCount: 1, linkedDoctors: ['D006'], createdAt: '2024-03-05' },
    { id: 'P004', name: 'Dire Dawa Referral Hospital', address: 'Dire Dawa City', city: 'Dire Dawa', region: 'Dire Dawa', phone: '+251254567890', email: 'info@ddh.et', serviceDescription: 'Prenatal and postnatal care', status: 'Inactive', linkedDoctorCount: 0, linkedDoctors: [], createdAt: '2024-04-12' },
];

// ─── Doctors ──────────────────────────────────────────────────────────
export const mockDoctors: Doctor[] = [
    { id: 'D001', name: 'Dr. Abebe Girma', email: 'abebe.girma@blacklion.et', phone: '+251910111213', specialization: 'Obstetrics & Gynecology', licenseNumber: 'ETH-OB-1203', providerId: 'P001', providerName: 'Black Lion Hospital', yearsExperience: 12, submittedDate: '2025-05-10', approvalStatus: 'Pending', status: 'Inactive', credentialImageUrl: undefined, bio: 'Senior OB/GYN with 12 years in maternal care at Black Lion Hospital.' },
    { id: 'D002', name: 'Dr. Marta Yohannes', email: 'marta.y@blacklion.et', phone: '+251920212223', specialization: 'Maternal-Fetal Medicine', licenseNumber: 'ETH-MF-0847', providerId: 'P001', providerName: 'Black Lion Hospital', yearsExperience: 8, submittedDate: '2025-05-08', approvalStatus: 'Pending', status: 'Inactive', credentialImageUrl: undefined, bio: 'Specialist in high-risk pregnancies and fetal wellbeing monitoring.' },
    { id: 'D003', name: 'Dr. Samuel Tesfaye', email: 'samuel.t@stpaul.et', phone: '+251930313233', specialization: 'General Practice - Prenatal', licenseNumber: 'ETH-GP-2211', providerId: 'P002', providerName: 'St. Paul Hospital', yearsExperience: 5, submittedDate: '2025-05-12', approvalStatus: 'Pending', status: 'Inactive', credentialImageUrl: undefined, bio: 'GP focused on routine prenatal checkups and community maternal health.' },
    { id: 'D004', name: 'Dr. Liya Bekele', email: 'liya.b@stpaul.et', phone: '+251940414243', specialization: 'Pediatrics & Neonatology', licenseNumber: 'ETH-PD-1105', providerId: 'P002', providerName: 'St. Paul Hospital', yearsExperience: 9, submittedDate: '2025-04-20', approvalStatus: 'Approved', status: 'Active', credentialImageUrl: undefined, bio: 'Neonatologist with expertise in newborn ICU care.' },
    { id: 'D005', name: 'Dr. Henok Alemu', email: 'henok.a@jugel.et', phone: '+251950515253', specialization: 'Obstetrics & Gynecology', licenseNumber: 'ETH-OB-3321', providerId: 'P003', providerName: 'Jugel Hospital', yearsExperience: 15, submittedDate: '2025-04-15', approvalStatus: 'Approved', status: 'Active', credentialImageUrl: undefined, bio: 'Head of Obstetrics at Jugel Hospital, Harar.' },
    { id: 'D006', name: 'Dr. Feven Hailu', email: 'feven.h@ddh.et', phone: '+251960616263', specialization: 'Midwifery & Obstetrics', licenseNumber: 'ETH-MW-0092', providerId: 'P004', providerName: 'Dire Dawa Referral Hospital', yearsExperience: 6, submittedDate: '2025-03-28', approvalStatus: 'Rejected', status: 'Inactive', rejectionReason: 'License number could not be verified with Ethiopian Medical Council.', credentialImageUrl: undefined, bio: 'Midwife-trained obstetrician with rural health experience.' },
];

// ─── Announcements ────────────────────────────────────────────────────
export const mockAnnouncements: Announcement[] = [
    { id: 'AN001', title: 'New Nutrition Guidelines Published', message: 'We have published updated nutrition guidelines for the second trimester. All mothers are encouraged to review the Nutrition Guide section.', audience: 'Mothers', sentAt: '2025-05-15T09:00:00Z', status: 'Sent', reachCount: 842, readCount: 631, createdBy: 'Yohannes Tesfaye' },
    { id: 'AN002', title: 'Platform Maintenance Window', message: 'The Mom Care platform will undergo scheduled maintenance on May 20, 2025 from 2:00 AM to 4:00 AM EAT. Thank you for your understanding.', audience: 'All', sentAt: '2025-05-14T08:00:00Z', status: 'Sent', reachCount: 1284, readCount: 978, createdBy: 'Yohannes Tesfaye' },
    { id: 'AN003', title: 'Doctor Profile Review Reminder', message: 'Please ensure your submitted credentials are complete and up to date. Pending reviews will be processed within 48 hours.', audience: 'Doctors', sentAt: '2025-05-10T10:00:00Z', status: 'Sent', reachCount: 6, readCount: 4, createdBy: 'Yohannes Tesfaye' },
    { id: 'AN004', title: 'Eid Feature: Special Wellness Content', message: 'Special wellness tips for Eid season have been added to the Content Library. Stay healthy and blessed!', audience: 'All', scheduledAt: '2025-06-01T06:00:00Z', status: 'Scheduled', reachCount: 0, readCount: 0, createdBy: 'Yohannes Tesfaye' },
];

// ─── Audit Log ────────────────────────────────────────────────────────
export const mockAuditLog: AuditEntry[] = [
    { id: 'AL001', timestamp: '2025-05-15T09:01:12Z', adminUser: 'Yohannes Tesfaye', actionType: 'Announcement Sent', targetEntity: 'Announcement AN001', beforeSummary: undefined, afterSummary: 'Status → Sent', details: 'Broadcast "New Nutrition Guidelines Published" sent to 842 mothers.' },
    { id: 'AL002', timestamp: '2025-05-14T14:22:05Z', adminUser: 'Yohannes Tesfaye', actionType: 'Approval', targetEntity: 'Doctor D004 (Dr. Liya Bekele)', beforeSummary: 'Status: Pending', afterSummary: 'Status: Approved', details: 'Doctor registration approved. Email notification sent.' },
    { id: 'AL003', timestamp: '2025-05-13T11:45:33Z', adminUser: 'Yohannes Tesfaye', actionType: 'Approval', targetEntity: 'Doctor D005 (Dr. Henok Alemu)', beforeSummary: 'Status: Pending', afterSummary: 'Status: Approved', details: 'Doctor registration approved. Email notification sent.' },
    { id: 'AL004', timestamp: '2025-05-12T10:10:00Z', adminUser: 'Yohannes Tesfaye', actionType: 'Approval', targetEntity: 'Doctor D006 (Dr. Feven Hailu)', beforeSummary: 'Status: Pending', afterSummary: 'Status: Rejected', details: 'Doctor rejected. Reason: License number could not be verified.' },
    { id: 'AL005', timestamp: '2025-05-11T16:30:00Z', adminUser: 'Yohannes Tesfaye', actionType: 'Suspension', targetEntity: 'Mother M003 (Selam Bekele)', beforeSummary: 'Status: Active', afterSummary: 'Status: Suspended', details: 'Account suspended due to reported community misconduct.' },
    { id: 'AL006', timestamp: '2025-05-09T08:55:00Z', adminUser: 'Yohannes Tesfaye', actionType: 'Content Update', targetEntity: 'Nutrition Entry #34', beforeSummary: 'Title: Iron Foods (v1)', afterSummary: 'Title: Iron-Rich Foods for Pregnancy (v2)', details: 'Updated content title and added trimester T2 tag.' },
    { id: 'AL007', timestamp: '2025-05-08T13:20:00Z', adminUser: 'Yohannes Tesfaye', actionType: 'Provider Update', targetEntity: 'Provider P004 (Dire Dawa Referral Hospital)', beforeSummary: 'Status: Active', afterSummary: 'Status: Inactive', details: 'Provider deactivated pending facility inspection.' },
    { id: 'AL008', timestamp: '2025-05-07T09:00:00Z', adminUser: 'Yohannes Tesfaye', actionType: 'Login', targetEntity: 'Admin Panel', details: 'Admin login from IP 10.0.0.1.' },
    { id: 'AL009', timestamp: '2025-05-06T14:10:00Z', adminUser: 'Yohannes Tesfaye', actionType: 'Content Delete', targetEntity: 'Audio Entry #12', beforeSummary: 'Title: Morning Meditation Pt.1', afterSummary: undefined, details: 'Deleted outdated audio entry.' },
    { id: 'AL010', timestamp: '2025-05-05T11:00:00Z', adminUser: 'Yohannes Tesfaye', actionType: 'Account Change', targetEntity: 'Mother M004 (Hirut Tadesse)', beforeSummary: 'Status: Active', afterSummary: 'Status: Inactive', details: 'Account marked inactive by user request.' },
];

// ─── Community Posts ───────────────────────────────────────────────────
export const mockPosts: Post[] = [
    { id: 'POST001', author: 'Tigist A.', content: 'Is it normal to feel dizzy in the third trimester? I\'ve been feeling lightheaded after standing up.', trimesterGroup: 'T3', postedAt: '2025-05-14T10:30:00Z', reportReason: 'Seeking medical advice — could mislead others', isFlagged: true, reportCount: 3 },
    { id: 'POST002', author: 'Chaltu G.', content: 'Sharing a home remedy my grandmother gave me to reduce morning sickness 🌿🍋', trimesterGroup: 'T1', postedAt: '2025-05-13T08:20:00Z', reportReason: 'Potentially harmful unverified medical advice', isFlagged: true, reportCount: 5 },
    { id: 'POST003', author: 'Hawi G.', content: 'Just had my 12-week scan — the baby is perfectly healthy! 🎉 So relieved.', trimesterGroup: 'T1', postedAt: '2025-05-15T14:00:00Z', isFlagged: false, reportCount: 0 },
    { id: 'POST004', author: 'Dinkinesh H.', content: 'What exercises are safe at 8 weeks? I want to stay active.', trimesterGroup: 'T1', postedAt: '2025-05-12T11:00:00Z', isFlagged: false, reportCount: 0 },
    { id: 'POST005', author: 'Mekdes W.', content: 'Baby shower tips for Ethiopian families? I want to plan something special!', trimesterGroup: 'T3', postedAt: '2025-05-11T09:30:00Z', isFlagged: false, reportCount: 0 },
    { id: 'POST006', author: 'Unknown User', content: 'Contact me for special pregnancy supplements — guaranteed results!', trimesterGroup: 'General', postedAt: '2025-05-14T15:00:00Z', reportReason: 'Spam / advertisement / scam', isFlagged: true, reportCount: 8 },
    { id: 'POST007', author: 'Selam B.', content: 'Week 30 update: back pain is becoming unbearable. Any tips?', trimesterGroup: 'T3', postedAt: '2025-05-10T16:45:00Z', isFlagged: false, reportCount: 0 },
    { id: 'POST008', author: 'Abebe R.', content: 'My wife is 28 weeks pregnant, and we are considering a home birth. Any experience?', trimesterGroup: 'T3', postedAt: '2025-05-09T13:00:00Z', isFlagged: false, reportCount: 1 },
];
