/**
 * MaternaLink / MomCare Admin Panel - Centralized API Service Layer
 * Fully integrated with my-backend REST endpoints under /api/v1
 */

// Base URL resolution from environment variable
const getBaseUrl = (): string => {
  // Check Vite env
  if (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL.replace(/\/+$/, '');
  }
  // Check Create-React-App env
  const proc = (globalThis as any)?.process;
  if (proc && proc.env && proc.env.REACT_APP_API_URL) {
    return proc.env.REACT_APP_API_URL.replace(/\/+$/, '');
  }
  return 'http://localhost:5000/api/v1';
};

export const API_BASE_URL = getBaseUrl();
export const CMS_BASE_URL = `${API_BASE_URL}/admin/cms`;

/**
 * Retrieve current JWT auth token from session or local storage
 */
export const getAuthToken = (): string | null => {
  try {
    const sessionStr = sessionStorage.getItem('momcare_admin_session');
    if (sessionStr) {
      const parsed = JSON.parse(sessionStr);
      if (parsed?.token) return parsed.token;
    }
  } catch {
    // Ignore JSON parse errors
  }
  return localStorage.getItem('token') || sessionStorage.getItem('token') || null;
};

/**
 * HTTP Client with automatic Authorization Bearer JWT interceptor
 */
async function apiRequest<T = any>(
  endpoint: string,
  options: RequestInit = {}
): Promise<{ success: boolean; data?: T; pagination?: any; message?: string; error?: string }> {
  const url = endpoint.startsWith('http') ? endpoint : `${API_BASE_URL}${endpoint.startsWith('/') ? '' : '/'}${endpoint}`;
  const token = getAuthToken();

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    });

    // Handle 401 Unauthorized
    if (response.status === 401) {
      console.warn('[API] 401 Unauthorized - Session may have expired');
    }

    const json = await response.json().catch(() => ({}));

    if (!response.ok) {
      const errorMessage = json?.error?.message || json?.message || `HTTP Error ${response.status}: ${response.statusText}`;
      throw new Error(errorMessage);
    }

    return json;
  } catch (err: any) {
    console.error(`[API Error] ${options.method || 'GET'} ${url}:`, err.message);
    throw err;
  }
}

// ─── Module Query Params Interface ────────────────────────────────────────
export interface CmsListParams {
  page?: number;
  limit?: number;
  search?: string;
  q?: string;
  trimester?: string | number;
  category?: string;
  isPublished?: boolean;
  published?: boolean;
  isActive?: boolean;
  active?: boolean;
}

// ─── Generic CMS Client ───────────────────────────────────────────────────
export const cmsClient = {
  /**
   * List items with pagination, search, and trimester/category filter
   */
  async list<T = any>(module: string, params: CmsListParams = {}) {
    const query = new URLSearchParams();
    if (params.page) query.set('page', String(params.page));
    if (params.limit) query.set('limit', String(params.limit));
    if (params.search || params.q) query.set('search', params.search || params.q || '');
    if (params.trimester !== undefined && params.trimester !== '') query.set('trimester', String(params.trimester));
    if (params.category && params.category !== 'All') query.set('category', params.category);
    if (params.isPublished !== undefined) query.set('isPublished', String(params.isPublished));
    if (params.published !== undefined) query.set('isPublished', String(params.published));
    if (params.isActive !== undefined) query.set('isActive', String(params.isActive));
    if (params.active !== undefined) query.set('isActive', String(params.active));

    const qs = query.toString();
    const endpoint = `/admin/cms/${module}${qs ? `?${qs}` : ''}`;
    const res = await apiRequest<T[]>(endpoint, { method: 'GET' });
    return {
      items: (res.data || []) as T[],
      pagination: res.pagination || { total: (res.data || []).length, page: 1, limit: 20 },
    };
  },

  /**
   * Get single item detail by ID
   */
  async get<T = any>(module: string, id: string | number) {
    const res = await apiRequest<T>(`/admin/cms/${module}/${id}`, { method: 'GET' });
    return res.data as T;
  },

  /**
   * Create new item with payload
   */
  async create<T = any>(module: string, payload: any) {
    const res = await apiRequest<T>(`/admin/cms/${module}`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    return res.data as T;
  },

  /**
   * Update item by ID
   */
  async update<T = any>(module: string, id: string | number, payload: any) {
    const res = await apiRequest<T>(`/admin/cms/${module}/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
    return res.data as T;
  },

  /**
   * Delete item by ID
   */
  async delete(module: string, id: string | number) {
    const res = await apiRequest(`/admin/cms/${module}/${id}`, { method: 'DELETE' });
    return res;
  },

  /**
   * Toggle published visibility
   */
  async togglePublish(module: string, id: string | number, currentStatus: boolean) {
    return this.update(module, id, { isPublished: !currentStatus });
  },

  /**
   * Toggle active state
   */
  async toggleActive(module: string, id: string | number, currentStatus: boolean) {
    return this.update(module, id, { isActive: !currentStatus });
  },
};

// ─── Authentication API ───────────────────────────────────────────────────
export const authApi = {
  async adminLogin(email: string, password: string) {
    const res = await apiRequest<{ token: string; admin: any }>('/auth/admin/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    return res.data;
  },
};

export default cmsClient;
