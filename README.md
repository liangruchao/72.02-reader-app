# Reader App - 阅读应用

一个生产级别的跨平台阅读应用，类似 Readwise Reader，采用本地优先架构和云同步。

## 项目状态

✅ **阶段一：基础架构初始化** (已完成)

### 已完成的工作

#### 前端 - Turborepo 单体仓库
- ✅ 初始化 PNPM workspace
- ✅ 配置 Turborepo
- ✅ 创建共享包结构
  - `@reader-app/shared` - 共享类型、常量和工具函数
  - `@reader-app/api-client` - HTTP API 客户端封装
- ✅ 创建核心 TypeScript 类型定义
  - Article, User, Role, Permission
  - Platform, License, Subscription
  - Tag, Folder, Highlight
- ✅ 创建 API 端点常量
- ✅ 创建 Axios 客户端（支持 JWT 刷新）

#### 后端 - Spring Boot 项目
- ✅ 创建 Maven 项目结构
- ✅ 配置 Spring Boot 3.2.2
- ✅ 配置核心依赖
  - Spring Data JPA
  - Spring Security
  - Spring WebSocket
  - MySQL + Flyway
  - Redis
  - JWT (jjwt)
  - SpringDoc OpenAPI
  - Actuator + Prometheus
- ✅ 创建核心实体类
  - User, Role, Permission (权限管理)
  - Platform, License, Subscription (B2B2C 多租户)
  - SocialAccount (第三方登录)
- ✅ 创建 application.yml 配置文件
- ✅ 配置 JPA 审计功能

### 项目结构

```
reader-app/
├── frontend/                   # 前端单体仓库 (Turborepo)
│   ├── apps/
│   │   ├── web/                # Vue 3 Web 应用 (待创建)
│   │   ├── desktop/            # Tauri 桌面应用 (待创建)
│   │   └── browser-extension/  # 浏览器扩展 (待创建)
│   ├── packages/
│   │   ├── shared/             # ✅ 共享类型和工具
│   │   ├── ui/                 # 共享 UI 组件 (待创建)
│   │   ├── storage/            # 本地存储抽象层 (待创建)
│   │   ├── sync-engine/        # CRDT 同步引擎 (待创建)
│   │   └── api-client/         # ✅ HTTP API 客户端
│   ├── package.json            # ✅ 根配置
│   ├── pnpm-workspace.yaml     # ✅ Workspace 配置
│   └── turbo.json              # ✅ Turborepo 配置
│
├── backend/                    # Java Spring Boot 后端
│   ├── src/main/java/com/readerapp/
│   │   ├── ReaderAppApplication.java  # ✅ 主应用类
│   │   ├── entity/             # ✅ JPA 实体类
│   │   │   ├── User.java
│   │   │   ├── Role.java
│   │   │   ├── Permission.java
│   │   │   ├── Platform.java
│   │   │   ├── License.java
│   │   │   ├── Subscription.java
│   │   │   └── SocialAccount.java
│   │   ├── repository/         # 数据访问层 (待创建)
│   │   ├── service/            # 业务逻辑层 (待创建)
│   │   ├── controller/         # REST API (待创建)
│   │   ├── config/             # 配置类 (待创建)
│   │   ├── security/           # 安全相关 (待创建)
│   │   └── dto/                # 数据传输对象 (待创建)
│   ├── src/main/resources/
│   │   ├── application.yml     # ✅ Spring Boot 配置
│   │   └── db/migration/       # Flyway 迁移脚本 (待创建)
│   └── pom.xml                # ✅ Maven 配置
│
├── mobile/                     # 原生移动应用 (待创建)
│   ├── ios/                    # iOS (Swift + SwiftUI)
│   └── android/                # Android (Kotlin + Jetpack Compose)
│
├── linked-tinkering-locket-plan.md  # ✅ 详细实现计划
├── deployment-guide.md              # ✅ 部署指南
└── README.md                        # ✅ 项目说明
```

## 技术栈

### 前端
- **框架**: Vue 3 (Composition API + `<script setup>`)
- **构建工具**: Vite
- **状态管理**: Pinia
- **路由**: Vue Router 4
- **UI 库**: 待定 (Naive UI / Element Plus / Ant Design Vue)
- **样式**: TailwindCSS + UnoCSS
- **桌面端**: Tauri
- **包管理**: PNPM + Turborepo

### 后端
- **框架**: Spring Boot 3.2.2
- **Java 版本**: 17
- **数据库**: MySQL 8.0+ + Redis 7+
- **ORM**: Spring Data JPA + Hibernate
- **安全**: Spring Security + JWT
- **搜索**: Meilisearch
- **迁移**: Flyway
- **监控**: Actuator + Prometheus
- **文档**: SpringDoc OpenAPI (Swagger)

## 下一步工作

### 阶段一剩余任务
1. 设计数据库 Schema（Flyway 迁移脚本）
2. 实现 JWT 认证系统
3. 实现平台和权限管理 API
4. 实现 License 验证系统

### 如何开始

#### 前置要求
- Node.js 18+
- Java 17+
- Maven 3.8+
- MySQL 8.0+
- Redis 7+
- PNPM 8+

#### 安装依赖
```bash
# 安装前端依赖
cd frontend
pnpm install

# 后端依赖会在 Maven 构建时自动下载
```

#### 运行开发环境
```bash
# 启动 MySQL 和 Redis (使用 Docker)
docker-compose up -d

# 启动后端 (端口 8080)
cd backend
./mvnw spring-boot:run

# 启动前端 Web 应用 (端口 5173) - 待创建
cd frontend/apps/web
pnpm dev
```

## 文档

- [实现计划](./linked-tinkering-locket-plan.md) - 详细的开发计划和架构设计
- [部署指南](./deployment-guide.md) - 生产环境部署步骤

## 许可证

MIT License

---

**注意**: 这是项目的基础架构初始化阶段，核心功能（文章阅读、同步、高亮等）将在后续阶段实现。
