import { useState } from 'react';
import { AlertTriangle, Trash2, CheckCircle, MessageSquare, BookOpen, Filter, Search } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { useCommunity } from '../api/hooks/useCommunity';
import type { TrimesterGroup } from '../api/types';

const subTabs = ['Flagged Posts', 'Post Browser', 'Community Rules'] as const;
type SubTab = typeof subTabs[number];

const trimesterOpts: (TrimesterGroup | 'All')[] = ['All', 'T1', 'T2', 'T3', 'General'];

const trimesterLabel: Record<TrimesterGroup | 'All', string> = {
    All: 'All Groups',
    T1: '1st Trimester',
    T2: '2nd Trimester',
    T3: '3rd Trimester',
    General: 'General',
};

const DEFAULT_RULES = `Community Guidelines for Mom Care

1. Be kind and respectful to all community members.
2. Do not share unverified medical advice or remedies.
3. Respect privacy — do not share personal health information publicly.
4. Spam, advertisements, or promotional content are strictly prohibited.
5. Posts flagged by multiple users will be reviewed by an admin.
6. Community support is not a substitute for professional medical care.
7. Always consult a licensed doctor for any health concerns.`;

export default function CommunityModeration() {
    const [activeTab, setActiveTab] = useState<SubTab>('Flagged Posts');
    const [trimesterFilter, setTrimesterFilter] = useState<TrimesterGroup | 'All'>('All');
    const [search, setSearch] = useState('');
    const [rules, setRules] = useState(DEFAULT_RULES);
    const [rulesSaved, setRulesSaved] = useState(false);

    const flaggedPosts = useCommunity(undefined, true);
    const allPosts = useCommunity(trimesterFilter === 'All' ? undefined : trimesterFilter, false);

    const filteredAllPosts = allPosts.posts.filter(p =>
        p.content.toLowerCase().includes(search.toLowerCase()) ||
        p.author.toLowerCase().includes(search.toLowerCase())
    );

    const handleSaveRules = async () => {
        await new Promise(r => setTimeout(r, 500));
        setRulesSaved(true);
        setTimeout(() => setRulesSaved(false), 2500);
    };

    const formatDate = (iso: string) =>
        new Date(iso).toLocaleDateString('en-US', { dateStyle: 'medium' });

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Community Moderation</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage posts, flagged content, and community guidelines</p>
                </div>
                {flaggedPosts.flaggedCount > 0 && (
                    <div className="flex items-center gap-2 text-sm font-medium text-amber-700 bg-amber-50 border border-amber-200 px-4 py-2 rounded-xl">
                        <AlertTriangle className="w-4 h-4" />
                        {flaggedPosts.flaggedCount} flagged post{flaggedPosts.flaggedCount > 1 ? 's' : ''} need review
                    </div>
                )}
            </div>

            {/* Sub-tabs */}
            <div className="flex gap-1 bg-gray-100 p-1 rounded-xl w-fit">
                {subTabs.map(tab => (
                    <button
                        key={tab}
                        onClick={() => setActiveTab(tab)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${activeTab === tab ? 'bg-white text-[#61183e] shadow-sm' : 'text-gray-500 hover:text-gray-700'
                            }`}
                    >
                        {tab === 'Flagged Posts' && <AlertTriangle className="w-3.5 h-3.5" />}
                        {tab === 'Post Browser' && <MessageSquare className="w-3.5 h-3.5" />}
                        {tab === 'Community Rules' && <BookOpen className="w-3.5 h-3.5" />}
                        {tab}
                        {tab === 'Flagged Posts' && flaggedPosts.flaggedCount > 0 && (
                            <span className="ml-1 bg-red-500 text-white text-xs rounded-full px-1.5 py-0.5 min-w-[18px] text-center">
                                {flaggedPosts.flaggedCount}
                            </span>
                        )}
                    </button>
                ))}
            </div>

            {/* Flagged Posts Tab */}
            {activeTab === 'Flagged Posts' && (
                <div className="space-y-4">
                    {flaggedPosts.posts.length === 0 ? (
                        <Card>
                            <div className="flex flex-col items-center justify-center py-12 text-gray-400 gap-3">
                                <CheckCircle className="w-12 h-12 text-green-200" />
                                <p className="font-medium">No flagged posts — queue is clear! ✓</p>
                            </div>
                        </Card>
                    ) : flaggedPosts.posts.map(post => (
                        <Card key={post.id}>
                            <div className="flex items-start justify-between gap-4">
                                <div className="flex-1">
                                    <div className="flex items-center gap-2 mb-2">
                                        <div className="w-7 h-7 rounded-full bg-red-100 text-red-500 text-xs font-bold flex items-center justify-center">
                                            {post.author[0]}
                                        </div>
                                        <span className="font-medium text-sm text-gray-800">{post.author}</span>
                                        <Badge variant="gray">{trimesterLabel[post.trimesterGroup]}</Badge>
                                        <span className="text-xs text-gray-400 ml-auto">{formatDate(post.postedAt)}</span>
                                    </div>
                                    <p className="text-sm text-gray-700 bg-gray-50 rounded-xl p-3 mb-3 leading-relaxed">"{post.content}"</p>
                                    {post.reportReason && (
                                        <div className="flex items-start gap-2 text-xs text-amber-700 bg-amber-50 border border-amber-100 rounded-lg px-3 py-2">
                                            <AlertTriangle className="w-3.5 h-3.5 mt-0.5 shrink-0" />
                                            <span><strong>Report reason:</strong> {post.reportReason}</span>
                                        </div>
                                    )}
                                    <p className="text-xs text-gray-400 mt-2">{post.reportCount} user report{post.reportCount > 1 ? 's' : ''}</p>
                                </div>
                                <div className="flex flex-col gap-2 shrink-0">
                                    <Button
                                        variant="danger"
                                        size="sm"
                                        icon={<Trash2 className="w-3.5 h-3.5" />}
                                        onClick={() => flaggedPosts.deletePost(post.id)}
                                    >
                                        Delete
                                    </Button>
                                    <Button
                                        variant="secondary"
                                        size="sm"
                                        icon={<CheckCircle className="w-3.5 h-3.5" />}
                                        onClick={() => flaggedPosts.dismissFlag(post.id)}
                                    >
                                        Dismiss
                                    </Button>
                                </div>
                            </div>
                        </Card>
                    ))}
                </div>
            )}

            {/* Post Browser Tab */}
            {activeTab === 'Post Browser' && (
                <Card>
                    <div className="flex flex-wrap gap-3 mb-5">
                        <div className="relative flex-1 min-w-[200px]">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                            <input
                                className="w-full pl-10 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white"
                                placeholder="Search posts or authors..."
                                value={search}
                                onChange={e => setSearch(e.target.value)}
                            />
                        </div>
                        <div className="flex items-center gap-2">
                            <Filter className="w-4 h-4 text-gray-400" />
                            <div className="flex bg-gray-100 p-1 rounded-lg gap-1">
                                {trimesterOpts.map(opt => (
                                    <button
                                        key={opt}
                                        onClick={() => setTrimesterFilter(opt)}
                                        className={`px-3 py-1 rounded text-xs font-medium transition-all ${trimesterFilter === opt ? 'bg-white text-[#61183e] shadow-sm' : 'text-gray-500 hover:text-gray-700'
                                            }`}
                                    >
                                        {opt === 'All' ? 'All' : trimesterLabel[opt]}
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>
                    <div className="space-y-3">
                        {filteredAllPosts.length === 0 ? (
                            <p className="text-center text-gray-400 py-8">No posts found.</p>
                        ) : filteredAllPosts.map(post => (
                            <div key={post.id} className="flex items-start gap-3 p-4 border border-gray-100 rounded-xl hover:border-[#fdf2f8] transition-colors">
                                <div className="w-8 h-8 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center shrink-0">
                                    {post.author[0]}
                                </div>
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2 mb-1">
                                        <span className="font-medium text-sm text-gray-800">{post.author}</span>
                                        <Badge variant="gray">{trimesterLabel[post.trimesterGroup]}</Badge>
                                        {post.isFlagged && <Badge variant="red">Flagged</Badge>}
                                        <span className="text-xs text-gray-400 ml-auto">{formatDate(post.postedAt)}</span>
                                    </div>
                                    <p className="text-sm text-gray-600 leading-relaxed">{post.content}</p>
                                </div>
                                <button
                                    onClick={() => allPosts.deletePost(post.id)}
                                    className="p-1.5 rounded-lg hover:bg-red-50 text-red-400 hover:text-red-600 transition-colors shrink-0"
                                    title="Delete post"
                                >
                                    <Trash2 className="w-4 h-4" />
                                </button>
                            </div>
                        ))}
                    </div>
                </Card>
            )}

            {/* Community Rules Tab */}
            {activeTab === 'Community Rules' && (
                <Card>
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="font-semibold text-gray-800 flex items-center gap-2">
                            <BookOpen className="w-4 h-4 text-[#61183e]" />
                            Community Rules Editor
                        </h3>
                        {rulesSaved && (
                            <span className="text-xs text-green-600 flex items-center gap-1">
                                <CheckCircle className="w-3.5 h-3.5" /> Saved
                            </span>
                        )}
                    </div>
                    <textarea
                        rows={16}
                        value={rules}
                        onChange={e => setRules(e.target.value)}
                        className="w-full px-4 py-3 border border-gray-200 rounded-xl text-sm font-mono leading-relaxed focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 resize-none"
                    />
                    <div className="mt-4">
                        <Button variant="primary" size="sm" onClick={handleSaveRules}>Save Rules</Button>
                    </div>
                </Card>
            )}
        </div>
    );
}
