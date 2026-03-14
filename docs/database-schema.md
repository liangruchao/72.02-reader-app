# 数据库设计文档

## 概述

Reader App 使用 MySQL 8.0+ 作为主数据库，采用 Flyway 进行数据库版本管理和迁移。

## 数据库版本信息

- **MySQL 版本**: 8.0+
- **字符集**: utf8mb4
- **排序规则**: utf8mb4_unicode_ci
- **引擎**: InnoDB（支持事务和外键）
- **迁移工具**: Flyway

## 迁移脚本列表

| 版本 | 文件名 | 描述 |
|------|--------|------|
| V1 | V1__create_core_tables.sql | 创建核心表（用户、角色、权限、平台、License） |
| V2 | V2__create_article_tables.sql | 创建文章相关表 |
| V3 | V3__create_performance_indexes.sql | 创建性能优化索引 |
| V4 | V4__init_data.sql | 初始化系统数据 |

## 数据库表结构

### 1. 用户和权限管理（B2B2C）

#### 1.1 用户表 (users)
```sql
主要字段：
- id: UUID 主键
- platform_id: 所属平台 ID（B2B2C 多租户）
- email: 邮箱（唯一）
- username: 用户名
- display_name: 显示名称
- password: 密码（加密存储）
- is_active: 是否激活
- is_email_verified: 邮箱是否验证

关联：
- roles: ManyToMany 关联
- social_accounts: OneToMany 关联
```

#### 1.2 角色表 (roles)
```sql
主要字段：
- id: UUID 主键
- platform_id: 所属平台 ID
- name: 角色名称（同一平台内唯一）
- description: 角色描述
- is_system_role: 是否系统角色

关联：
- users: ManyToMany 关联
- permissions: ManyToMany 关联
```

#### 1.3 权限表 (permissions)
```sql
主要字段：
- id: UUID 主键
- name: 权限名称（全局唯一）
- resource: 资源类型（users, articles, tags 等）
- action: 操作类型（create, read, update, delete）
- description: 权限描述

权限格式：{resource}.{action}
例如：users.create, articles.read
```

#### 1.4 关联表
- **user_roles**: 用户-角色多对多关联
- **role_permissions**: 角色-权限多对多关联

### 2. B2B2C 多租户管理

#### 2.1 平台表 (platforms)
```sql
主要字段：
- id: UUID 主键
- name: 平台唯一标识
- display_name: 平台显示名称
- is_active: 是否激活
- license_id: 关联的 License
- user_limit: 用户数量限制
- user_count: 当前用户数量

用途：B2B2C 模式中的平台（公司/组织）
```

#### 2.2 License 表 (licenses)
```sql
主要字段：
- id: UUID 主键
- platform_id: 所属平台
- license_key: License 密钥（唯一）
- type: License 类型（TRIAL, SUBSCRIPTION, LIFETIME）
- tier: License 等级（FREE, BASIC, PRO, ENTERPRISE）
- max_users: 最大用户数
- max_articles: 最大文章数
- max_storage: 最大存储空间（字节）
- start_date: 开始日期
- end_date: 结束日期
- is_active: 是否激活
- auto_renew: 是否自动续费

关联：
- license_features: 一对多关联（License 功能列表）
```

#### 2.3 License 功能表 (license_features)
```sql
主要字段：
- license_id: License ID
- feature: 功能名称（例如：highlights, sync, export）

存储 License 支持的功能列表
```

#### 2.4 订阅表 (subscriptions)
```sql
主要字段：
- id: UUID 主键
- platform_id: 所属平台
- license_id: 关联的 License
- status: 订阅状态（ACTIVE, PAST_DUE, CANCELED 等）
- amount: 金额
- currency: 货币（USD, CNY 等）
- billing_cycle: 计费周期（MONTHLY, QUARTERLY, YEARLY）
- current_period_start: 当前计费周期开始
- current_period_end: 当前计费周期结束
- next_billing_date: 下次计费日期
- cancel_at_period_end: 是否在周期结束后取消
```

### 3. 第三方集成

#### 3.1 社交账户表 (social_accounts)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- provider: 提供商（WECHAT, GOOGLE, GITHUB, APPLE）
- provider_user_id: 第三方用户 ID
- access_token: 访问令牌
- refresh_token: 刷新令牌
- expires_at: 过期时间

支持微信、Google、GitHub、Apple 登录
```

### 4. 文章管理

#### 4.1 文章表 (articles)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- platform_id: 所属平台 ID
- title: 文章标题
- content: 文章内容（LONGTEXT）
- excerpt: 摘要
- author: 作者
- url: 原始 URL
- source_url: 来源 URL
- thumbnail_url: 缩略图 URL
- published_at: 发布时间
- saved_at: 保存时间
- reading_progress: 阅读进度（0-100）
- reading_time: 阅读时间（分钟）
- word_count: 字数
- status: 状态（UNREAD, READING, READ）
- is_archived: 是否归档
- is_favorite: 是否收藏

索引：
- 全文搜索索引：title, content, excerpt
- 复合索引：user_id + status, user_id + saved_at 等
```

#### 4.2 标签表 (tags)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- name: 标签名称（同一用户内唯一）
- color: 颜色（十六进制）
- icon: 图标
- article_count: 文章数量
```

#### 4.3 文件夹表 (folders)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- name: 文件夹名称
- parent_id: 父文件夹 ID（支持树形结构）
- article_count: 文章数量
- is_system_folder: 是否系统文件夹
- sort_order: 排序

支持层级文件夹结构
```

#### 4.4 高亮表 (highlights)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- article_id: 文章 ID
- text: 高亮的文本
- note: 批注内容
- color: 高亮颜色
- position: 位置（字符偏移）
- length: 高亮长度

支持精确到字符级别的高亮
```

#### 4.5 阅读进度表 (reading_progress)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- article_id: 文章 ID
- last_position: 最后阅读位置（字符偏移）
- progress_percentage: 阅读进度百分比
- last_read_at: 最后阅读时间
- total_read_time: 总阅读时间（秒）
```

### 5. 关联表

#### 5.1 article_tags
文章-标签多对多关联

#### 5.2 article_folders
文章-文件夹多对多关联（一篇文章可以属于多个文件夹）

#### 5.3 highlight_tags
高亮-标签多对多关联

### 6. 同步支持

#### 6.1 同步状态表 (sync_state)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- entity_type: 实体类型（article, highlight, tag 等）
- entity_id: 实体 ID
- version: CRDT 版本号
- checksum: 内容校验和
- last_synced_at: 最后同步时间
- is_deleted: 是否已删除（软删除）

支持 CRDT 冲突解决和离线同步
```

### 7. 计费和使用量

#### 7.1 使用量日志表 (usage_logs)
```sql
主要字段：
- id: UUID 主键
- platform_id: 平台 ID
- user_id: 用户 ID
- resource_type: 资源类型（article, highlight, storage）
- action: 操作类型（create, read, update, delete）
- quantity: 使用数量
- unit: 单位（count, bytes, minutes）

用于计费和配额控制
```

#### 7.2 账单记录表 (billing_records)
```sql
主要字段：
- id: UUID 主键
- platform_id: 平台 ID
- subscription_id: 订阅 ID
- type: 类型（CHARGE, REFUND,, ADJUSTMENT）
- amount: 金额
- status: 状态（PENDING, SUCCESS, FAILED）
- transaction_id: 第三方交易 ID
- invoice_url: 账单 URL
```

### 8. 高级功能（预留）

#### 8.1 RSS 订阅源表 (rss_feeds)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- title: RSS 源标题
- url: RSS 源 URL
- update_frequency: 更新频率（秒）
- last_fetched_at: 最后抓取时间
```

#### 8.2 邮件转存配置表 (email_configs)
```sql
主要字段：
- id: UUID 主键
- user_id: 用户 ID
- email_address: 分配的转存邮箱地址
- auto_save: 是否自动保存
- folder_id: 默认保存的文件夹
```

#### 8.3 系统配置表 (system_configs)
```sql
主要字段：
- id: UUID 主键
- config_key: 配置键（唯一）
- config_value: 配置值
- config_type: 类型（STRING, JSON, BOOLEAN, NUMBER）
- is_encrypted: 是否加密

存储系统级配置，包括微信、Google 集成配置等
```

## 索引策略

### 1. 主键索引
- 所有表使用 UUID 作为主键（VARCHAR(36)）

### 2. 唯一索引
- users.email
- roles.name (同一平台内)
- permissions.name
- tags.name (同一用户内)
- platforms.name
- licenses.license_key
- social_accounts.provider + provider_user_id

### 3. 复合索引
- articles: user_id + status, user_id + saved_at DESC
- users: platform_id + is_active
- licenses: platform_id + is_active
- subscriptions: platform_id + status

### 4. 全文索引
- articles: title, content, excerpt（使用 ngram 解析器支持中文）

## 性能优化

### 1. 索引优化
- 为高频查询路径创建复合索引
- 使用覆盖索引减少回表查询
- 定期维护索引统计信息

### 2. 分区策略（未来）
- 考虑按时间分区大表（articles, sync_state）
- 考虑按平台分区多租户表

### 3. 查询优化
- 使用 EXPLAIN 分析慢查询
- 避免全表扫描
- 合理使用缓存（Redis）

## 数据完整性

### 1. 外键约束
- 所有关联关系使用外键约束
- 级联删除和更新规则明确
- 防止孤立数据

### 2. 唯一性约束
- 使用 UNIQUE 约束确保数据唯一性
- 复合唯一约束处理多列唯一性

### 3. 默认值
- 时间戳字段使用 DEFAULT CURRENT_TIMESTAMP
- 布尔字段有明确默认值
- 数量字段默认为 0

## 初始数据

### 1. 系统权限（46 个）
- 用户管理：5 个
- 文章管理：6 个
- 标签和文件夹：8 个
- 高亮和批注：4 个
- 平台管理：7 个
- License 管理：8 个
- 订阅和计费：4 个
- 角色和权限管理：6 个
- 系统管理：5 个

### 2. 系统角色（4 个）
- SUPER_ADMIN：超级管理员（所有权限）
- PLATFORM_ADMIN：平台管理员
- USER：普通用户
- READONLY：只读用户

### 3. 系统配置
- 应用名称、版本等基础配置
- 同步配置
- 上传文件大小限制

## 备份策略

### 1. 全量备份
- 每天凌晨 2 点执行全量备份
- 使用 mysqldump 工具
- 备份文件压缩并上传到 OSS

### 2. 增量备份
- 基于 binlog 的增量备份
- 每小时执行一次

### 3. 备份保留
- 保留最近 7 天的备份
- 保留每周的备份（4 周）
- 保留每月的备份（12 个月）

## 监控指标

### 1. 表大小监控
- articles 表大小（最大的表）
- sync_state 表大小
- 其他核心表大小

### 2. 查询性能
- 慢查询日志
- 查询响应时间
- 索引使用率

### 3. 连接数
- 活跃连接数
- 连接池使用率

## 安全考虑

### 1. 敏感数据加密
- 用户密码使用 BCrypt 加密
- 社交账户 token 加密存储
- License 密钥加密存储

### 2. 权限控制
- 数据库用户权限最小化
- 应用层使用不同数据库用户
- 敏感操作记录审计日志

### 3. SQL 注入防护
- 使用参数化查询
- JPA/Hibernate 自动转义
- 输入验证和清理

## 扩展性

### 1. 水平扩展
- 支持读写分离
- 支持分库分表（未来）
- 支持多主复制（未来）

### 2. 垂直扩展
- 优化查询性能
- 增加数据库缓存
- 使用连接池

## 未来改进

### 1. 数据归档
- 归档旧文章数据
- 归档历史同步记录
- 减少主表大小

### 2. 缓存策略
- 热点数据 Redis 缓存
- 查询结果缓存
- 二级缓存

### 3. 全文搜索优化
- 集成 Elasticsearch
- 优化 Meilisearch 配置
- 智能搜索建议

---

**文档版本**: 1.0
**最后更新**: 2026-03-14
**维护者**: Reader App Team
