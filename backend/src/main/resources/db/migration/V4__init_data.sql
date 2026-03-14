-- ====================================================================
-- Reader App - Initial Data
-- Version: 4.0
-- Description: 初始化系统数据（权限、角色、默认文件夹等）
-- ====================================================================

-- ====================================================================
-- 1. 插入系统权限
-- ====================================================================

-- 用户管理权限
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-001', 'users.create', 'users', 'create', '创建用户'),
('perm-002', 'users.read', 'users', 'read', '查看用户'),
('perm-003', 'users.update', 'users', 'update', '更新用户'),
('perm-004', 'users.delete', 'users', 'delete', '删除用户'),
('perm-005', 'users.manage', 'users', 'manage', '管理用户（所有操作）');

-- 文章管理权限
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-101', 'articles.create', 'articles', 'create', '创建文章'),
('perm-102', 'articles.read', 'articles', 'read', '查看文章'),
('perm-103', 'articles.update', 'articles', 'update', '更新文章'),
('perm-104', 'articles.delete', 'articles', 'delete', '删除文章'),
('perm-105', 'articles.export', 'articles', 'export', '导出文章'),
('perm-106', 'articles.import', 'articles', 'import', '导入文章');

-- 标签和文件夹权限
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-201', 'tags.create', 'tags', 'create', '创建标签'),
('perm-202', 'tags.read', 'tags', 'read', '查看标签'),
('perm-203', 'tags.update', 'tags', 'update', '更新标签'),
('perm-204', 'tags.delete', 'tags', 'delete', '删除标签'),
('perm-205', 'folders.create', 'folders', 'create', '创建文件夹'),
('perm-206', 'folders.read', 'folders', 'read', '查看文件夹'),
('perm-207', 'folders.update', 'folders', 'update', '更新文件夹'),
('perm-208', 'folders.delete', 'folders', 'delete', '删除文件夹');

-- 高亮和批注权限
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-301', 'highlights.create', 'highlights', 'create', '创建高亮'),
('perm-302', 'highlights.read', 'highlights', 'read', '查看高亮'),
('perm-303', 'highlights.update', 'highlights', 'update', '更新高亮'),
('perm-304', 'highlights.delete', 'highlights', 'delete', '删除高亮');

-- 平台管理权限（B2B2C）
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-401', 'platforms.create', 'platforms', 'create', '创建平台'),
('perm-402', 'platforms.read', 'platforms', 'read', '查看平台'),
('perm-403', 'platforms.update', 'platforms', 'update', '更新平台'),
('perm-404', 'platforms.delete', 'platforms', 'delete', '删除平台'),
('perm-405', 'platforms.manage', 'platforms', 'manage', '管理平台（所有操作）'),
('perm-406', 'platforms.view_users', 'platforms', 'view_users', '查看平台用户'),
('perm-407', 'platforms.view_usage', 'platforms', 'view_usage', '查看平台使用量');

-- License 管理权限
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-501', 'licenses.create', 'licenses', 'create', '创建 License'),
('perm-502', 'licenses.read', 'licenses', 'read', '查看 License'),
('perm-503', 'licenses.update', 'licenses', 'update', '更新 License'),
('perm-504', 'licenses.delete', 'licenses', 'delete', '删除 License'),
('perm-505', 'licenses.purchase', 'licenses', 'purchase', '购买 License'),
('perm-506', 'licenses.upgrade', 'licenses', 'upgrade', '升级 License'),
('perm-507', 'licenses.cancel', 'licenses', 'cancel', '取消 License'),
('perm-508', 'licenses.validate', 'licenses', 'validate', '验证 License');

-- 订阅和计费权限
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-601', 'subscriptions.read', 'subscriptions', 'read', '查看订阅'),
('perm-602', 'subscriptions.manage', 'subscriptions', 'manage', '管理订阅'),
('perm-603', 'billing.read', 'billing', 'read', '查看账单'),
('perm-604', 'billing.manage', 'billing', 'manage', '管理账单');

-- 角色和权限管理权限
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-701', 'roles.create', 'roles', 'create', '创建角色'),
('perm-702', 'roles.read', 'roles', 'read', '查看角色'),
('perm-703', 'roles.update', 'roles', 'update', '更新角色'),
('perm-704', 'roles.delete', 'roles', 'delete', '删除角色'),
('perm-705', 'permissions.assign', 'permissions', 'assign', '分配权限'),
('perm-706', 'permissions.revoke', 'permissions', 'revoke', '撤销权限');

-- 系统管理权限
INSERT INTO permissions (id, name, resource, action, description) VALUES
('perm-801', 'system.read', 'system', 'read', '查看系统信息'),
('perm-802', 'system.manage', 'system', 'manage', '管理系统配置'),
('perm-803', 'system.monitor', 'system', 'monitor', '监控系统状态'),
('perm-804', 'system.backup', 'system', 'backup', '备份系统数据'),
('perm-805', 'system.restore', 'system', 'restore', '恢复系统数据');

-- ====================================================================
-- 2. 插入系统角色
-- ====================================================================

-- 超级管理员角色（系统管理员）
INSERT INTO roles (id, platform_id, name, description, is_system_role) VALUES
('role-super-admin', NULL, 'SUPER_ADMIN', '超级管理员，拥有所有权限', TRUE);

-- 平台管理员角色
INSERT INTO roles (id, platform_id, name, description, is_system_role) VALUES
('role-platform-admin', NULL, 'PLATFORM_ADMIN', '平台管理员，管理平台和用户', TRUE);

-- 普通用户角色
INSERT INTO roles (id, platform_id, name, description, is_system_role) VALUES
('role-user', NULL, 'USER', '普通用户，标准用户权限', TRUE);

-- 只读用户角色
INSERT INTO roles (id, platform_id, name, description, is_system_role) VALUES
('role-readonly', NULL, 'READONLY', '只读用户，仅查看权限', TRUE);

-- ====================================================================
-- 3. 为系统角色分配权限
-- ====================================================================

-- 超级管理员：所有权限
INSERT INTO role_permissions (role_id, permission_id)
SELECT 'role-super-admin', id FROM permissions;

-- 平台管理员：平台管理、用户管理、License 管理、文章管理权限
INSERT INTO role_permissions (role_id, permission_id)
SELECT 'role-platform-admin', id FROM permissions
WHERE name IN (
    'platforms.create', 'platforms.read', 'platforms.update', 'platforms.manage', 'platforms.view_users', 'platforms.view_usage',
    'users.create', 'users.read', 'users.update', 'users.manage',
    'licenses.read', 'licenses.validate', 'licenses.upgrade',
    'subscriptions.read', 'billing.read',
    'articles.create', 'articles.read', 'articles.update', 'articles.delete',
    'tags.*', 'folders.*', 'highlights.*'
);

-- 普通用户：文章、标签、文件夹、高亮的完整权限
INSERT INTO role_permissions (role_id, permission_id)
SELECT 'role-user', id FROM permissions
WHERE name IN (
    'articles.create', 'articles.read', 'articles.update', 'articles.delete', 'articles.export',
    'tags.create', 'tags.read', 'tags.update', 'tags.delete',
    'folders.create', 'folders.read', 'folders.update', 'folders.delete',
    'highlights.create', 'highlights.read', 'highlights.update', 'highlights.delete'
);

-- 只读用户：仅查看权限
INSERT INTO role_permissions (role_id, permission_id)
SELECT 'role-readonly', id FROM permissions
WHERE name IN (
    'articles.read', 'tags.read', 'folders.read', 'highlights.read'
);

-- ====================================================================
-- 4. 创建使用量日志表
-- ====================================================================

CREATE TABLE usage_logs (
    id VARCHAR(36) PRIMARY KEY,
    platform_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36),
    resource_type VARCHAR(50) NOT NULL COMMENT '资源类型：article, highlight, storage 等',
    action VARCHAR(50) NOT NULL COMMENT '操作类型：create, read, update, delete',
    quantity INT NOT NULL DEFAULT 1 COMMENT '使用数量',
    unit VARCHAR(20) DEFAULT 'count' COMMENT '单位：count, bytes, minutes 等',
    metadata JSON DEFAULT NULL COMMENT '额外信息',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (platform_id) REFERENCES platforms(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_platform_id (platform_id),
    INDEX idx_user_id (user_id),
    INDEX idx_resource_type (resource_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='使用量日志表';

-- ====================================================================
-- 5. 创建账单记录表
-- ====================================================================

CREATE TABLE billing_records (
    id VARCHAR(36) PRIMARY KEY,
    platform_id VARCHAR(36) NOT NULL,
    subscription_id VARCHAR(36),
    type ENUM('CHARGE', 'REFUND', 'ADJUSTMENT') NOT NULL DEFAULT 'CHARGE',
    amount DOUBLE NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    description TEXT DEFAULT NULL,
    status ENUM('PENDING', 'SUCCESS', 'FAILED', 'CANCELED') NOT NULL DEFAULT 'PENDING',
    transaction_id VARCHAR(255) DEFAULT NULL COMMENT '第三方交易ID',
    invoice_url VARCHAR(500) DEFAULT NULL COMMENT '账单 URL',
    due_date TIMESTAMP DEFAULT NULL,
    paid_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (platform_id) REFERENCES platforms(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL,
    INDEX idx_platform_id (platform_id),
    INDEX idx_subscription_id (subscription_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='账单记录表';

-- ====================================================================
-- 6. 创建配置表（存储微信、Google 等配置）
-- ====================================================================

CREATE TABLE system_configs (
    id VARCHAR(36) PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    config_type VARCHAR(20) NOT NULL DEFAULT 'STRING' COMMENT 'STRING, JSON, BOOLEAN, NUMBER',
    description TEXT DEFAULT NULL,
    is_encrypted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 插入默认配置
INSERT INTO system_configs (id, config_key, config_value, config_type, description) VALUES
('cfg-001', 'app.name', 'Reader App', 'STRING', '应用名称'),
('cfg-002', 'app.version', '1.0.0', 'STRING', '应用版本'),
('cfg-003', 'app.max_upload_size', '52428800', 'NUMBER', '最大上传文件大小（字节）'),
('cfg-004', 'sync.enabled', 'true', 'BOOLEAN', '是否启用同步'),
('cfg-005', 'sync.interval', '60000', 'NUMBER', '同步间隔（毫秒）');

-- ====================================================================
-- 7. 创建 RSS 订阅源表（预留）
-- ====================================================================

CREATE TABLE rss_feeds (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    platform_id VARCHAR(36) DEFAULT NULL,
    title VARCHAR(255) NOT NULL,
    url VARCHAR(2048) NOT NULL,
    description TEXT DEFAULT NULL,
    favicon_url VARCHAR(500) DEFAULT NULL,
    update_frequency INT DEFAULT 3600 COMMENT '更新频率（秒）',
    last_fetched_at TIMESTAMP DEFAULT NULL,
    last_error TEXT DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_url (user_id, url),
    INDEX idx_user_id (user_id),
    INDEX idx_last_fetched_at (last_fetched_at),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='RSS订阅源表';

-- ====================================================================
-- 8. 创建邮件转存配置表（预留）
-- ====================================================================

CREATE TABLE email_configs (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    platform_id VARCHAR(36) DEFAULT NULL,
    email_address VARCHAR(255) NOT NULL UNIQUE COMMENT '分配给用户的转存邮箱地址',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    auto_save BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否自动保存',
    folder_id VARCHAR(36) DEFAULT NULL COMMENT '默认保存到的文件夹',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_email_address (email_address),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='邮件转存配置表';

-- ====================================================================
-- 说明
-- ====================================================================

-- 1. 插入了 46 个系统权限，涵盖所有功能模块
-- 2. 创建了 4 个系统角色：超级管理员、平台管理员、普通用户、只读用户
-- 3. 为系统角色分配了相应的权限
-- 4. 创建了使用量日志表用于计费
-- 5. 创建了账单记录表
-- 6. 创建了系统配置表
-- 7. 预留了 RSS 订阅和邮件转存功能表
