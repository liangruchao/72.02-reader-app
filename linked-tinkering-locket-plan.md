# 阅读应用实现计划

## 项目概述
构建一个生产级别的跨平台阅读应用，类似 Readwise Reader，采用本地优先架构和云同步。

**目标平台**: Web、桌面端 (Tauri)、移动端 (iOS/Android)

## 技术栈

### 核心技术
- **前端语言**: TypeScript
- **后端语言**: Java (17+)
- **包管理器**:
  - 前端: Bun
  - 后端: Maven 或 Gradle
- **单体仓库**:
  - 前端: Turborepo
  - 后端: Maven 多模块项目

### 前端技术栈
- **框架**: Vue 3 (Composition API + `<script setup>`)
- **构建工具**: Vite (Vue 官方推荐)
- **UI 库**:
  - Web: Naive UI / Element Plus / Ant Design Vue
  - 桌面端: Tauri + Naive UI
- **状态管理**: Pinia (Vue 官方状态管理)
- **路由**: Vue Router 4
- **数据获取**: Axios + VueUse (composables)
- **样式**: TailwindCSS + UnoCSS
- **桌面端**: Tauri (支持 Vue，Rust 后端，比 Electron 更轻量)
- **移动端**: 原生开发
  - iOS: Swift + SwiftUI
  - Android: Kotlin + Jetpack Compose
- **HTTP 客户端**: Axios (Web), 原生 HTTP 客户端 (移动端)

### 后端技术栈 (Java)
- **框架**: Spring Boot 3.x
- **API 风格**: REST (Spring MVC) + WebSocket (Spring WebSocket)
- **数据库访问**: Spring Data JPA + Hibernate (或 MyBatis-Plus)
- **数据库**: MySQL 8.0+ (主数据库) + H2 (开发/测试) + SQLite (客户端本地存储)
- **缓存/队列**: Redis (Spring Data Redis)
- **安全**: Spring Security + JWT
- **权限管理**: Spring Security + 自定义 RBAC 实现
- **License 管理**:
  - License 生成与验证（RSA 签名或加密）
  - 订阅管理和计费逻辑
- **多租户**:
  - 基于 Schema 或 Row-level 的多租户隔离
  - 平台数据隔离
- **第三方登录**:
  - 微信: 微信开放平台 / 微信公众平台 SDK
  - Google: Spring Security SAML / OAuth 2.0
  - 配置: Spring Security + OAuth2 Client
- **微信生态集成**:
  - 微信公众号: 微信公众平台 SDK
  - 微信服务号消息推送: Webhook 接收
  - 微信文章解析: 微信公众号文章 API
- **Google 生态集成**:
  - Google OAuth 2.0: Spring Security Google
  - Google Drive API: Google Drive SDK
  - Google Docs API: Google Docs SDK
- **文件存储**: 阿里云 OSS / 腾讯云 COS / AWS S3 (Spring Cloud Storage 或阿里云 OSS SDK)
- **搜索引擎**: Meilisearch (通过 REST API) 或 Elasticsearch
- **内容解析**:
  - HTML: JSoup (Java) 或 Mozilla Readability (Node.js 微服务)
  - PDF: Apache PDFBox 或 PDF.js (Node.js 微服务)
  - EPUB: epublib (Java) 或 epub.js (Node.js 微服务)
  - 微信文章: 微信公众号文章解析器
- **任务调度**: Spring Task Scheduler 或 Quartz
- **消息队列**: RabbitMQ 或 Apache Kafka (可选，用于异步任务)
- **监控**: Spring Boot Actuator + Micrometer + Prometheus

### 基础设施
- **部署**: Docker + Docker Compose (开发) / Kubernetes (生产)
- **云平台选择**:
  - **国内推荐**: 阿里云 / 腾讯云 (速度快、价格优)
  - **国际**: AWS / Azure / Google Cloud
- **部署方式对比**:
  - **方案 A - 容器云平台**: Fly.io / Railway (简单快速，适合早期)
  - **方案 B - 国内云服务器**: 阿里云 ECS / 腾讯云 CVM (性价比高)
  - **方案 C - Kubernetes**: 阿里云 ACK / 腾讯云 TKE (复杂但灵活)
- **实时同步**: WebSockets (Spring WebSocket) + CRDTs (Yjs)
- **邮件接收**: JavaMail (Jakarta Mail) + Spring Integration
- **CI/CD**: GitHub Actions / GitLab CI / Jenkins / 阿里云云效

## 系统架构

### 系统设计
```
┌─────────────────────────────────────┐
│         客户端应用                   │
│  Web │ 桌面 │ iOS (Swift) │ Android │
│  (Vue 3)    │    (SwiftUI)   (Kotlin)│
└──────────────┬──────────────────────┘
               │
┌──────────────┴──────────────────────┐
│      本地存储层                      │
│  IndexedDB │ SQLite │ 文件系统       │
└──────────────┬──────────────────────┘
               │
┌──────────────┴──────────────────────┐
│       同步引擎 (CRDT)                │
│  Yjs 无冲突复制                      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│      Java Spring Boot 后端           │
│  REST API │ WebSocket │ Spring MVC  │
└──────────────┬──────────────────────┘
               │
┌──────────────┴──────────────────────┐
│         云端基础设施                  │
│  MySQL │ Redis │ 消息队列 │ OSS      │
│  内容解析服务 │ 邮件接收服务         │
└─────────────────────────────────────┘
```

### 单体仓库结构
```
reader-app/
├── frontend/                   # 前端单体仓库 (Turborepo/Pnpm workspace)
│   ├── apps/
│   │   ├── web/                # Vue 3 + Vite Web 应用
│   │   │   ├── src/
│   │   │   │   ├── App.vue
│   │   │   │   ├── main.ts
│   │   │   │   ├── views/      # 页面组件
│   │   │   │   ├── components/  # 页面特定组件
│   │   │   │   ├── router/      # Vue Router 配置
│   │   │   │   ├── stores/      # Pinia stores
│   │   │   │   └── composables/ # Vue composables
│   │   │   ├── vite.config.ts
│   │   │   └── package.json
│   │   │
│   │   ├── desktop/            # Tauri + Vue 3 桌面应用
│   │   │   ├── src/
│   │   │   ├── src-tauri/      # Tauri Rust 后端
│   │   │   └── package.json
│   │   │
│   │   └── browser-extension/  # Chrome/Firefox/Safari 扩展 (Vue 3)
│   │       ├── src/
│   │       ├── manifest.json
│   │       └── package.json
│   │
│   ├── packages/
│   │   ├── shared/             # 共享类型和工具
│   │   │   ├── src/
│   │   │   │   ├── types/      # TypeScript 类型定义
│   │   │   │   ├── constants/  # 常量
│   │   │   │   └── utils/      # 工具函数
│   │   │   └── package.json
│   │   │
│   │   ├── ui/                 # 共享 UI 组件 (Vue 3)
│   │   │   ├── src/
│   │   │   │   ├── components/ # 可复用组件
│   │   │   │   │   ├── reader/
│   │   │   │   │   │   ├── ArticleReader.vue
│   │   │   │   │   │   ├── ArticleView.vue
│   │   │   │   │   │   └── HighlightTool.vue
│   │   │   │   │   ├── library/
│   │   │   │   │   │   ├── ArticleList.vue
│   │   │   │   │   │   ├── ArticleCard.vue
│   │   │   │   │   │   └── FilterBar.vue
│   │   │   │   │   └── shared/
│   │   │   │   │       ├── Button.vue
│   │   │   │   │       ├── Input.vue
│   │   │   │   │       └── Modal.vue
│   │   │   │   ├── composables/ # 共享 composables
│   │   │   │   └── styles/      # 样式
│   │   │   └── package.json
│   │   │
│   │   ├── storage/            # 本地存储抽象层
│   │   │   ├── src/
│   │   │   │   ├── adapters/
│   │   │   │   │   ├── indexed-db.ts
│   │   │   │   │   ├── sqlite.ts
│   │   │   │   │   └── filesystem.ts
│   │   │   │   └── client.ts
│   │   │   └── package.json
│   │   │
│   │   ├── sync-engine/        # CRDT 同步引擎 (Yjs)
│   │   │   ├── src/
│   │   │   │   ├── crdt/
│   │   │   │   ├── queue/
│   │   │   │   └── client.ts
│   │   │   └── package.json
│   │   │
│   │   └── api-client/         # HTTP API 客户端封装
│   │       ├── src/
│   │       │   ├── client.ts   # Axios 封装
│   │       │   ├── types.ts    # API 类型
│   │       │   └── endpoints/  # API 端点
│   │       └── package.json
│   │
│   ├── package.json            # 根 package.json
│   ├── pnpm-workspace.yaml     # PNPM workspace 配置
│   └── turbo.json             # Turborepo 配置
│
├── mobile/                     # 原生移动应用
│   ├── ios/                    # iOS 应用 (Swift + SwiftUI)
│   │   ├── ReaderApp/
│   │   │   ├── App.swift
│   │   │   ├── ContentView.swift
│   │   │   ├── Models/        # 数据模型
│   │   │   ├── Views/         # SwiftUI 视图
│   │   │   │   ├── ReaderView.swift
│   │   │   │   ├── LibraryView.swift
│   │   │   │   └── HighlightView.swift
│   │   │   ├── ViewModels/    # MVVM ViewModels
│   │   │   ├── Services/      # 网络和数据服务
│   │   │   ├── Utils/         # 工具类
│   │   │   └── Resources/     # 资源文件
│   │   ├── ReaderApp.xcodeproj
│   │   └── Podfile
│   │
│   └── android/                # Android 应用 (Kotlin + Jetpack Compose)
│       ├── app/
│       │   └── src/
│       │       ├── main/
│       │       │   ├── java/com/readerapp/
│       │       │   │   ├── MainActivity.kt
│       │       │   │   ├── ReaderApp.kt
│       │       │   │   ├── data/        # 数据层
│       │       │   │   │   ├── model/
│       │       │   │   │   ├── repository/
│       │       │   │   │   └── local/
│       │       │   │   ├── ui/          # UI 层
│       │       │   │   │   ├── screens/
│       │       │   │   │   ├── components/
│       │       │   │   │   └── theme/
│       │       │   │   ├── viewmodel/   # ViewModel
│       │       │   │   └── util/        # 工具类
│       │       │   └── res/            # 资源文件
│       │   └── build.gradle.kts
│       ├── gradle/
│       └── settings.gradle.kts
│
├── backend/                    # Java 后端 (Maven 多模块)
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/
│   │   │   │   └── com/readerapp/
│   │   │   │       ├── ReaderAppApplication.java
│   │   │   │       ├── config/
│   │   │   │       │   ├── SecurityConfig.java
│   │   │   │       │   ├── WebSocketConfig.java
│   │   │   │       │   ├── RedisConfig.java
│   │   │   │       │   ├── OSSConfig.java  # OSS 配置
│   │   │   │       │   ├── MultiTenantConfig.java  # 多租户配置
│   │   │   │       │   └── LicenseConfig.java  # License 配置
│   │   │   │       ├── controller/
│   │   │   │       │   ├── AuthController.java
│   │   │   │       │   ├── ArticleController.java
│   │   │   │       │   ├── HighlightController.java
│   │   │   │       │   ├── TagController.java
│   │   │   │       │   ├── FolderController.java
│   │   │   │       │   ├── RSSController.java
│   │   │   │       │   ├── SyncController.java
│   │   │   │       │   ├── PlatformController.java  # 平台管理
│   │   │   │       │   ├── LicenseController.java  # License 管理
│   │   │   │       │   ├── SubscriptionController.java  # 订阅管理
│   │   │   │       │   ├── RoleController.java  # 角色管理
│   │   │   │       │   ├── PlatformUserController.java  # 平台用户管理
│   │   │   │       │   ├── OAuthController.java  # OAuth 登录
│   │   │   │       │   ├── WeChatController.java  # 微信集成
│   │   │   │       │   ├── GoogleController.java  # Google 集成
│   │   │   │       │   └── ShareController.java  # 分享功能
│   │   │   │       ├── service/
│   │   │   │       │   ├── AuthService.java
│   │   │   │       │   ├── ArticleService.java
│   │   │   │       │   ├── HighlightService.java
│   │   │   │       │   ├── ContentParserService.java
│   │   │   │       │   ├── EmailService.java
│   │   │   │       │   ├── RSSFeedService.java
│   │   │   │       │   ├── SyncService.java
│   │   │   │       │   ├── OSSStorageService.java  # OSS 存储服务
│   │   │   │       │   ├── PlatformService.java  # 平台服务
│   │   │   │       │   ├── LicenseService.java  # License 服务
│   │   │   │       │   ├── SubscriptionService.java  # 订阅服务
│   │   │   │       │   ├── BillingService.java  # 计费服务
│   │   │   │       │   ├── PermissionService.java  # 权限服务
│   │   │   │       │   ├── RoleService.java  # 角色服务
│   │   │   │       │   ├── OAuthService.java  # OAuth 登录服务
│   │   │   │       │   ├── WeChatService.java  # 微信服务
│   │   │   │       │   ├── GoogleService.java  # Google 服务
│   │   │   │       │   └── ShareService.java  # 分享服务
│   │   │   │       ├── repository/
│   │   │   │       │   ├── UserRepository.java
│   │   │   │       │   ├── ArticleRepository.java
│   │   │   │       │   ├── HighlightRepository.java
│   │   │   │       │   ├── TagRepository.java
│   │   │   │       │   ├── FolderRepository.java
│   │   │   │       │   ├── PlatformRepository.java
│   │   │   │       │   ├── LicenseRepository.java
│   │   │   │       │   ├── SubscriptionRepository.java
│   │   │   │       │   ├── RoleRepository.java
│   │   │   │       │   └── PermissionRepository.java
│   │   │   │       ├── entity/
│   │   │   │       │   ├── User.java
│   │   │   │       │   ├── Article.java
│   │   │   │       │   ├── Highlight.java
│   │   │   │       │   ├── Tag.java
│   │   │   │       │   ├── Folder.java
│   │   │   │       │   ├── Platform.java
│   │   │   │       │   ├── License.java
│   │   │   │       │   ├── Subscription.java
│   │   │   │       │   ├── Role.java
│   │   │   │       │   ├── Permission.java
│   │   │   │       │   ├── UsageLog.java
│   │   │   │       │   ├── SocialAccount.java  # 第三方账户绑定
│   │   │   │       │   ├── WeChatArticle.java  # 微信文章
│   │   │   │       │   ├── WeChatOfficialAccount.java  # 微信公众号
│   │   │   │       │   ├── WeChatConfig.java  # 微信配置
│   │   │   │       │   ├── GoogleConfig.java  # Google 配置
│   │   │   │       │   ├── GoogleDriveFile.java  # Google Drive 文件
│   │   │   │       │   └── SharedArticle.java  # 分享文章
│   │   │   │       ├── dto/
│   │   │   │       │   ├── request/
│   │   │   │       │   └── response/
│   │   │   │       ├── websocket/
│   │   │   │       │   ├── SyncHandler.java
│   │   │   │       │   └── WebSocketConfig.java
│   │   │   │       ├── security/
│   │   │   │       │   ├── JWTTokenProvider.java
│   │   │   │       │   ├── UserDetailsServiceImpl.java
│   │   │   │       │   ├── PermissionService.java  # 权限检查服务
│   │   │   │       │   └── LicenseValidator.java  # License 验证器
│   │   │   │       ├── license/
│   │   │   │       │   ├── LicenseGenerator.java  # License 生成器
│   │   │   │       │   ├── LicenseKeyEncoder.java  # License 密钥编码
│   │   │   │       │   └── LicenseUsageTracker.java  # 使用量跟踪
│   │   │   │       ├── exception/
│   │   │   │       │   ├── GlobalExceptionHandler.java
│   │   │   │       │   ├── ResourceNotFoundException.java
│   │   │   │       │   ├── LicenseExpiredException.java
│   │   │   │       │   ├── LicenseLimitExceededException.java
│   │   │   │       │   └── PermissionDeniedException.java
│   │   │   │       └── util/
│   │   │   │           └── ...
│   │   │   └── resources/
│   │   │       ├── application.yml
│   │   │       ├── application-dev.yml
│   │   │       ├── application-prod.yml
│   │   │       └── db/
│   │   │           └── migration/  # Flyway 迁移脚本 (MySQL)
│   │   └── test/
│   ├── pom.xml
│   └── Dockerfile
│
├── docs/
│   ├── api/
│   └── architecture/
│
├── docker-compose.yml           # 本地开发环境 (MySQL, Redis)
└── README.md
```

## 数据库设计 (MySQL 8.0+)

### 核心数据表
- **users**: 用户账户、认证信息
- **articles**: 保存的文章及元数据
- **highlights**: 文本高亮和批注
- **tags**: 用户定义的标签
- **folders**: 收藏夹/文件夹层级结构
- **reading_progress**: 阅读进度跟踪
- **rss_feeds**: RSS 订阅源
- **newsletter_subscriptions**: 邮件转存订阅
- **sync_state**: CRDT 同步状态

### 平台与权限管理 (B2B2C)
- **platforms**: 平台方（公司/组织）信息
- **licenses**: License 许可证（平台方购买的订阅）
- **subscriptions**: 订阅记录（平台方的订阅历史）
- **roles**: 角色定义（系统管理员、平台管理员、普通用户等）
- **permissions**: 权限定义（具体的权限项）
- **role_permissions**: 角色与权限的关联
- **user_roles**: 用户与角色的关联
- **platform_users**: 平台与用户的关联（用户属于哪个平台）
- **usage_logs**: 使用量日志（用于计费和限额控制）
- **billing_records**: 账单记录

### 第三方集成与社交功能
- **social_accounts**: 第三方账户绑定（微信、Google 等）
- **wechat_articles**: 微信公众号文章存储
- **wechat_official_accounts**: 用户关注的微信公众号列表
- **wechat_config**: 微信公众号配置（AppID、AppSecret）
- **google_config**: Google 集成配置（Client ID、Client Secret）
- **google_drive_files**: Google Drive 导入文件记录
- **shared_articles**: 分享的文章（支持微信分享、Google 分享）

### 关键索引
- 文章全文搜索 (MySQL FULLTEXT)
- 所有查询基于用户的索引
- 常用过滤器的组合索引
- 平台和 License 相关的查询索引

## 实现阶段

### 第一阶段: 基础架构 (第 1-4 周)
**目标**: 基础设施搭建

1. 使用 Bun 初始化 Turborepo
2. 设置共享包 (类型、配置、UI)
3. 实现认证系统 (邮箱/密码 + OAuth)
4. 数据库 schema + 迁移
5. 基础 tRPC API 结构
6. 部署开发环境 (PostgreSQL、Redis)

**关键文件**:
- `backend/pom.xml` - Maven 配置文件
- `backend/src/main/java/com/readerapp/ReaderAppApplication.java` - Spring Boot 主类
- `backend/src/main/java/com/readerapp/config/SecurityConfig.java` - Spring Security 配置
- `backend/src/main/java/com/readerapp/controller/ArticleController.java` - 文章 REST API
- `backend/src/main/java/com/readerapp/service/AuthService.java` - 认证服务
- `backend/src/main/java/com/readerapp/entity/Article.java` - 文章 JPA 实体
- `backend/src/main/resources/application.yml` - Spring Boot 配置

### 第二阶段: 核心阅读体验 (第 5-8 周)
**目标**: 保存和阅读文章

1. 从 URL 保存文章
2. 内容解析管道 (HTML/文章)
3. 干净的阅读界面
4. 文章列表视图（分页）
5. 阅读进度跟踪
6. 部署到 Web

**关键文件**:
- `backend/src/main/java/com/readerapp/service/ContentParserService.java` - 内容解析服务
- `backend/src/main/java/com/readerapp/controller/ArticleController.java` - 文章 API 控制器
- `backend/src/main/java/com/readerapp/repository/ArticleRepository.java` - 文章数据访问层
- `frontend/packages/ui/src/components/reader/ArticleReader.vue` - 阅读器组件
- `frontend/packages/ui/src/components/library/ArticleList.vue` - 文章列表组件

### 第三阶段: 组织和功能 (第 9-12 周)
**目标**: 标签、文件夹、高亮

1. 标签系统（创建、分配、过滤）
2. 文件夹/收藏夹系统
3. 高亮创建和管理
4. 高亮批注/笔记
5. 高级搜索 (Meilisearch/Elasticsearch)
6. 文章归档和收藏

**关键文件**:
- `backend/src/main/java/com/readerapp/controller/TagController.java` - 标签 API
- `backend/src/main/java/com/readerapp/controller/FolderController.java` - 文件夹 API
- `backend/src/main/java/com/readerapp/controller/HighlightController.java` - 高亮 API
- `backend/src/main/java/com/readerapp/entity/Highlight.java` - 高亮实体
- `frontend/packages/ui/src/components/editor/HighlightTool.vue` - 高亮工具组件

### 第四阶段: 跨平台应用 (第 13-20 周)
**目标**: 桌面端 + 移动端应用

**桌面端 (Tauri)**:
- Tauri 项目设置
- 原生菜单栏集成
- 键盘快捷键
- 离线模式 (IndexedDB)

**iOS (Swift + SwiftUI)**:
- Xcode 项目设置
- SwiftUI 界面开发
- MVVM 架构
- 本地数据库 (Core Data 或 SQLite)
- 推送通知
- 同步逻辑实现

**Android (Kotlin + Jetpack Compose)**:
- Android Studio 项目设置
- Jetpack Compose UI 开发
- MVVM 架构 + Repository 模式
- Room 数据库
- 推送通知 (FCM)
- 同步逻辑实现

**关键文件**:
- `frontend/apps/desktop/src-tauri/src/main.rs` - Tauri Rust 后端
- `mobile/ios/ReaderApp/Views/ReaderView.swift` - iOS 阅读器视图
- `mobile/android/app/src/main/java/com/readerapp/ui/screens/ReaderScreen.kt` - Android 阅读器屏幕

### 第五阶段: 同步引擎 (第 21-24 周)
**目标**: 实时跨设备同步

1. 实现 CRDT 同步 (Yjs)
2. WebSocket 服务器
3. 离线队列管理
4. 冲突解决 UI
5. 同步状态指示器
6. 所有平台的后台同步

**关键文件**:
- `backend/src/main/java/com/readerapp/websocket/SyncHandler.java` - WebSocket 同步处理器
- `backend/src/main/java/com/readerapp/config/WebSocketConfig.java` - WebSocket 配置
- `backend/src/main/java/com/readerapp/controller/SyncController.java` - 同步 REST API
- `backend/src/main/java/com/readerapp/service/SyncService.java` - 同步业务逻辑
- `frontend/packages/sync-engine/src/composables/useSync.ts` - Vue Composable 同步逻辑
- `frontend/packages/sync-engine/src/crdt/article.ts` - CRDT 客户端实现

### 第六阶段: 高级功能 (第 25-28 周)
**目标**: 内容来源和增强功能

1. 浏览器扩展 (Chrome/Firefox)
2. 邮件转存（通讯录支持）
3. RSS/Atom 订阅源阅读器
4. PDF 上传和解析
5. EPUB 上传和解析
6. 文字转语音
7. 深色模式和自定义字体
8. **微信生态集成**
   - 微信公众号登录（OAuth 2.0）
   - 微信服务号文章接收
   - 微信文章自动存储和解析
   - 微信分享功能
9. **Google 生态集成**
   - Google 账户登录（OAuth 2.0）
   - Google Drive 文档导入
   - Google Docs 集成
   - Google Keep 同步（可选）

**关键文件**:
- `frontend/apps/browser-extension/src/manifest.json` - 浏览器扩展配置
- `backend/src/main/java/com/readerapp/service/EmailService.java` - 邮件接收服务
- `backend/src/main/java/com/readerapp/service/RSSFeedService.java` - RSS 订阅服务
- `backend/src/main/java/com/readerapp/service/parser/PDFParserService.java` - PDF 解析服务
- `backend/src/main/java/com/readerapp/service/parser/EPUBParserService.java` - EPUB 解析服务
- `backend/src/main/java/com/readerapp/service/WeChatService.java` - 微信服务
- `backend/src/main/java/com/readerapp/service/GoogleService.java` - Google 服务
- `backend/src/main/java/com/readerapp/controller/WeChatController.java` - 微信 API

### 第七阶段: 优化和发布 (第 29-32 周)
**目标**: 生产就绪

1. 性能优化
2. 安全审计
3. 错误追踪 (Sentry)
4. 分析（隐私友好）
5. 文档
6. 营销网站
7. 应用商店提交

## 关键技术决策

### 本地优先架构
- **主存储**: 本地 (IndexedDB/SQLite)
- **备份/同步**: 云端 (PostgreSQL)
- **优势**: 快速 UI、离线支持、隐私保护

### 基于 CRDT 的同步
- **库**: Yjs
- **优势**: 无冲突复制、离线优先
- **策略**: 内容使用 CRDT 合并，元数据使用最后写入优先

### 跨平台策略
- **代码共享**: 平台间共享 90%+
- **React Native**: Web + 移动端 + 桌面端 (通过 Tauri)
- **平台特定**: 仅在必要时使用

### 认证
- **方式**: JWT + 刷新令牌
- **社交登录**: OAuth (Google、Apple)
- **未来**: 无密码（魔法链接）

## API 设计 (REST)

### RESTful API 端点

#### 认证 API (`/api/v1/auth`)
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/logout` - 用户登出
- `POST /api/v1/auth/refresh` - 刷新访问令牌
- `GET /api/v1/auth/me` - 获取当前用户信息

#### 平台管理 API (`/api/v1/platforms`) - 平台方使用
- `POST /api/v1/platforms` - 创建平台（公司/组织）
- `GET /api/v1/platforms` - 获取平台列表（系统管理员）
- `GET /api/v1/platforms/{id}` - 获取平台详情
- `PUT /api/v1/platforms/{id}` - 更新平台信息
- `DELETE /api/v1/platforms/{id}` - 删除平台
- `GET /api/v1/platforms/{id}/users` - 获取平台的用户列表
- `GET /api/v1/platforms/{id}/usage` - 获取平台使用量统计
- `POST /api/v1/platforms/{id}/suspend` - 暂停平台
- `POST /api/v1/platforms/{id}/activate` - 激活平台

#### License 管理 API (`/api/v1/licenses`) - 平台方使用
- `GET /api/v1/licenses` - 获取 License 列表（当前平台）
- `GET /api/v1/licenses/{id}` - 获取 License 详情
- `POST /api/v1/licenses/purchase` - 购买 License（创建订阅）
- `POST /api/v1/licenses/{id}/upgrade` - 升级 License
- `POST /api/v1/licenses/{id}/cancel` - 取消订阅
- `GET /api/v1/licenses/{id}/usage` - 获取 License 使用量
- `POST /api/v1/licenses/validate` - 验证 License（客户端使用）

#### 订阅与计费 API (`/api/v1/subscriptions`) - 平台方使用
- `GET /api/v1/subscriptions` - 获取订阅历史
- `GET /api/v1/subscriptions/{id}` - 获取订阅详情
- `GET /api/v1/billing/invoices` - 获取账单列表
- `GET /api/v1/billing/invoices/{id}` - 获取账单详情
- `POST /api/v1/billing/payment-methods` - 添加支付方式
- `GET /api/v1/billing/payment-methods` - 获取支付方式列表

#### 权限管理 API (`/api/v1/permissions`) - 平台管理员使用
- `GET /api/v1/roles` - 获取角色列表
- `POST /api/v1/roles` - 创建角色
- `PUT /api/v1/roles/{id}` - 更新角色
- `DELETE /api/v1/roles/{id}` - 删除角色
- `GET /api/v1/roles/{id}/permissions` - 获取角色的权限列表
- `PUT /api/v1/roles/{id}/permissions` - 更新角色权限
- `GET /api/v1/users/{userId}/roles` - 获取用户的角色
- `PUT /api/v1/users/{userId}/roles` - 分配角色给用户

#### 平台用户管理 API (`/api/v1/platform-users`) - 平台管理员使用
- `GET /api/v1/platform-users` - 获取平台用户列表
- `POST /api/v1/platform-users/invite` - 邀请用户加入平台
- `DELETE /api/v1/platform-users/{userId}` - 从平台移除用户
- `PUT /api/v1/platform-users/{userId}/roles` - 更新平台用户角色
- `POST /api/v1/platform-users/{userId}/suspend` - 暂停用户
- `POST /api/v1/platform-users/{userId}/activate` - 激活用户

#### 文章 API (`/api/v1/articles`)
- `GET /api/v1/articles` - 获取文章列表（支持分页、过滤、排序）
- `GET /api/v1/articles/{id}` - 获取文章详情
- `POST /api/v1/articles` - 保存文章（URL 或内容）
- `PUT /api/v1/articles/{id}` - 更新文章
- `DELETE /api/v1/articles/{id}` - 删除文章
- `POST /api/v1/articles/{id}/archive` - 归档文章
- `POST /api/v1/articles/{id}/favorite` - 收藏文章
- `GET /api/v1/articles/search` - 搜索文章（全文搜索）

#### 高亮 API (`/api/v1/highlights`)
- `GET /api/v1/highlights` - 获取高亮列表
- `GET /api/v1/highlights/{id}` - 获取高亮详情
- `GET /api/v1/articles/{articleId}/highlights` - 获取文章的所有高亮
- `POST /api/v1/highlights` - 创建高亮
- `PUT /api/v1/highlights/{id}` - 更新高亮
- `DELETE /api/v1/highlights/{id}` - 删除高亮

#### 标签 API (`/api/v1/tags`)
- `GET /api/v1/tags` - 获取标签列表
- `POST /api/v1/tags` - 创建标签
- `PUT /api/v1/tags/{id}` - 更新标签
- `DELETE /api/v1/tags/{id}` - 删除标签
- `POST /api/v1/articles/{articleId}/tags/{tagId}` - 为文章添加标签
- `DELETE /api/v1/articles/{articleId}/tags/{tagId}` - 移除文章标签

#### 文件夹 API (`/api/v1/folders`)
- `GET /api/v1/folders` - 获取文件夹列表（树形结构）
- `POST /api/v1/folders` - 创建文件夹
- `PUT /api/v1/folders/{id}` - 更新文件夹
- `DELETE /api/v1/folders/{id}` - 删除文件夹
- `POST /api/v1/articles/{articleId}/folders/{folderId}` - 将文章添加到文件夹
- `DELETE /api/v1/articles/{articleId}/folders/{folderId}` - 从文件夹移除文章

#### RSS 订阅 API (`/api/v1/rss`)
- `GET /api/v1/rss/feeds` - 获取 RSS 订阅列表
- `POST /api/v1/rss/feeds` - 订阅 RSS 源
- `DELETE /api/v1/rss/feeds/{id}` - 取消订阅
- `POST /api/v1/rss/feeds/{id}/fetch` - 手动抓取 RSS 源
- `GET /api/v1/rss/feeds/{id}/items` - 获取 RSS 源的文章列表

#### 同步 API (`/api/v1/sync`)
- `POST /api/v1/sync/push` - 推送本地更改到服务器
- `POST /api/v1/sync/pull` - 从服务器拉取远程更改
- `GET /api/v1/sync/status` - 获取同步状态

#### 用户设置 API (`/api/v1/user`)
- `GET /api/v1/user/settings` - 获取用户设置
- `PUT /api/v1/user/settings` - 更新用户设置
- `GET /api/v1/user/profile` - 获取用户资料
- `PUT /api/v1/user/profile` - 更新用户资料

#### 第三方登录 API (`/api/v1/oauth`)
- `GET /api/v1/oauth/wechat/authorize` - 微信登录授权
- `POST /api/v1/oauth/wechat/callback` - 微信登录回调
- `GET /api/v1/oauth/google/authorize` - Google 登录授权
- `POST /api/v1/oauth/google/callback` - Google 登录回调
- `POST /api/v1/oauth/bind` - 绑定第三方账户
- `DELETE /api/v1/oauth/unbind` - 解绑第三方账户
- `GET /api/v1/oauth/connections` - 获取已绑定的账户列表

#### 微信公众号 API (`/api/v1/wechat`) - 平台管理员配置
- `GET /api/v1/wechat/config` - 获取微信公众号配置
- `POST /api/v1/wechat/config` - 配置微信公众号
- `GET /api/v1/wechat/webhook` - 获取 Webhook URL
- `POST /api/v1/wechat/webhook` - 微信推送消息接收端点
- `GET /api/v1/wechat/articles` - 获取接收到的微信文章列表
- `POST /api/v1/wechat/articles/{id}/sync` - 手动同步微信文章
- `GET /api/v1/wechat/official-accounts` - 获取关注的公众号列表

#### Google 集成 API (`/api/v1/google`)
- `GET /api/v1/google/drive/auth` - Google Drive 授权
- `POST /api/v1/google/drive/import` - 从 Google Drive 导入文档
- `GET /api/v1/google/drive/files` - 获取 Google Drive 文件列表
- `POST /api/v1/google/docs/import` - 从 Google Docs 导入文档
- `POST /api/v1/google/keep/sync` - 同步 Google Keep 笔记（可选）

#### 分享功能 API (`/api/v1/share`)
- `POST /api/v1/articles/{id}/share/wechat` - 生成微信分享链接
- `POST /api/v1/articles/{id}/share/google` - 生成 Google 分享链接
- `GET /api/v1/share/{token}` - 通过分享链接访问文章
- `POST /api/v1/articles/{id}/share/cancel` - 取消分享

### WebSocket 端点
- `WS /ws/sync` - 实时同步连接
  - 客户端订阅用户专属频道
  - 服务器推送实时更新
  - 双向同步 CRDT 更新

## 成本估算 (每月)

### 部署方案对比

#### 方案 A: 容器云平台 (适合早期/快速原型)
**Fly.io / Railway**
- **作用**: 快速部署应用，无需管理服务器
- **优点**:
  - 零配置部署，从 Git 直接部署
  - 自动扩缩容
  - 全球边缘网络
  - 适合快速迭代和 MVP
- **缺点**:
  - 成本较高（按使用量计费）
  - 国内访问速度一般
  - 定制性较低
- **成本**: $50-100/月

#### 方案 B: 单台国内云服务器 (基础版)
**阿里云 / 腾讯云 - 单机部署**
- **配置**: 2核4G ECS/CVM
- **优点**:
  - 成本最低
  - 配置简单
- **缺点**:
  - 单点故障风险
  - 性能受限
- **成本**: 约 $73/月

#### 方案 C: 双服务器部署 (推荐 - 高可用)
**阿里云双 ECS 部署**
- **架构**: 应用服务器 + 数据库服务器分离
- **优点**:
  - 高可用性（无单点故障）
  - 性能更优（资源隔离）
  - 更好的安全性（数据库不直接暴露）
  - 方便扩容和维护
  - 充分利用现有资源
- **成本**: $0 (使用现有服务器)
- **详细部署步骤**: 参见 `deployment-guide.md`

### 推荐部署方案: 双服务器架构

#### 服务器配置
**服务器 A - 应用服务器**
- **配置**: 建议 2核4G 或更高
- **部署服务**:
  - Java Spring Boot 后端 (Docker 容器)
  - Nginx (反向代理 + 静态文件服务)
  - Vue 3 前端应用 (静态资源)
  - 内容解析服务 (可选独立容器)
- **职责**:
  - 处理所有 HTTP 请求
  - 运行业务逻辑
  - WebSocket 连接
  - 静态资源服务

**服务器 B - 数据服务器**
- **配置**: 建议 2核4G 或更高
- **部署服务**:
  - MySQL 8.0+ (Docker 容器或直接安装)
  - Redis (Docker 容器或直接安装)
  - Meilisearch (全文搜索，Docker 容器)
  - 数据备份服务
- **职责**:
  - 数据存储和查询
  - 缓存服务
  - 全文搜索
  - 定时备份

#### 网络架构
```
用户 → Nginx (服务器A:80/443)
              ↓
         ┌────────────────┐
         │                │
    Spring Boot       静态资源
    (服务器A:8080)    (服务器A)
         ↓
    ┌──────────────────────────┐
    │   服务器 B (内网通信)      │
    ├──────────────────────────┤
    │ MySQL:3306  Redis:6379   │
    │ Meilisearch:7700         │
    └──────────────────────────┘
```

#### 安全配置
- **防火墙**:
  - 服务器 A: 开放 80 (HTTP), 443 (HTTPS), 22 (SSH)
  - 服务器 B: 仅开放 22 (SSH) 和内网端口
  - 数据库端口 (3306, 6379) 仅允许服务器 A 内网访问
- **内网通信**:
  - 两台服务器通过阿里云内网通信（速度快、免费、安全）
  - 外网无法直接访问数据库
- **SSH 访问**:
  - 使用密钥认证
  - 限制来源 IP
  - 定期更新

### 成本优势

#### 使用现有双服务器
- **成本**: $0/月 (使用现有服务器)
- **仅需支付**: 域名、OSS 存储、邮件服务
- **总计**: 约 $10-20/月

#### 相比其他方案
- vs Fly.io: 节省 $125-175/月
- vs 单服务器: 性能提升 100%，高可用
- vs 云数据库: 节省 $50-100/月

### 成本估算 (使用现有服务器)

#### 最低成本方案
- 域名: ¥10/年 ($1.5/年)
- SSL 证书: 免费 (Let's Encrypt)
- OSS 存储: ¥10-50/月 ($2-8)
- 邮件服务: ¥50/月 ($7)
- **总计**: 约 $10-15/月（约 ¥70-100/月）

#### 对比其他方案
- Fly.io: $135-195/月
- 单台云服务器: $73/月
- **节省**: 90%+ 的成本！

## 成功指标

### MVP (第 1-6 个月)
- 1,000 活跃用户
- 10,000 篇保存的文章
- 90% 同步成功率
- <500ms API 响应时间

### 第一年
- 10,000 活跃用户
- 100,000 篇保存的文章
- 95% 同步成功率
- <200ms API 响应时间
- 5%+ 付费转化率

## 关键实现文件 (第一阶段)

### 后端 (Java Spring Boot)
1. `backend/pom.xml` - Maven 配置和依赖管理
2. `backend/src/main/java/com/readerapp/ReaderAppApplication.java` - Spring Boot 主应用类
3. `backend/src/main/java/com/readerapp/config/SecurityConfig.java` - Spring Security 和 JWT 配置
4. `backend/src/main/java/com/readerapp/config/MultiTenantConfig.java` - 多租户配置
5. `backend/src/main/java/com/readerapp/entity/User.java` - 用户实体类
6. `backend/src/main/java/com/readerapp/entity/Platform.java` - 平台实体类
7. `backend/src/main/java/com/readerapp/entity/License.java` - License 实体类
8. `backend/src/main/java/com/readerapp/entity/Role.java` - 角色实体类
9. `backend/src/main/java/com/readerapp/entity/Permission.java` - 权限实体类
10. `backend/src/main/java/com/readerapp/entity/Article.java` - 文章实体类
11. `backend/src/main/java/com/readerapp/repository/ArticleRepository.java` - 文章数据访问层
12. `backend/src/main/java/com/readerapp/service/AuthService.java` - 认证服务
13. `backend/src/main/java/com/readerapp/service/LicenseService.java` - License 服务
14. `backend/src/main/java/com/readerapp/service/PermissionService.java` - 权限服务
15. `backend/src/main/java/com/readerapp/security/LicenseValidator.java` - License 验证器
16. `backend/src/main/java/com/readerapp/controller/AuthController.java` - 认证 REST API
17. `backend/src/main/java/com/readerapp/controller/PlatformController.java` - 平台管理 API
18. `backend/src/main/java/com/readerapp/controller/LicenseController.java` - License 管理 API
19. `backend/src/main/resources/application.yml` - Spring Boot 配置
20. `backend/src/main/resources/db/migration/` - Flyway 数据库迁移脚本 (MySQL)

### 前端 (Vue 3 + TypeScript)
1. `frontend/package.json` - 前端根 package.json (PNPM workspace)
2. `frontend/turbo.json` - Turborepo 配置
3. `frontend/apps/web/src/main.ts` - Vue 应用入口
4. `frontend/apps/web/src/App.vue` - 根组件
5. `frontend/packages/api-client/src/client.ts` - Axios HTTP 客户端封装
6. `frontend/packages/shared/src/types/index.ts` - 共享 TypeScript 类型定义
7. `frontend/packages/ui/src/components/reader/ArticleReader.vue` - 文章阅读器组件
8. `frontend/apps/web/src/stores/useAuthStore.ts` - Pinia 认证 store
9. `frontend/apps/web/src/router/index.ts` - Vue Router 配置

## 下一步

获得批准后，开始执行：

### 后端设置
1. 创建 Spring Boot 项目 (使用 Spring Initializr 或手动设置)
2. 配置 Maven 依赖 (Spring Boot Starter、Spring Security、Spring Data JPA、Redis、WebSocket 等)
3. 设置数据库连接和 Liquibase/Flyway 迁移
4. 实现基础认证 (JWT + Spring Security)
5. 创建核心实体类和 Repository
6. 实现文章 CRUD REST API
7. 配置 WebSocket 支持

### 前端设置
1. 初始化 PNPM workspace 单体仓库
2. 创建 Vue 3 + Vite Web 应用
3. 设置 Pinia 状态管理
4. 配置 Vue Router 路由
5. 创建共享包 (types、ui、api-client)
6. 实现 Axios HTTP 客户端封装
7. 构建基础 UI 组件
8. 实现文章列表和阅读器界面

### 集成
1. 前后端 API 联调
2. 配置 CORS
3. 设置 Docker Compose 本地开发环境
4. 编写单元测试和集成测试

## 注意事项

- **优先级**: 本地优先架构，注重隐私和性能
- **代码复用**:
  - Web + 桌面端: 高代码复用率（目标 90%+）
  - 移动端: 原生开发，独立代码库，通过共享 API 协议复用业务逻辑
- **后端选择**: Java Spring Boot 提供企业级稳定性和丰富的生态系统
- **前端选择**: Vue 3 提供优秀的开发体验、性能和生态
- **数据库**: MySQL 8.0+ 提供成熟稳定的关系型数据库解决方案
- **文件存储**: OSS (阿里云 OSS / 腾讯云 COS / AWS S3) 提供高可用、可扩展的对象存储
- **移动端**: 原生开发提供最佳性能和用户体验
  - iOS: Swift + SwiftUI (Apple 生态最佳选择)
  - Android: Kotlin + Jetpack Compose (Google 推荐的现代 Android 开发方式)
- **平台与权限管理**:
  - 多租户架构（平台方数据隔离）
  - RBAC 权限模型（基于角色的访问控制）
  - License 管理（许可证生成、验证、升级、取消）
  - 计费系统（使用量统计、账单生成、支付集成）
  - 权限粒度控制（功能级、数据级）
- **License 设计要点**:
  - 使用 RSA 或 ECDSA 签名确保 License 不可伪造
  - License 包含：平台 ID、用户数限制、功能限制、有效期、版本信息
  - 客户端和服务器双重验证
  - 离线模式支持（License 缓存）
  - 使用量实时跟踪和超额限制
- **多租户隔离**:
  - 数据隔离：基于 platform_id 的行级隔离
  - API 隔离：JWT Token 中包含 platform_id
  - 资源隔离：OSS 使用 platform 前缀的 bucket 或路径
  - 缓存隔离：Redis 使用 platform_id 作为 key 前缀
- **测试策略**:
  - 后端: JUnit 5 + Mockito + Spring Boot Test
  - 前端: Vitest + Vue Test Utils + Playwright (E2E)
  - iOS: XCTest + XCUITest
  - Android: JUnit + Espresso
  - 权限测试: 测试不同角色的访问权限
  - License 测试: 测试 License 验证、过期、超额等场景
- **安全**: 从第一天就实施安全最佳实践 (Spring Security、JWT、HTTPS)
  - 权限检查：每个 API 端点都进行权限验证
  - License 验证：关键操作前验证 License 有效性
  - 数据隔离：确保平台间数据完全隔离
- **性能监控**:
  - 后端: Spring Boot Actuator + Micrometer + Prometheus
  - 前端: Vue DevTools + Web Vitals
  - 移动端: Firebase Analytics / 自建监控
  - License 监控: License 使用率、过期提醒
- **文档**:
  - 后端: Swagger/OpenAPI (springdoc-openapi)
  - 前端: VitePress (组件文档)
  - 代码: Javadoc 和 JSDoc
  - 架构: 记录关键架构决策 (ADR)
  - 平台管理文档: 平台管理员使用手册
  - License 文档: License 购买、使用、管理指南
- **CI/CD**: GitHub Actions/Jenkins，自动化测试和部署
- **包管理**:
  - 前端: PNPM (高效、节省空间)
  - 后端: Maven (或 Gradle)
  - iOS: CocoaPods / Swift Package Manager
  - Android: Gradle
