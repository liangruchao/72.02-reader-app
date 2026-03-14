/**
 * Article entity
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
  sourceUrl?: string;
  thumbnailUrl?: string;
  publishedAt?: Date;
  savedAt: Date;
  readingProgress?: number;
  readingTime?: number;
  wordCount?: number;
  status: ArticleStatus;
  isArchived: boolean;
  isFavorite: boolean;
  tags?: Tag[];
  folderId?: string;
  folder?: Folder;
  highlights?: Highlight[];
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Article status enum
 */
export enum ArticleStatus {
  UNREAD = 'UNREAD',
  READING = 'READING',
  READ = 'READ',
}

/**
 * Article creation request
 */
export interface CreateArticleRequest {
  url?: string;
  content?: string;
  title?: string;
  author?: string;
  tags?: string[];
  folderId?: string;
}

/**
 * Article update request
 */
export interface UpdateArticleRequest {
  title?: string;
  status?: ArticleStatus;
  isArchived?: boolean;
  isFavorite?: boolean;
  folderId?: string;
  readingProgress?: number;
}
