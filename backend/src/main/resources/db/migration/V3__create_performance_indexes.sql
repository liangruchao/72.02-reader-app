-- ====================================================================
-- Reader App - Performance Optimization Indexes
-- Version: 3.0
-- Description: 创建性能优化索引
-- ====================================================================

-- ====================================================================
-- 1. 用户和权限索引优化
-- ====================================================================

-- 用户表复合索引
CREATE INDEX idx_users_platform_active ON users(platform_id, is_active);
CREATE INDEX idx_users_email_active ON users(email, is_active);

-- 角色表复合索引
CREATE INDEX idx_roles_platform_system ON roles(platform_id, is_system_role);

-- ====================================================================
-- 2. License 和订阅索引优化
-- ====================================================================

-- License 表复合索引
CREATE INDEX idx_licenses_platform_active ON licenses(platform_id, is_active);
CREATE INDEX idx_licenses_active_dates ON licenses(is_active, start_date, end_date);

-- 订阅表复合索引
CREATE INDEX idx_subscriptions_platform_status ON subscriptions(platform_id, status);
CREATE INDEX idx_subscriptions_license_status ON subscriptions(license_id, status);
CREATE INDEX idx_subscriptions_status_billing ON subscriptions(status, next_billing_date);

-- ====================================================================
-- 3. 文章查询性能索引
-- ====================================================================

-- 文章表复合索引（常用查询组合）
CREATE INDEX idx_articles_user_status ON articles(user_id, status);
CREATE INDEX idx_articles_user_archived ON articles(user_id, is_archived);
CREATE INDEX idx_articles_user_favorite ON articles(user_id, is_favorite);
CREATE INDEX idx_articles_user_saved ON articles(user_id, saved_at DESC);
CREATE INDEX idx_articles_platform_status ON articles(platform_id, status);
CREATE INDEX idx_articles_status_archived ON articles(status, is_archived);

-- 文章表覆盖索引（用于列表查询）
CREATE INDEX idx_articles_list_cover ON articles(user_id, status, is_archived, saved_at DESC);

-- ====================================================================
-- 4. 标签和文件夹索引优化
-- ====================================================================

-- 标签表复合索引
CREATE INDEX idx_tags_user_count ON tags(user_id, article_count DESC);
CREATE INDEX idx_tags_platform_count ON tags(platform_id, article_count DESC);

-- 文件夹表复合索引
CREATE INDEX idx_folders_user_parent ON folders(user_id, parent_id);
CREATE INDEX idx_folders_user_order ON folders(user_id, sort_order);

-- ====================================================================
-- 5. 关联表索引优化
-- ====================================================================

-- 文章-标签关联表
CREATE INDEX idx_article_tags_article ON article_tags(article_id);
CREATE INDEX idx_article_tags_tag ON article_tags(tag_id);

-- 文章-文件夹关联表
CREATE INDEX idx_article_folders_article ON article_folders(article_id);
CREATE INDEX idx_article_folders_folder ON article_folders(folder_id);

-- 高亮表复合索引
CREATE INDEX idx_highlights_user_article ON highlights(user_id, article_id);
CREATE INDEX idx_highlights_article_position ON highlights(article_id, position);

-- 阅读进度表复合索引
CREATE INDEX idx_reading_progress_user_article ON reading_progress(user_id, article_id);
CREATE INDEX idx_reading_progress_user_read ON reading_progress(user_id, last_read_at DESC);

-- ====================================================================
-- 6. 同步性能索引
-- ====================================================================

-- 同步状态表复合索引
CREATE INDEX idx_sync_state_user_entity ON sync_state(user_id, entity_type);
CREATE INDEX idx_sync_state_deleted ON sync_state(user_id, is_deleted);
CREATE INDEX idx_sync_state_sync_time ON sync_state(user_id, last_synced_at);

-- ====================================================================
-- 7. 社交账户索引优化
-- ====================================================================

-- 社交账户表复合索引
CREATE INDEX idx_social_accounts_user_provider ON social_accounts(user_id, provider);

-- ====================================================================
-- 8. 全文搜索优化（可选）
-- ====================================================================

-- 为文章表添加更精细的全文搜索索引
-- 注意：需要 MySQL 5.7.6+ 和 InnoDB 引擎

-- 创建全文搜索解析器配置（ngram 适用于中文分词）
-- 这个已经在 V2 中定义，这里只是注释说明

-- ====================================================================
-- 9. 统计和报表索引
-- ====================================================================

-- 平台用户统计
CREATE INDEX idx_platforms_user_count ON platforms(user_count);

-- License 使用统计
CREATE INDEX idx_licenses_platform_tier ON licenses(platform_id, tier);

-- ====================================================================
-- 索引说明
-- ====================================================================

-- 1. 复合索引遵循最左前缀原则
-- 2. 高频查询路径优先建立索引
-- 3. 覆盖索引减少回表查询
-- 4. 全文索引支持中文搜索（ngram）
-- 5. 定期维护索引统计信息
-- 6. 监控慢查询日志优化索引

-- ====================================================================
-- 索引维护建议
-- ====================================================================

-- 定期分析表：
-- ANALYZE TABLE users, articles, tags, folders;

-- 定期优化表：
-- OPTIMIZE TABLE users, articles, tags, folders;

-- 查看索引使用情况：
-- SELECT * FROM sys.schema_index_statistics;
-- SELECT * FROM sys.schema_unused_indexes;
