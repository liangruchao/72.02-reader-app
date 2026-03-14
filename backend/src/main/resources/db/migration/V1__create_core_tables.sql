-- ====================================================================
-- Reader App - Core Database Schema
-- Version: 1.0
-- Description: 创建核心表结构（用户、角色、权限、平台、License）
-- ====================================================================

-- ====================================================================
-- 1. 用户和权限管理表
-- ====================================================================

-- 用户表
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    platform_id VARCHAR(36) DEFAULT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(100) DEFAULT NULL,
    display_name VARCHAR(100) DEFAULT NULL,
    avatar_url VARCHAR(500) DEFAULT NULL,
    bio TEXT DEFAULT NULL,
    password VARCHAR(255) DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_platform_id (platform_id),
    INDEX idx_email (email),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 角色表
CREATE TABLE roles (
    id VARCHAR(36) PRIMARY KEY,
    platform_id VARCHAR(36) DEFAULT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT DEFAULT NULL,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_role_name (platform_id, name),
    INDEX idx_platform_id (platform_id),
    INDEX idx_is_system_role (is_system_role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色表';

-- 权限表
CREATE TABLE permissions (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_resource_action (resource, action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='权限表';

-- 用户-角色关联表（多对多）
CREATE TABLE user_roles (
    user_id VARCHAR(36) NOT NULL,
    role_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_role_id (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户角色关联表';

-- 角色-权限关联表（多对多）
CREATE TABLE role_permissions (
    role_id VARCHAR(36) NOT NULL,
    permission_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_role_id (role_id),
    INDEX idx_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色权限关联表';

-- ====================================================================
-- 2. B2B2C 多租户表
-- ====================================================================

-- 平台表
CREATE TABLE platforms (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT NULL,
    logo_url VARCHAR(500) DEFAULT NULL,
    website VARCHAR(500) DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    license_id VARCHAR(36) DEFAULT NULL,
    user_limit INT DEFAULT NULL,
    user_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE SET NULL,
    INDEX idx_is_active (is_active),
    INDEX idx_license_id (license_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='平台表';

-- License 表
CREATE TABLE licenses (
    id VARCHAR(36) PRIMARY KEY,
    platform_id VARCHAR(36) NOT NULL,
    license_key VARCHAR(500) NOT NULL UNIQUE,
    type ENUM('TRIAL', 'SUBSCRIPTION', 'LIFETIME') NOT NULL DEFAULT 'SUBSCRIPTION',
    tier ENUM('FREE', 'BASIC', 'PRO', 'ENTERPRISE') NOT NULL DEFAULT 'BASIC',
    max_users INT DEFAULT NULL,
    max_articles BIGINT DEFAULT NULL,
    max_storage BIGINT DEFAULT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (platform_id) REFERENCES platforms(id) ON DELETE CASCADE,
    INDEX idx_platform_id (platform_id),
    INDEX idx_license_key (license_key),
    INDEX idx_is_active (is_active),
    INDEX idx_end_date (end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='License表';

-- License 功能集合表
CREATE TABLE license_features (
    license_id VARCHAR(36) NOT NULL,
    feature VARCHAR(100) NOT NULL,
    PRIMARY KEY (license_id, feature),
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    INDEX idx_license_id (license_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='License功能表';

-- 订阅表
CREATE TABLE subscriptions (
    id VARCHAR(36) PRIMARY KEY,
    platform_id VARCHAR(36) NOT NULL,
    license_id VARCHAR(36) NOT NULL,
    status ENUM('ACTIVE', 'PAST_DUE', 'CANCELED', 'INCOMPLETE', 'TRIALING') NOT NULL DEFAULT 'ACTIVE',
    amount DOUBLE NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    billing_cycle ENUM('MONTHLY', 'QUARTERLY', 'YEARLY') NOT NULL DEFAULT 'MONTHLY',
    current_period_start TIMESTAMP NOT NULL,
    current_period_end TIMESTAMP NOT NULL,
    next_billing_date TIMESTAMP DEFAULT NULL,
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
    canceled_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (platform_id) REFERENCES platforms(id) ON DELETE CASCADE,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    INDEX idx_platform_id (platform_id),
    INDEX idx_license_id (license_id),
    INDEX idx_status (status),
    INDEX idx_next_billing_date (next_billing_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订阅表';

-- ====================================================================
-- 3. 第三方集成表
-- ====================================================================

-- 社交账户表
CREATE TABLE social_accounts (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    provider ENUM('WECHAT', 'GOOGLE', 'GITHUB', 'APPLE') NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT DEFAULT NULL,
    refresh_token TEXT DEFAULT NULL,
    expires_at TIMESTAMP DEFAULT NULL,
    email VARCHAR(255) DEFAULT NULL,
    display_name VARCHAR(100) DEFAULT NULL,
    avatar_url VARCHAR(500) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_provider_user (provider, provider_user_id),
    INDEX idx_user_id (user_id),
    INDEX idx_provider (provider)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='社交账户表';

-- ====================================================================
-- 注释和说明
-- ====================================================================

-- 1. 所有表使用 InnoDB 引擎，支持事务和外键
-- 2. 所有表使用 utf8mb4 字符集，支持完整的 Unicode 字符（包括 emoji）
-- 3. 所有主键使用 VARCHAR(36) 存储 UUID
-- 4. created_at 和 updated_at 字段自动管理时间戳
-- 5. 外键约束确保数据完整性
-- 6. 索引优化常用查询路径
