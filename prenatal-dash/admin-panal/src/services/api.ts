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
 * Origin used to serve uploaded static files (e.g. /uploads/fetal/xyz.jpg).
 * Uploads are NOT served under /api/v1 — strip that suffix off API_BASE_URL
 * to get the plain backend origin (e.g. http://localhost:5000).
 */
export const MEDIA_ORIGIN = API_BASE_URL.replace(/\/api\/v\d+\/?$/, '');

/**
 * Turn a relative upload path (e.g. "/uploads/fetal/week19.jpg") into an
 * absolute URL usable directly in an <img src>. Leaves already-absolute
 * URLs (http:// or https://, e.g. externally hosted images) untouched.
 * Returns '' for empty/null input so callers can safely check truthiness.
 */
export function resolveMediaUrl(path?: string | null): string {
  if (!path) return '';
  if (/^https?:\/\//i.test(path)) return path;
  return `${MEDIA_ORIGIN}${path.startsWith('/') ? '' : '/'}${path}`;
}

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
 * LIST endpoint overrides (GET collection): raw, unlocalized rows with every
 * language field — used for the admin table view.
 *
 * fetal: GET /fetal (mother-facing) is localized down to ONE language and
 *        collapses e.g. title_en/title_am/... into a single "title" field.
 *        GET /fetal/admin/list is the raw admin listing (every *_en/*_am/
 *        *_om/*_so column). This is a DIFFERENT path from the single-record
 *        admin GET below — the two must stay as separate objects/values.
 */
const LIST_ENDPOINT_OVERRIDES: Record<string, string> = {
  'fetal': '/fetal/admin/list',
};

/**
 * GET-by-ID endpoint overrides (single record): includes joined child
 * tables (developments/checklist) for the admin edit form.
 *
 * fetal: GET /fetal/:week (mother-facing) expects a WEEK NUMBER (1–42),
 *        not a DB id, and filters is_active=true — wrong shape for admin
 *        editing. GET /fetal/admin/:id is the dedicated admin single-record
 *        route (raw columns + developments[] + checklist[]).
 */
const GET_ENDPOINT_OVERRIDES: Record<string, string> = {
  'fetal': '/fetal/admin',
};

/**
 * Resolve the actual REST path for a given module name.
 * Falls back to /admin/cms/{module} for any unknown modules (legacy behaviour).
 */
function resolveModulePath(module: string): string {
  return MODULE_ENDPOINT_MAP[module] ?? `/admin/cms/${module}`;
}

/**
 * Resolve the path used specifically for LIST (GET collection) requests.
 * Prefers a dedicated admin listing endpoint when one is registered,
 * otherwise falls back to the normal module path.
 */
function resolveListPath(module: string): string {
  return LIST_ENDPOINT_OVERRIDES[module] ?? resolveModulePath(module);
}

/**
 * Resolve the path used specifically for single-record GET-by-ID requests.
 * Prefers a dedicated admin detail endpoint when one is registered,
 * otherwise falls back to the normal module path.
 */
function resolveGetPath(module: string): string {
  return GET_ENDPOINT_OVERRIDES[module] ?? resolveModulePath(module);
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
  lang?: string;
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
   * Uses LIST_ENDPOINT_OVERRIDES when a module has a dedicated admin listing
   * endpoint (e.g. fetal → /fetal/admin/list), otherwise MODULE_ENDPOINT_MAP.
   */
  async list<T = any>(module: string, params: CmsListParams = {}) {
    const query = new URLSearchParams();
    if (params.page) query.set('page', String(params.page));
    if (params.limit) query.set('limit', String(params.limit));
    if (params.search || params.q) query.set('search', params.search || params.q || '');
    if (params.lang) query.set('lang', params.lang);
    if (params.trimester !== undefined && params.trimester !== '') query.set('trimester', String(params.trimester));
    if (params.category && params.category !== 'All') query.set('category', params.category);
    if (params.type && params.type !== 'All') query.set('type', params.type);
    if (params.week !== undefined && params.week !== '' && params.week !== 'All') query.set('week', String(params.week));
    if (params.month !== undefined && params.month !== '' && params.month !== 'All') query.set('month', String(params.month));
    if (params.isPublished !== undefined) query.set('isPublished', String(params.isPublished));
    if (params.published !== undefined) query.set('isPublished', String(params.published));
    if (params.isActive !== undefined) query.set('isActive', String(params.isActive));
    if (params.active !== undefined) query.set('isActive', String(params.active));
    // Admin fetal listing always wants inactive entries included too
    if (module === 'fetal') query.set('includeInactive', 'true');

    const qs = query.toString();
    const basePath = resolveListPath(module);
    const endpoint = `${basePath}${qs ? `?${qs}` : ''}`;
    const res = await apiRequest<T[]>(endpoint, { method: 'GET' });
    return {
      items: (res.data || []) as T[],
      pagination: res.pagination || { total: (res.data || []).length, page: 1, limit: 20 },
    };
  },

  /**
   * Get single item detail by ID.
   * Uses GET_ENDPOINT_OVERRIDES when a module has a dedicated admin detail
   * endpoint (e.g. fetal → /fetal/admin/:id), otherwise MODULE_ENDPOINT_MAP.
   */
  async get<T = any>(module: string, id: string | number) {
    const basePath = resolveGetPath(module);
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
   *
   * NOTE: this currently posts to `${API_BASE_URL}/admin/cms/upload`.
   * If your backend does not have that route mounted, this call will 404.
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