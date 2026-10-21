import { useState, useCallback, useEffect } from 'react';
import { adminCommunityApi } from '../../services/api';
import type { Post, TrimesterGroup } from '../types';

export function useCommunity(trimesterFilter?: TrimesterGroup | 'All', flaggedOnly?: boolean) {
    const [posts, setPosts] = useState<Post[]>([]);
    const [flaggedCount, setFlaggedCount] = useState<number>(0);
    const [isLoading, setIsLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

    const fetchPosts = useCallback(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const data = await adminCommunityApi.getPosts({
                trimester: trimesterFilter === 'All' ? undefined : trimesterFilter,
                flaggedOnly: flaggedOnly,
                limit: 100,
            });
            setPosts(data.items || []);

            // Also check flagged count for the badge
            if (flaggedOnly) {
                setFlaggedCount((data.items || []).length);
            } else {
                const flagged = await adminCommunityApi.getPosts({ flaggedOnly: true, limit: 100 });
                setFlaggedCount((flagged.items || []).length);
            }
        } catch (err: any) {
            console.error('Error loading community posts:', err);
            setError(err.message || 'Failed to load community posts');
        } finally {
            setIsLoading(false);
        }
    }, [trimesterFilter, flaggedOnly]);

    useEffect(() => {
        fetchPosts();
    }, [fetchPosts]);

    const deletePost = useCallback(async (id: string) => {
        try {
            await adminCommunityApi.deletePost(id);
            setPosts(prev => prev.filter(p => p.id !== id));
            setFlaggedCount(prev => Math.max(0, prev - 1));
        } catch (err: any) {
            console.error('Error deleting post:', err);
            throw err;
        }
    }, []);

    const dismissFlag = useCallback(async (id: string) => {
        try {
            await adminCommunityApi.dismissFlag(id);
            setPosts(prev =>
                prev
                    .map(p => p.id === id ? { ...p, isFlagged: false, reportCount: 0, reportReason: undefined } : p)
                    .filter(p => flaggedOnly ? p.id !== id : true)
            );
            setFlaggedCount(prev => Math.max(0, prev - 1));
        } catch (err: any) {
            console.error('Error dismissing flag:', err);
            throw err;
        }
    }, [flaggedOnly]);

    return { posts, isLoading, error, deletePost, dismissFlag, flaggedCount, refresh: fetchPosts };
}
