/**
 * Tag entity
 */
export interface Tag {
  id: string;
  userId: string;
  platformId?: string;
  name: string;
  color?: string;
  icon?: string;
  articleCount: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Folder entity
 */
export interface Folder {
  id: string;
  userId: string;
  platformId?: string;
  name: string;
  description?: string;
  icon?: string;
  color?: string;
  parentId?: string;
  articleCount: number;
  children?: Folder[];
  isSystemFolder: boolean;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Highlight entity
 */
export interface Highlight {
  id: string;
  userId: string;
  platformId?: string;
  articleId: string;
  article?: Article;
  text: string;
  note?: string;
  color?: string;
  position: number;
  length: number;
  tags?: Tag[];
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Re-export Article type
 */
export interface Article {
  id: string;
  userId: string;
  platformId?: string;
  title: string;
  content: string;
  excerpt?: string;
  author?: string;
  url?: string;
  thumbnailUrl?: string;
  publishedAt?: Date;
  savedAt: Date;
  readingProgress?: number;
  readingTime?: number;
  wordCount?: number;
  status: 'UNREAD' | 'READING' | 'READ';
  isArchived: boolean;
  isFavorite: boolean;
  tags?: Tag[];
  folderId?: string;
  highlights?: Highlight[];
  createdAt: Date;
  updatedAt: Date;
}

/**
 * API Response wrapper
 */
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

/**
 * Pagination response
 */
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
  hasNext: boolean;
  hasPrevious: boolean;
}

/**
 * Article list filters
 */
export interface ArticleFilters {
  status?: string;
  tagId?: string;
  folderId?: string;
  isFavorite?: boolean;
  isArchived?: boolean;
  search?: string;
  sortBy?: 'savedAt' | 'publishedAt' | 'title' | 'readingProgress';
  sortOrder?: 'asc' | 'desc';
}
