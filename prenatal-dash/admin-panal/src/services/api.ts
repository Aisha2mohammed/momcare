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
 * Module-to-endpoint map:
 * Translates logical module names used by admin panel manager pages
 * into their actual backend REST path segments (relative to API_BASE_URL).
 *
 * This replaces the deleted /admin/cms/ proxy router — each module now
 * directly calls the real controller endpoints.
 */
const MODULE_ENDPOINT_MAP: Record<string, string> = {
  // Exercise
  'exercise-weeks': '/exercise/weeks',   // ExerciseManager (exercise_weeks table)
  'exercise-tips':  '/exercise/tips',    // AddExercisePage (exercises table)
  'exercises':      '/exercise/tips',    // legacy alias → exercise tips content

  // Nutrition
  'nutrition-weeks': '/nutrition/weeks', // NutritionManager (nutrition_weeks table)
  'nutrition-tips':  '/nutrition/tips',  // AddNutritionPage (nutrition_tips table)
  'nutrition':       '/nutrition/tips',  // legacy alias → nutrition tips content

  // Sleep
  'sleep-weeks': '/sleep/weeks',         // SleepPositionManager (sleep_weeks table)
  'sleep-tips':  '/sleep/tips',          // AddSleepPage (sleep_tips table)
  'sleep':       '/sleep/tips',          // legacy alias → sleep tips content

  // Music
  'music': '/music',                     // MusicLibraryManager (music_tracks table)

  // Fetal Development
  'fetal': '/fetal',                     // FetalDevelopmentManager (fetal_weekly_content table)
};

/**
 * Resolve the actual REST path for a given module name.
 * Falls back to /admin/cms/{module} for any unknown modules (legacy behaviour).
 */
function resolveModulePath(module: string): string {
  return MODULE_ENDPOINT_MAP[module] ?? `/admin/cms/${module}`;
}

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
  type?: string;
  week?: string | number;
  month?: string | number;
  isPublished?: boolean;
  published?: boolean;
  isActive?: boolean;
  active?: boolean;
}

// ─── Generic CMS Client ───────────────────────────────────────────────────
export const cmsClient = {
  /**
   * List items with pagination, search, and trimester/category/week/month/type filter.
   * Module names are resolved through MODULE_ENDPOINT_MAP to the actual backend paths.
   */
  async list<T = any>(module: string, params: CmsListParams = {}) {
    const query = new URLSearchParams();
    if (params.page) query.set('page', String(params.page));
    if (params.limit) query.set('limit', String(params.limit));
    if (params.search || params.q) query.set('search', params.search || params.q || '');
    if (params.trimester !== undefined && params.trimester !== '') query.set('trimester', String(params.trimester));
    if (params.category && params.category !== 'All') query.set('category', params.category);
    if (params.type && params.type !== 'All') query.set('type', params.type);
    if (params.week !== undefined && params.week !== '' && params.week !== 'All') query.set('week', String(params.week));
    if (params.month !== undefined && params.month !== '' && params.month !== 'All') query.set('month', String(params.month));
    if (params.isPublished !== undefined) query.set('isPublished', String(params.isPublished));
    if (params.published !== undefined) query.set('isPublished', String(params.published));
    if (params.isActive !== undefined) query.set('isActive', String(params.isActive));
    if (params.active !== undefined) query.set('isActive', String(params.active));
    // Pass includeInactive for admin fetal view so all records are returned
    if (module === 'fetal') query.set('includeInactive', 'true');

    const qs = query.toString();
    const basePath = resolveModulePath(module);
    const endpoint = `${basePath}${qs ? `?${qs}` : ''}`;
    const res = await apiRequest<T[]>(endpoint, { method: 'GET' });
    return {
      items: (res.data || []) as T[],
      pagination: res.pagination || { total: (res.data || []).length, page: 1, limit: 20 },
    };
  },

  /**
   * Get single item detail by ID.
   * Module names are resolved through MODULE_ENDPOINT_MAP to the actual backend paths.
   */
  async get<T = any>(module: string, id: string | number) {
    const basePath = resolveModulePath(module);
    const res = await apiRequest<T>(`${basePath}/${id}`, { method: 'GET' });
    return res.data as T;
  },

  /**
   * Create new item with payload.
   * Module names are resolved through MODULE_ENDPOINT_MAP to the actual backend paths.
   */
  async create<T = any>(module: string, payload: any) {
    const basePath = resolveModulePath(module);
    const res = await apiRequest<T>(basePath, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    return res.data as T;
  },

  /**
   * Update item by ID.
   * Module names are resolved through MODULE_ENDPOINT_MAP to the actual backend paths.
   */
  async update<T = any>(module: string, id: string | number, payload: any) {
    const basePath = resolveModulePath(module);
    const res = await apiRequest<T>(`${basePath}/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
    return res.data as T;
  },

  /**
   * Delete item by ID.
   * Module names are resolved through MODULE_ENDPOINT_MAP to the actual backend paths.
   */
  async delete(module: string, id: string | number) {
    const basePath = resolveModulePath(module);
    const res = await apiRequest(`${basePath}/${id}`, { method: 'DELETE' });
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

  /**
   * Upload media file (Image, Video, Audio, or PDF document)
   */
  async upload(file: File): Promise<{ url: string; relativeUrl: string; filename: string; size: number; mimetype: string }> {
    const formData = new FormData();
    formData.append('file', file);
    const token = getAuthToken();

    const headers: Record<string, string> = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const res = await fetch(`${API_BASE_URL}/admin/cms/upload`, {
      method: 'POST',
      headers,
      body: formData,
    });

    const json = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new Error(json?.error?.message || json?.message || `Upload failed with HTTP ${res.status}`);
    }
    return json.data;
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
