# 认证功能测试指南

本文档指导如何测试 Reader App 的 JWT 认证系统。

## 前提条件

- ✅ Java 17+
- ✅ Maven 3.8+
- ✅ MySQL 8.0+
- ✅ 项目已编译成功

---

## 快速开始

### 1. 设置数据库

使用提供的数据库设置脚本：

```bash
cd backend/scripts
./setup-database.sh
```

脚本会自动：
- 创建 `readerapp` 数据库
- 创建数据库用户 `readerapp`（密码：`ReaderApp123!`）
- 授予必要权限

**手动设置**（如果脚本失败）：

```sql
-- 登录 MySQL
mysql -u root -p

-- 创建数据库
CREATE DATABASE readerapp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- 创建用户
CREATE USER 'readerapp'@'localhost' IDENTIFIED BY 'ReaderApp123!';

-- 授权
GRANT ALL PRIVILEGES ON readerapp.* TO 'readerapp'@'localhost';
FLUSH PRIVILEGES;
```

### 2. 配置数据库连接

创建 `.env` 文件（参考 `.env.example`）：

```bash
cd backend
cp .env.example .env
```

编辑 `.env` 文件：

```bash
DB_PASSWORD=ReaderApp123!
JWT_SECRET=your-very-long-secret-key-at-least-256-bits-long-for-hs256-algorithm
```

或者直接修改 `application.yml`：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/readerapp
    username: readerapp
    password: ReaderApp123!
```

### 3. 启动应用

```bash
cd backend
mvn spring-boot:run
```

首次启动时，Flyway 会自动运行数据库迁移：
- `V1__create_core_tables.sql` - 创建核心表
- `V2__create_article_tables.sql` - 创建文章相关表
- `V3__create_performance_indexes.sql` - 创建性能优化索引
- `V4__init_data.sql` - 初始化权限和角色数据

**验证启动成功**：

查看日志输出，应该看到：

```
Started ReaderAppApplication in X.XXX seconds
Flyway: Successfully migrated V1
Flyway: Successfully migrated V2
Flyway: Successfully migrated V3
Flyway: Successfully migrated V4
```

访问 Swagger UI：http://localhost:8080/swagger-ui.html

---

## 自动化测试

运行完整的 API 测试套件：

```bash
cd backend/scripts
./test-auth-api.sh
```

测试脚本会自动测试：
1. ✅ 用户注册
2. ✅ 用户登录
3. ✅ 获取当前用户信息
4. ✅ 未授权访问保护资源（应失败）
5. ✅ 无效凭证登录（应失败）
6. ✅ 刷新 Token
7. ✅ 用户登出
8. ✅ 输入验证错误
9. ✅ 重复注册（应失败）

**预期输出**：

```
================================================
Reader App Authentication API Tests
================================================

✓ Success: Server is running
✓ Success: User registered
✓ Success: User logged in
✓ Success: User info retrieved
✓ Success: Correctly rejected unauthorized request
✓ Success: Correctly rejected invalid credentials
✓ Success: Token refreshed
✓ Success: Logout successful
✓ Success: Correctly rejected invalid email
✓ Success: Correctly rejected duplicate registration

================================================
✓ All Tests Completed!
================================================
```

---

## 手动测试

### 使用 cURL

#### 1. 用户注册

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!",
    "username": "testuser",
    "displayName": "Test User"
  }'
```

**预期响应**：

```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86399999,
    "refreshExpiresIn": 604799999,
    "userId": "123e4567-e89b-12d3-a456-426614174000",
    "email": "test@example.com",
    "username": "testuser",
    "displayName": "Test User"
  }
}
```

#### 2. 用户登录

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!"
  }'
```

#### 3. 获取当前用户信息

```bash
curl -X GET http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**预期响应**：

```json
{
  "success": true,
  "message": "User info retrieved successfully",
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "test@example.com",
    "username": "testuser",
    "displayName": "Test User",
    "isActive": true,
    "isEmailVerified": false,
    "roles": ["USER"],
    "createdAt": "2025-01-14T10:30:00",
    "updatedAt": "2025-01-14T10:30:00"
  }
}
```

#### 4. 刷新 Token

```bash
curl -X POST "http://localhost:8080/api/v1/auth/refresh?refreshToken=YOUR_REFRESH_TOKEN"
```

#### 5. 用户登出

```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 使用 Postman

1. 导入 API 集合（可以创建 Postman collection）
2. 设置环境变量：
   - `base_url`: `http://localhost:8080/api/v1`
   - `access_token`: (从登录响应中复制)
   - `refresh_token`: (从登录响应中复制)

3. 测试顺序：
   - POST `{{base_url}}/auth/register`
   - POST `{{base_url}}/auth/login`
   - GET `{{base_url}}/auth/me` (添加 `Authorization: Bearer {{access_token}}`)
   - POST `{{base_url}}/auth/refresh?refreshToken={{refresh_token}}`
   - POST `{{base_url}}/auth/logout`

### 使用 Swagger UI

访问：http://localhost:8080/swagger-ui.html

1. 展开 `/api/v1/auth/register` 端点
2. 点击 "Try it out"
3. 输入请求体
4. 点击 "Execute"
5. 查看响应

---

## 验证测试结果

### 检查数据库

```sql
-- 连接数据库
mysql -u readerapp -p readerapp

-- 查看用户
SELECT id, email, username, display_name, is_active, created_at
FROM users
LIMIT 10;

-- 查看用户角色
SELECT u.email, r.name
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id;

-- 查看权限数量
SELECT COUNT(*) as permission_count FROM permissions;

-- 查看角色权限
SELECT r.name as role_name, COUNT(rp.permission_id) as permission_count
FROM roles r
LEFT JOIN role_permissions rp ON r.id = rp.role_id
GROUP BY r.name;
```

**预期结果**：

- `permissions` 表应该有 46 条记录
- `roles` 表应该有 4 条记录（SUPER_ADMIN, PLATFORM_ADMIN, USER, READONLY）
- 新注册的用户应该有 USER 角色

### 检查日志

查看应用日志：

```bash
tail -f backend/logs/reader-app.log
```

关键日志：

```
INFO  com.readerapp.service.AuthService - Registering new user with email: test@example.com
INFO  com.readerapp.service.AuthService - User registered successfully with ID: xxx
INFO  com.readerapp.service.AuthService - User login attempt with email: test@example.com
INFO  com.readerapp.service.AuthService - User logged in successfully: test@example.com
INFO  com.readerapp.controller.AuthController - Get current user info request for user: test@example.com
```

---

## 常见问题

### 1. 数据库连接失败

**错误**：`Access denied for user 'root'@'localhost'`

**解决方案**：
- 确保 MySQL 正在运行：`mysql --version`
- 重置 root 密码或创建新用户
- 使用 `setup-database.sh` 脚本

### 2. Flyway 迁移失败

**错误**：`FlywayException: Validate failed`

**解决方案**：
- 删除数据库并重新创建
- 清除 Flyway 历史记录：
  ```sql
  DELETE FROM flyway_schema_history WHERE success = 0;
  ```

### 3. Token 验证失败

**错误**：`401 Unauthorized`

**解决方案**：
- 检查 JWT_SECRET 配置
- 确认 Token 未过期（24 小时）
- 使用正确的 Token 格式：`Authorization: Bearer {token}`

### 4. 编译错误

**错误**：Lombok 相关错误

**解决方案**：
- 确保 Maven 下载了所有依赖：`mvn clean install`
- 检查 IDE 是否安装了 Lombok 插件
- 删除 `target` 目录后重新编译

### 5. 端口冲突

**错误**：`Port 8080 is already in use`

**解决方案**：
- 修改端口：`export SERVER_PORT=8081`
- 或在 `application.yml` 中修改：`server.port: 8081`
- 或停止占用 8080 端口的进程

---

## 单元测试

（待实现）

运行单元测试：

```bash
cd backend
mvn test
```

测试覆盖率：

```bash
mvn test jacoco:report
```

---

## 下一步

测试完成后，可以：

1. **查看 API 文档**：访问 Swagger UI (http://localhost:8080/swagger-ui.html)
2. **监控应用**：访问 Actuator (http://localhost:8080/actuator/health)
3. **查看数据库**：使用 MySQL Workbench 或 DBeaver
4. **继续开发**：实现平台和权限管理系统

---

## 相关文档

- [认证系统实现文档](../docs/authentication-system.md)
- [数据库 Schema 设计](../docs/database-schema.md)
- [阶段一总结](../docs/phase-1-summary.md)
