import { useState, useCallback } from 'react';
import { mockAnnouncements } from '../mockData';
import type { Announcement, AnnouncementAudience } from '../types';

let announcementsStore: Announcement[] = [...mockAnnouncements];

export function useAnnouncements() {
    const [announcements, setAnnouncements] = useState<Announcement[]>([...announcementsStore]);
    const [isLoading] = useState(false);
    const [error] = useState<string | null>(null);

    const refresh = useCallback(() => setAnnouncements([...announcementsStore]), []);

    const send = useCallback(async (payload: {
        title: string;
        message: string;
        audience: AnnouncementAudience;
        scheduledAt?: string;
    }) => {
        await new Promise(r => setTimeout(r, 700));
        const isScheduled = !!payload.scheduledAt;
        const newAnnouncement: Announcement = {
            id: `AN${String(announcementsStore.length + 1).padStart(3, '0')}`,
            ...payload,
            status: isScheduled ? 'Scheduled' : 'Sent',
            sentAt: isScheduled ? undefined : new Date().toISOString(),
            reachCount: isScheduled ? 0 : Math.floor(Math.random() * 800 + 200),
            readCount: 0,
            createdBy: 'Yohannes Tesfaye',
        };
        announcementsStore = [newAnnouncement, ...announcementsStore];
        console.log(`[EMAIL STUB] Announcement "${payload.title}" sent to: ${payload.audience}`);
        refresh();
    }, [refresh]);

    return { announcements, isLoading, error, send, refresh };
}
