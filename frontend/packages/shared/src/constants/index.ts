/**
 * API endpoints
 */
export const API_ENDPOINTS = {
  // Auth
  AUTH: {
    LOGIN: '/api/v1/auth/login',
    REGISTER: '/api/v1/auth/register',
    LOGOUT: '/api/v1/auth/logout',
    REFRESH: '/api/v1/auth/refresh',
    ME: '/api/v1/auth/me',
  },
  // Articles
  ARTICLES: {
    LIST: '/api/v1/articles',
    GET: (id: string) => `/api/v1/articles/${id}`,
    CREATE: '/api/v1/articles',
    UPDATE: (id: string) => `/api/v1/articles/${id}`,
    DELETE: (id: string) => `/api/v1/articles/${id}`,
    ARCHIVE: (id: string) => `/api/v1/articles/${id}/archive`,
    FAVORITE: (id: string) => `/api/v1/articles/${id}/favorite`,
    SEARCH: '/api/v1/articles/search',
  },
  // Highlights
  HIGHLIGHTS: {
    LIST: '/api/v1/highlights',
    GET: (id: string) => `/api/v1/highlights/${id}`,
    CREATE: '/api/v1/highlights',
    UPDATE: (id: string) => `/api/v1/highlights/${id}`,
    DELETE: (id: string) => `/api/v1/highlights/${id}`,
    BY_ARTICLE: (articleId: string) => `/api/v1/articles/${articleId}/highlights`,
  },
  // Tags
  TAGS: {
    LIST: '/api/v1/tags',
    GET: (id: string) => `/api/v1/tags/${id}`,
    CREATE: '/api/v1/tags',
    UPDATE: (id: string) => `/api/v1/tags/${id}`,
    DELETE: (id: string) => `/api/v1/tags/${id}`,
    ADD_TO_ARTICLE: (articleId: string, tagId: string) =>
      `/api/v1/articles/${articleId}/tags/${tagId}`,
    REMOVE_FROM_ARTICLE: (articleId: string, tagId: string) =>
      `/api/v1/articles/${articleId}/tags/${tagId}`,
  },
  // Folders
  FOLDERS: {
    LIST: '/api/v1/folders',
    GET: (id: string) => `/api/v1/folders/${id}`,
    CREATE: '/api/v1/folders',
    UPDATE: (id: string) => `/api/v1/folders/${id}`,
    DELETE: (id: string) => `/api/v1/folders/${id}`,
    ADD_ARTICLE: (articleId: string, folderId: string) =>
      `/api/v1/articles/${articleId}/folders/${folderId}`,
    REMOVE_ARTICLE: (articleId: string, folderId: string) =>
      `/api/v1/articles/${articleId}/folders/${folderId}`,
  },
  // Sync
  SYNC: {
    PUSH: '/api/v1/sync/push',
    PULL: '/api/v1/sync/pull',
    STATUS: '/api/v1/sync/status',
  },
  // Platform & License
  PLATFORMS: {
    LIST: '/api/v1/platforms',
    GET: (id: string) => `/api/v1/platforms/${id}`,
    CREATE: '/api/v1/platforms',
    UPDATE: (id: string) => `/api/v1/platforms/${id}`,
    DELETE: (id: string) => `/api/v1/platforms/${id}`,
    USERS: (id: string) => `/api/v1/platforms/${id}/users`,
    USAGE: (id: string) => `/api/v1/platforms/${id}/usage`,
  },
  LICENSES: {
    LIST: '/api/v1/licenses',
    GET: (id: string) => `/api/v1/licenses/${id}`,
    PURCHASE: '/api/v1/licenses/purchase',
    UPGRADE: (id: string) => `/api/v1/licenses/${id}/upgrade`,
    CANCEL: (id: string) => `/api/v1/licenses/${id}/cancel`,
    USAGE: (id: string) => `/api/v1/licenses/${id}/usage`,
    VALIDATE: '/api/v1/licenses/validate',
  },
} as const;

/**
 * Local storage keys
 */
export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'reader_app_access_token',
  REFRESH_TOKEN: 'reader_app_refresh_token',
  USER_SETTINGS: 'reader_app_user_settings',
  SYNC_STATE: 'reader_app_sync_state',
  OFFLINE_QUEUE: 'reader_app_offline_queue',
} as const;

/**
 * App constants
 */
export const APP_CONFIG = {
  // API
  API_BASE_URL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080',
  API_TIMEOUT: 30000,

  // Sync
  SYNC_INTERVAL: 60000, // 1 minute
  SYNC_RETRY_INTERVAL: 5000, // 5 seconds
  MAX_SYNC_RETRIES: 3,

  // Pagination
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,

  // File upload
  MAX_FILE_SIZE: 50 * 1024 * 1024, // 50MB
  ALLOWED_FILE_TYPES: [
    'application/pdf',
    'application/epub+zip',
    'text/html',
    'text/plain',
  ],

  // Reading
  DEFAULT_FONT_SIZE: 18,
  DEFAULT_LINE_HEIGHT: 1.6,
  DEFAULT_FONT_FAMILY: 'system-ui, -apple-system, sans-serif',

  // Highlights
  HIGHLIGHT_COLORS: [
    '#FCD34D', // yellow
    '#F87171', // red
    '#60A5FA', // blue
    '#34D399', // green
    '#A78BFA', // purple
    '#F472B6', // pink
  ],
} as const;
