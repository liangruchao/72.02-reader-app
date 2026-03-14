-- ====================================================================
-- Reader App - Article Tables
-- Version: 2.0
-- Description: 创建文章相关表（文章、标签、文件夹、高亮、阅读进度）
-- ====================================================================

-- ====================================================================
-- 1. 文章组织表
-- ====================================================================

-- 标签表
CREATE TABLE tags (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    platform_id VARCHAR(36) DEFAULT NULL,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(7) DEFAULT NULL,
    icon VARCHAR(50) DEFAULT NULL,
    article_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_tag_name (user_id, name),
    INDEX idx_user_id (user_id),
    INDEX idx_platform_id (platform_id),
    INDEX idx_article_count (article_count)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签表';

-- 文件夹表
CREATE TABLE folders (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    platform_id VARCHAR(36) DEFAULT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT DEFAULT NULL,
    icon VARCHAR(50) DEFAULT NULL,
    color VARCHAR(7) DEFAULT NULL,
    parent_id VARCHAR(36) DEFAULT NULL,
    article_count INT NOT NULL DEFAULT 0,
    is_system_folder BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES folders(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_folder_name (user_id, name, parent_id),
    INDEX idx_user_id (user_id),
    INDEX idx_platform_id (platform_id),
    INDEX idx_parent_id (parent_id),
    INDEX idx_sort_order (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文件夹表';

-- ====================================================================
-- 2. 文章主表
-- ====================================================================

CREATE TABLE articles (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    platform_id VARCHAR(36) DEFAULT NULL,
    title VARCHAR(500) NOT NULL,
    content LONGTEXT NOT NULL,
    excerpt TEXT DEFAULT NULL,
    author VARCHAR(255) DEFAULT NULL,
    url VARCHAR(2048) DEFAULT NULL,
    source_url VARCHAR(2048) DEFAULT NULL,
    thumbnail_url VARCHAR(500) DEFAULT NULL,
    published_at TIMESTAMP DEFAULT NULL,
    saved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reading_progress DECIMAL(5,2) DEFAULT 0.00,
    reading_time INT DEFAULT NULL COMMENT '阅读时间（分钟）',
    word_count INT DEFAULT NULL COMMENT '字数',
    status ENUM('UNREAD', 'READING', 'READ') NOT NULL DEFAULT 'UNREAD',
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_platform_id (platform_id),
    INDEX idx_status (status),
    INDEX idx_is_archived (is_archived),
    INDEX idx_is_favorite (is_favorite),
    INDEX idx_saved_at (saved_at),
    INDEX idx_published_at (published_at),
    INDEX idx_reading_progress (reading_progress),
    FULLTEXT INDEX ft_search (title, content, excerpt) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文章表';

-- ====================================================================
-- 3. 文章关联表
-- ====================================================================

-- 文章-标签关联表（多对多）
CREATE TABLE article_tags (
    article_id VARCHAR(36) NOT NULL,
    tag_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (article_id, tag_id),
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
    INDEX idx_article_id (article_id),
    INDEX idx_tag_id (tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文章标签关联表';

-- 文章-文件夹关联表（多对多）
CREATE TABLE article_folders (
    article_id VARCHAR(36) NOT NULL,
    folder_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (article_id, folder_id),
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
    FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE,
    INDEX idx_article_id (article_id),
    INDEX idx_folder_id (folder_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文章文件夹关联表';

-- ====================================================================
-- 4. 高亮和批注表
-- ====================================================================

CREATE TABLE highlights (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    platform_id VARCHAR(36) DEFAULT NULL,
    article_id VARCHAR(36) NOT NULL,
    text TEXT NOT NULL COMMENT '高亮的文本',
    note TEXT DEFAULT NULL COMMENT '批注内容',
    color VARCHAR(7) DEFAULT NULL COMMENT '高亮颜色',
    position INT NOT NULL COMMENT '高亮位置（字符偏移）',
    length INT NOT NULL COMMENT '高亮长度',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_platform_id (platform_id),
    INDEX idx_article_id (article_id),
    INDEX idx_position (position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='高亮和批注表';

-- ====================================================================
-- 5. 阅读进度表
-- ====================================================================

CREATE TABLE reading_progress (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    article_id VARCHAR(36) NOT NULL,
    last_position INT NOT NULL DEFAULT 0 COMMENT '最后阅读位置（字符偏移）',
    progress_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT '阅读进度百分比',
    last_read_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最后阅读时间',
    total_read_time INT DEFAULT 0 COMMENT '总阅读时间（秒）',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_article (user_id, article_id),
    INDEX idx_user_id (user_id),
    INDEX idx_article_id (article_id),
    INDEX idx_last_read_at (last_read_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='阅读进度表';

-- ====================================================================
-- 6. 高亮-标签关联表
-- ====================================================================

CREATE TABLE highlight_tags (
    highlight_id VARCHAR(36) NOT NULL,
    tag_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (highlight_id, tag_id),
    FOREIGN KEY (highlight_id) REFERENCES highlights(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
    INDEX idx_highlight_id (highlight_id),
    INDEX idx_tag_id (tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='高亮标签关联表';

-- ====================================================================
-- 7. 同步状态表（用于 CRDT 同步）
-- ====================================================================

CREATE TABLE sync_state (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    entity_type VARCHAR(50) NOT NULL COMMENT '实体类型：article, highlight, tag 等',
    entity_id VARCHAR(36) NOT NULL COMMENT '实体ID',
    version INT NOT NULL DEFAULT 1 COMMENT 'CRDT 版本号',
    checksum VARCHAR(64) DEFAULT NULL COMMENT '内容校验和',
    last_synced_at TIMESTAMP DEFAULT NULL COMMENT '最后同步时间',
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否已删除',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_entity (user_id, entity_type, entity_id),
    INDEX idx_user_id (user_id),
    INDEX idx_entity_type (entity_type),
    INDEX idx_last_synced_at (last_synced_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='同步状态表';

-- ====================================================================
-- 注释和说明
-- ====================================================================

-- 1. 文章表支持全文搜索（FULLTEXT 索引）
-- 2. 多对多关系使用中间表存储
-- 3. 阅读进度支持精确到字符级别
-- 4. 高亮支持颜色和位置记录
-- 5. 同步状态表支持 CRDT 冲突解决
-- 6. 所有软删除字段使用 is_deleted 标记
