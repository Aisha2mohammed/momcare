import { useState } from 'react';
import { Send, Calendar, Users, Clock, CheckCircle, Badge as BadgeIcon, Eye } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { useAnnouncements } from '../api/hooks/useAnnouncements';
import type { AnnouncementAudience } from '../api/types';

const audienceOptions = [
    { value: 'All', label: 'All Users', icon: '👥', desc: '~1,284 recipients' },
    { value: 'Mothers', label: 'Mothers Only', icon: '🤱', desc: '~1,272 recipients' },
    { value: 'Doctors', label: 'Doctors Only', icon: '👨‍⚕️', desc: '~12 recipients' },
];

export default function Announcements() {
    const { announcements, send } = useAnnouncements();
    const [audience, setAudience] = useState<AnnouncementAudience>('All');
    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');
    const [scheduledAt, setScheduledAt] = useState('');
    const [sending, setSending] = useState(false);
    const [sent, setSent] = useState(false);

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!title.trim() || !message.trim()) return;
        setSending(true);
        await send({ title, message, audience, scheduledAt: scheduledAt || undefined });
        setSending(false);
        setSent(true);
        setTitle('');
        setMessage('');
        setScheduledAt('');
        setTimeout(() => setSent(false), 3000);
    };

    const statusVariant = (s: string) => s === 'Sent' ? 'green' : s === 'Scheduled' ? 'blue' : 'gray';

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-2xl font-bold text-[#61183e]">Announcements</h2>
                <p className="text-gray-500 text-sm mt-0.5">Broadcast messages to platform users</p>
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
                {/* Composer */}
                <Card>
                    <h3 className="font-semibold text-gray-800 mb-5 flex items-center gap-2">
                        <Send className="w-4 h-4 text-[#61183e]" />
                        Broadcast Composer
                    </h3>

                    {sent && (
                        <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-xl flex items-center gap-2 text-green-700 text-sm">
                            <CheckCircle className="w-4 h-4" /> Announcement sent successfully!
                        </div>
                    )}

                    <form onSubmit={handleSend} className="space-y-4">
                        {/* Audience */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Audience</label>
                            <div className="grid grid-cols-3 gap-2">
                                {audienceOptions.map(opt => (
                                    <button
                                        key={opt.value}
                                        type="button"
                                        onClick={() => setAudience(opt.value as AnnouncementAudience)}
                                        className={`flex flex-col items-center p-3 rounded-xl border-2 transition-all text-center ${audience === opt.value
                                                ? 'border-[#61183e] bg-[#fdf2f8]'
                                                : 'border-gray-200 hover:border-gray-300'
                                            }`}
                                    >
                                        <span className="text-2xl mb-1">{opt.icon}</span>
                                        <span className="text-xs font-semibold text-gray-800">{opt.label}</span>
                                        <span className="text-xs text-gray-400 mt-0.5">{opt.desc}</span>
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* Title */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1.5">Title</label>
                            <input
                                type="text"
                                required
                                value={title}
                                onChange={e => setTitle(e.target.value)}
                                placeholder="Announcement title..."
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20"
                            />
                        </div>

                        {/* Message */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1.5">Message</label>
                            <textarea
                                required
                                rows={5}
                                value={message}
                                onChange={e => setMessage(e.target.value)}
                                placeholder="Write your message here..."
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 resize-none"
                            />
                            <p className="text-xs text-gray-400 mt-1 text-right">{message.length} chars</p>
                        </div>

                        {/* Schedule */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1.5 flex items-center gap-1.5">
                                <Calendar className="w-3.5 h-3.5" />
                                Schedule (optional)
                            </label>
                            <input
                                type="datetime-local"
                                value={scheduledAt}
                                onChange={e => setScheduledAt(e.target.value)}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20"
                            />
                            <p className="text-xs text-gray-400 mt-1">Leave empty to send immediately.</p>
                        </div>

                        <Button
                            type="submit"
                            variant="primary"
                            size="sm"
                            className="w-full"
                            icon={scheduledAt ? <Clock className="w-4 h-4" /> : <Send className="w-4 h-4" />}
                            disabled={sending || !title.trim() || !message.trim()}
                        >
                            {sending ? 'Sending...' : scheduledAt ? 'Schedule Announcement' : 'Send Now'}
                        </Button>
                    </form>
                </Card>

                {/* History */}
                <Card>
                    <h3 className="font-semibold text-gray-800 mb-5 flex items-center gap-2">
                        <BadgeIcon className="w-4 h-4 text-[#61183e]" />
                        Announcement History
                    </h3>
                    <div className="space-y-3 max-h-[560px] overflow-y-auto pr-1">
                        {announcements.length === 0 ? (
                            <p className="text-center text-gray-400 py-8">No announcements sent yet.</p>
                        ) : (
                            announcements.map(a => (
                                <div key={a.id} className="border border-gray-100 rounded-xl p-4 hover:border-[#fdf2f8] transition-colors">
                                    <div className="flex items-start justify-between gap-2 mb-2">
                                        <p className="font-semibold text-gray-800 text-sm">{a.title}</p>
                                        <Badge variant={statusVariant(a.status) as 'green' | 'blue' | 'gray'}>{a.status}</Badge>
                                    </div>
                                    <p className="text-xs text-gray-500 line-clamp-2 mb-3">{a.message}</p>
                                    <div className="flex items-center gap-4 text-xs text-gray-400">
                                        <span className="flex items-center gap-1">
                                            <Users className="w-3 h-3" />
                                            {a.audience}
                                        </span>
                                        {a.sentAt && (
                                            <span className="flex items-center gap-1">
                                                <Send className="w-3 h-3" />
                                                {new Date(a.sentAt).toLocaleDateString()}
                                            </span>
                                        )}
                                        {a.scheduledAt && (
                                            <span className="flex items-center gap-1">
                                                <Clock className="w-3 h-3" />
                                                {new Date(a.scheduledAt).toLocaleDateString()}
                                            </span>
                                        )}
                                    </div>
                                    {a.status === 'Sent' && (
                                        <div className="mt-3 flex gap-4 text-xs">
                                            <span className="flex items-center gap-1 text-blue-600">
                                                <Eye className="w-3 h-3" /> {a.reachCount} reached
                                            </span>
                                            <span className="flex items-center gap-1 text-green-600">
                                                <CheckCircle className="w-3 h-3" /> {a.readCount} read ({Math.round((a.readCount / Math.max(a.reachCount, 1)) * 100)}%)
                                            </span>
                                        </div>
                                    )}
                                </div>
                            ))
                        )}
                    </div>
                </Card>
            </div>
        </div>
    );
}
