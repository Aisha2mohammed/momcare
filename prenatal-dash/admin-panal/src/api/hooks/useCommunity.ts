import { useState, useCallback } from 'react';
import { mockPosts } from '../mockData';
import type { Post, TrimesterGroup } from '../types';

let postsStore: Post[] = [...mockPosts];

export function useCommunity(trimesterFilter?: TrimesterGroup | 'All', flaggedOnly?: boolean) {
    const applyFilters = () => {
        let result = [...postsStore];
        if (flaggedOnly) result = result.filter(p => p.isFlagged);
        if (trimesterFilter && trimesterFilter !== 'All') result = result.filter(p => p.trimesterGroup === trimesterFilter);
        return result;
    };

    const [posts, setPosts] = useState<Post[]>(applyFilters());
    const [isLoading] = useState(false);
    const [error] = useState<string | null>(null);

    const refresh = useCallback(() => setPosts(applyFilters()), [trimesterFilter, flaggedOnly]);

    const deletePost = useCallback(async (id: string) => {
        await new Promise(r => setTimeout(r, 400));
        postsStore = postsStore.filter(p => p.id !== id);
        refresh();
    }, [refresh]);

    const dismissFlag = useCallback(async (id: string) => {
        await new Promise(r => setTimeout(r, 400));
        postsStore = postsStore.map(p => p.id === id ? { ...p, isFlagged: false, reportCount: 0, reportReason: undefined } : p);
        refresh();
    }, [refresh]);

    const flaggedCount = postsStore.filter(p => p.isFlagged).length;

    return { posts, isLoading, error, deletePost, dismissFlag, flaggedCount, refresh };
}
