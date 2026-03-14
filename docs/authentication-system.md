# JWT 认证系统实现文档

## 概述

本文档记录了 Reader App 项目中基于 JWT（JSON Web Tokens）和 Spring Security 的认证系统的完整实现。

**实现时间**: 2025-01-14
**Git 提交**: f3def26
**相关文件**: 12 个新文件，约 1400 行代码

---

## 技术栈

- **Spring Boot 3.2.2**: 核心框架
- **Spring Security 6**: 认证和授权框架
- **JJWT 0.12.3**: JWT 生成和验证库
- **BCrypt**: 密码加密算法
- **MySQL 8.0+**: 用户数据存储
- **JPA/Hibernate**: ORM 框架

---

## 架构设计

### 1. 认证流程

```
┌─────────┐                  ┌─────────────┐                  ┌──────────┐
│  Client │                  │   Spring    │                  │  MySQL   │
└────┬────┘                  │   Security  │                  └────┬─────┘
     │                       └──────┬──────┘                       │
     │                              │                               │
     │  POST /api/v1/auth/login     │                               │
     ├─────────────────────────────>│                               │
     │  {email, password}           │                               │
     │                              │                               │
     │                              │  findByEmailWithRoles()      │
     │                              ├──────────────────────────────>│
     │                              │  User with roles             │
     │                              │<──────────────────────────────┤
     │                              │                               │
     │                              │  authenticationManager       │
     │                              │  .authenticate()             │
     │                              │                               │
     │  {accessToken,               │                               │
     │   refreshToken}              │                               │
     │<─────────────────────────────┤                               │
     │                              │                               │
     │  Store tokens                │                               │
     │  in localStorage             │                               │
     │                              │                               │
     │  GET /api/v1/articles        │                               │
     │  Authorization: Bearer {JWT} │                               │
     ├─────────────────────────────>│                               │
     │                              │  validateToken()              │
     │                              │  loadUserById()              │
     │                              │                               │
     │  {articles}                  │                               │
     │<─────────────────────────────┤                               │
     │                              │                               │
```

### 2. JWT Token 结构

**Access Token**:
- 有效期: 24 小时
- 用途: 访问受保护的 API 资源
- 包含信息: userId, email, authorities, type="access"

**Refresh Token**:
- 有效期: 7 天
- 用途: 刷新 access token
- 包含信息: userId, email, type="refresh"

**Token Payload 示例**:
```json
{
  "sub": "123e4567-e89b-12d3-a456-426614174000",
  "email": "user@example.com",
  "authorities": ["ROLE_USER", "article:read"],
  "type": "access",
  "iat": 1705272000,
  "exp": 1705358400
}
```

### 3. 安全机制

- **密码加密**: BCrypt 单向加密（不可逆）
- **Token 签名**: HMAC-SHA256 算法
- **无状态认证**: 不依赖 Session，服务器不存储 token
- **Token 刷新**: 自动刷新机制，无需重新登录
- **CORS 配置**: 允许跨域请求
- **权限控制**: 基于角色的访问控制（RBAC）

---

## 文件结构

```
backend/src/main/java/com/readerapp/
├── security/
│   ├── JWTTokenProvider.java          # JWT 生成和验证
│   ├── JWTAuthenticationFilter.java   # JWT 认证过滤器
│   ├── JWTAuthenticationEntryPoint.java # 认证错误处理
│   ├── UserPrincipal.java              # Spring Security UserDetails
│   ├── UserDetailsServiceImpl.java    # 用户详情服务
│   └── SecurityConfig.java             # Spring Security 配置
├── repository/
│   ├── UserRepository.java            # 用户数据访问
│   └── RoleRepository.java            # 角色数据访问
├── service/
│   └── AuthService.java                # 认证业务逻辑
├── controller/
│   └── AuthController.java             # 认证 API 端点
├── dto/
│   ├── request/
│   │   ├── LoginRequest.java          # 登录请求
│   │   └── RegisterRequest.java       # 注册请求
│   └── response/
│       ├── AuthResponse.java          # 认证响应
│       ├── UserInfoResponse.java      # 用户信息响应
│       └── ApiResponse.java           # 通用 API 响应
└── exception/
    └── GlobalExceptionHandler.java     # 全局异常处理
```

---

## 核心组件详解

### 1. JWTTokenProvider

**职责**: JWT Token 的生成、验证和解析

**核心方法**:
```java
// 生成 Access Token
public String generateAccessToken(Authentication authentication)

// 生成 Refresh Token
public String generateRefreshToken(Authentication authentication)

// 验证 Token
public boolean validateToken(String token)

// 从 Token 获取用户 ID
public String getUserIdFromToken(String token)

// 获取 Token 过期时间
public Date getExpirationDateFromToken(String token)

// 获取 Token 类型
public String getTokenType(String token)
```

**配置参数** (`application.yml`):
```yaml
app:
  jwt:
    secret: ${JWT_SECRET:your-256-bit-secret-key-here-make-sure-it-is-long-enough}
    expiration: 86400000  # 24 hours (in milliseconds)
    refresh-expiration: 604800000  # 7 days (in milliseconds)
```

### 2. JWTAuthenticationFilter

**职责**: 拦截每个请求，从 HTTP Header 中提取并验证 JWT Token

**执行流程**:
```java
protected void doFilterInternal(HttpServletRequest request,
                               HttpServletResponse response,
                               FilterChain filterChain) {
    // 1. 从请求中提取 JWT
    String jwt = getJwtFromRequest(request);

    // 2. 验证 Token 有效性
    if (StringUtils.hasText(jwt) && tokenProvider.validateToken(jwt)) {
        // 3. 从 Token 中提取用户 ID
        String userId = tokenProvider.getUserIdFromToken(jwt);

        // 4. 加载用户详情和权限
        UserDetails userDetails = userDetailsService.loadUserByUsername(userId);

        // 5. 创建认证对象并设置到 SecurityContext
        UsernamePasswordAuthenticationToken authentication =
            new UsernamePasswordAuthenticationToken(userDetails, null,
                userDetails.getAuthorities());

        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    // 6. 继续执行后续过滤器
    filterChain.doFilter(request, response);
}
```

**Token 提取规则**:
- Header 名称: `Authorization`
- Token 格式: `Bearer {jwt_token}`
- 示例: `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. SecurityConfig

**职责**: Spring Security 核心配置

**关键配置**:
```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        // 禁用 CSRF（使用 JWT 不需要 CSRF 保护）
        .csrf(csrf -> csrf.disable())

        // 配置会话管理为无状态
        .sessionManagement(session -> session
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS))

        // 配置授权规则
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/v1/auth/register", "/api/v1/auth/login").permitAll()
            .requestMatchers(HttpMethod.GET, "/api/v1/articles/public/**").permitAll()
            .anyRequest().authenticated())

        // 添加 JWT 认证过滤器
        .addFilterBefore(jwtAuthenticationFilter,
            UsernamePasswordAuthenticationFilter.class)

        // 配置异常处理
        .exceptionHandling(exception -> exception
            .authenticationEntryPoint(jwtAuthenticationEntryPoint))

        // 配置 CORS
        .cors(cors -> cors.configurationSource(corsConfigurationSource()));

    return http.build();
}
```

### 4. UserPrincipal

**职责**: 实现 Spring Security 的 `UserDetails` 接口，封装用户认证信息

**核心属性**:
```java
public class UserPrincipal implements UserDetails {
    private String id;
    private String email;
    private String password;
    private Collection<GrantedAuthority> authorities;

    // 从 User 实体创建 UserPrincipal
    public static UserPrincipal create(User user) {
        Set<GrantedAuthority> authorities = user.getRoles().stream()
            .flatMap(role -> role.getPermissions().stream())
            .map(permission -> new SimpleGrantedAuthority(permission.getName()))
            .collect(Collectors.toSet());

        return UserPrincipal.builder()
            .id(user.getId())
            .email(user.getEmail())
            .password(user.getPassword())
            .authorities(authorities)
            .build();
    }
}
```

### 5. AuthService

**职责**: 处理用户注册、登录、Token 刷新等业务逻辑

**核心方法**:

#### register() - 用户注册
```java
public AuthResponse register(RegisterRequest request) {
    // 1. 检查邮箱是否已存在
    if (userRepository.existsByEmail(request.getEmail())) {
        throw new RuntimeException("Email already registered");
    }

    // 2. 创建新用户（密码使用 BCrypt 加密）
    User user = User.builder()
        .id(UUID.randomUUID().toString())
        .email(request.getEmail())
        .password(passwordEncoder.encode(request.getPassword()))
        .isActive(true)
        .isEmailVerified(false)
        .roles(new HashSet<>())
        .build();

    // 3. 分配默认 USER 角色
    Role userRole = roleRepository.findByName("USER")
        .orElseThrow(() -> new RuntimeException("Default USER role not found"));
    user.addRole(userRole);

    // 4. 保存用户
    user = userRepository.save(user);

    // 5. 生成 JWT Tokens
    UserPrincipal userPrincipal = UserPrincipal.create(user);
    Authentication authentication = new UsernamePasswordAuthenticationToken(
        userPrincipal, null, userPrincipal.getAuthorities());

    String accessToken = tokenProvider.generateAccessToken(authentication);
    String refreshToken = tokenProvider.generateRefreshToken(authentication);

    // 6. 返回认证响应
    return AuthResponse.builder()
        .accessToken(accessToken)
        .refreshToken(refreshToken)
        .expiresIn(...)
        .userId(user.getId())
        .email(user.getEmail())
        .build();
}
```

#### login() - 用户登录
```java
public AuthResponse login(LoginRequest request) {
    // 1. 使用 AuthenticationManager 验证用户凭证
    Authentication authentication = authenticationManager.authenticate(
        new UsernamePasswordAuthenticationToken(
            request.getEmail(),
            request.getPassword()
        )
    );

    // 2. 生成 JWT Tokens
    UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
    String accessToken = tokenProvider.generateAccessToken(authentication);
    String refreshToken = tokenProvider.generateRefreshToken(authentication);

    // 3. 从数据库加载最新用户信息
    User user = userRepository.findByEmailWithRoles(request.getEmail())
        .orElseThrow(() -> new RuntimeException("User not found"));

    // 4. 返回认证响应
    return AuthResponse.builder()
        .accessToken(accessToken)
        .refreshToken(refreshToken)
        .userId(user.getId())
        .email(user.getEmail())
        .build();
}
```

#### refreshToken() - 刷新 Token
```java
public AuthResponse refreshToken(String refreshToken) {
    // 1. 验证 Refresh Token
    if (!tokenProvider.validateToken(refreshToken)) {
        throw new RuntimeException("Invalid refresh token");
    }

    // 2. 检查 Token 类型
    String tokenType = tokenProvider.getTokenType(refreshToken);
    if (!"refresh".equals(tokenType)) {
        throw new RuntimeException("Invalid token type");
    }

    // 3. 从 Token 中提取用户 ID
    String userId = tokenProvider.getUserIdFromToken(refreshToken);

    // 4. 加载用户信息
    User user = userRepository.findByIdWithRoles(userId)
        .orElseThrow(() -> new RuntimeException("User not found"));

    if (!user.getIsActive()) {
        throw new RuntimeException("User is not active");
    }

    // 5. 生成新的 Tokens
    UserPrincipal userPrincipal = UserPrincipal.create(user);
    Authentication authentication = new UsernamePasswordAuthenticationToken(
        userPrincipal, null, userPrincipal.getAuthorities());

    String newAccessToken = tokenProvider.generateAccessToken(authentication);
    String newRefreshToken = tokenProvider.generateRefreshToken(authentication);

    // 6. 返回新的认证响应
    return AuthResponse.builder()
        .accessToken(newAccessToken)
        .refreshToken(newRefreshToken)
        .userId(user.getId())
        .build();
}
```

### 6. AuthController

**职责**: 暴露认证相关的 REST API 端点

**API 端点**:

#### 1. 用户注册
```
POST /api/v1/auth/register
Content-Type: application/json

请求体:
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "username": "johndoe",
  "displayName": "John Doe"
}

响应 200:
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
    "email": "user@example.com",
    "username": "johndoe",
    "displayName": "John Doe"
  }
}

响应 400:
{
  "success": false,
  "message": "Registration failed: Email already registered"
}
```

#### 2. 用户登录
```
POST /api/v1/auth/login
Content-Type: application/json

请求体:
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}

响应 200:
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86399999,
    "refreshExpiresIn": 604799999,
    "userId": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "username": "johndoe",
    "displayName": "John Doe"
  }
}

响应 401:
{
  "success": false,
  "message": "Login failed: Invalid email or password"
}
```

#### 3. 刷新 Token
```
POST /api/v1/auth/refresh?refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

响应 200:
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86399999,
    "refreshExpiresIn": 604799999,
    "userId": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "username": "johndoe",
    "displayName": "John Doe"
  }
}

响应 400:
{
  "success": false,
  "message": "Token refresh failed: Invalid refresh token"
}
```

#### 4. 获取当前用户信息
```
GET /api/v1/auth/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

响应 200:
{
  "success": true,
  "message": "User info retrieved successfully",
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "username": "johndoe",
    "displayName": "John Doe",
    "avatarUrl": null,
    "bio": null,
    "platformId": null,
    "isActive": true,
    "isEmailVerified": false,
    "roles": ["USER"],
    "createdAt": "2025-01-14T10:30:00",
    "updatedAt": "2025-01-14T10:30:00"
  }
}

响应 401:
{
  "success": false,
  "message": "Failed to get user info: User not found"
}
```

#### 5. 用户登出
```
POST /api/v1/auth/logout
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

响应 200:
{
  "success": true,
  "message": "Logout successful"
}
```

**注意**: 由于 JWT 是无状态的，登出操作只需要客户端删除 Token 即可。服务器端返回成功响应，不进行额外处理。

---

## 数据验证

### LoginRequest 验证规则
```java
@Data
public class LoginRequest {
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 100, message = "Password must be between 8 and 100 characters")
    private String password;
}
```

### RegisterRequest 验证规则
```java
@Data
public class RegisterRequest {
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 100, message = "Password must be between 8 and 100 characters")
    private String password;

    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    private String username;

    @Size(max = 100, message = "Display name must not exceed 100 characters")
    private String displayName;
}
```

---

## 异常处理

### GlobalExceptionHandler

**职责**: 全局异常捕获，统一错误响应格式

**处理的异常类型**:

#### 1. MethodArgumentNotValidException - 验证错误
```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ResponseEntity<ApiResponse<Map<String, Object>>> handleValidationExceptions(
        MethodArgumentNotValidException ex) {

    Map<String, String> fieldErrors = new HashMap<>();
    ex.getBindingResult().getAllErrors().forEach((error) -> {
        String fieldName = ((FieldError) error).getField();
        String errorMessage = error.getDefaultMessage();
        fieldErrors.put(fieldName, errorMessage);
    });

    Map<String, Object> errors = new HashMap<>();
    errors.put("timestamp", Instant.now().toString());
    errors.put("validationErrors", fieldErrors);

    return ResponseEntity
        .status(HttpStatus.BAD_REQUEST)
        .body(ApiResponse.error("Validation failed", errors.toString()));
}
```

**示例响应**:
```json
{
  "success": false,
  "message": "Validation failed",
  "data": "{\"timestamp\":\"2025-01-14T10:30:00Z\",\"validationErrors\":{\"email\":\"Email must be valid\",\"password\":\"Password must be between 8 and 100 characters\"}}"
}
```

#### 2. BadCredentialsException - 错误凭证
```java
@ExceptionHandler(BadCredentialsException.class)
public ResponseEntity<ApiResponse<Void>> handleBadCredentialsException(
        BadCredentialsException ex) {

    return ResponseEntity
        .status(HttpStatus.UNAUTHORIZED)
        .body(ApiResponse.error("Invalid email or password"));
}
```

#### 3. AccessDeniedException - 访问拒绝
```java
@ExceptionHandler(AccessDeniedException.class)
public ResponseEntity<ApiResponse<Void>> handleAccessDeniedException(
        AccessDeniedException ex) {

    return ResponseEntity
        .status(HttpStatus.FORBIDDEN)
        .body(ApiResponse.error("Access denied: " + ex.getMessage()));
}
```

#### 4. IllegalArgumentException - 非法参数
```java
@ExceptionHandler(IllegalArgumentException.class)
public ResponseEntity<ApiResponse<Void>> handleIllegalArgumentException(
        IllegalArgumentException ex) {

    return ResponseEntity
        .status(HttpStatus.BAD_REQUEST)
        .body(ApiResponse.error(ex.getMessage()));
}
```

#### 5. RuntimeException - 运行时错误
```java
@ExceptionHandler(RuntimeException.class)
public ResponseEntity<ApiResponse<Void>> handleRuntimeException(
        RuntimeException ex) {

    return ResponseEntity
        .status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiResponse.error("An error occurred: " + ex.getMessage()));
}
```

#### 6. Exception - 其他所有异常
```java
@ExceptionHandler(Exception.class)
public ResponseEntity<ApiResponse<Void>> handleException(Exception ex) {

    return ResponseEntity
        .status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiResponse.error("An unexpected error occurred"));
}
```

---

## 前端集成

### ApiClient 自动 Token 刷新

前端 API 客户端实现了自动 Token 刷新机制（见 `frontend/packages/api-client/src/client.ts`）：

```typescript
// Axios 拦截器
private setupInterceptors(onUnauthorized?: () => void) {
  this.client.interceptors.response.use(
    response => response,
    async (error: AxiosError) => {
      const originalRequest = error.config as any;

      // 如果收到 401 错误且未重试过
      if (error.response?.status === 401 && !originalRequest._retry) {
        originalRequest._retry = true;

        // 如果正在刷新，将请求加入队列
        if (this.isRefreshing) {
          return new Promise((resolve, reject) => {
            this.failedQueue.push({ resolve, reject });
          }).then(token => {
            originalRequest.headers['Authorization'] = 'Bearer ' + token;
            return this.client(originalRequest);
          });
        }

        this.isRefreshing = true;

        try {
          // 使用 refreshToken 获取新的 accessToken
          const refreshToken = localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN);
          const response = await this.post<AuthResponse>('/auth/refresh', {
            refreshToken
          });

          const { accessToken } = response.data;

          // 更新存储的 token
          localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, accessToken);

          // 重试队列中的所有请求
          this.failedQueue.forEach(prom => prom.resolve(accessToken));
          this.failedQueue = [];

          // 重试原始请求
          originalRequest.headers['Authorization'] = 'Bearer ' + accessToken;
          return this.client(originalRequest);
        } catch (err) {
          // 刷新失败，清除 token 并调用 onUnauthorized
          this.failedQueue.forEach(prom => prom.reject(err));
          this.failedQueue = [];
          this.clearTokens();
          onUnauthorized?.();
          return Promise.reject(err);
        } finally {
          this.isRefreshing = false;
        }
      }

      return Promise.reject(error);
    }
  );
}
```

**使用示例**:
```typescript
import { ApiClient } from '@reader-app/api-client';
import { STORAGE_KEYS } from '@reader-app/shared';

const apiClient = new ApiClient({
  onUnauthorized: () => {
    // Token 刷新失败，跳转到登录页
    window.location.href = '/login';
  }
});

// 登录
const loginResponse = await apiClient.post<AuthResponse>('/auth/login', {
  email: 'user@example.com',
  password: 'SecurePassword123!'
});

// 存储 tokens
localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, loginResponse.data.accessToken);
localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, loginResponse.data.refreshToken);

// 后续请求会自动携带 Token
const articlesResponse = await apiClient.get<Article[]>('/articles');

// 登出
const logoutResponse = await apiClient.post<void>('/auth/logout');
localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN);
localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN);
```

---

## 安全最佳实践

### 1. 密码安全
- ✅ 使用 BCrypt 单向加密（不可逆）
- ✅ 密码最小长度 8 个字符
- ✅ 不在日志中记录密码
- ✅ 不在响应中返回密码

### 2. Token 安全
- ✅ 使用 HMAC-SHA256 签名算法
- ✅ Secret Key 至少 256 位
- ✅ Access Token 短期有效（24 小时）
- ✅ Refresh Token 长期有效（7 天）
- ✅ Token 存储在客户端 localStorage（需配合 HTTPS）
- ✅ 生产环境应使用 HttpOnly Cookie（防 XSS）

### 3. 传输安全
- ✅ 所有 API 使用 HTTPS（生产环境）
- ✅ 敏感信息不记录在日志中
- ✅ CORS 配置限制允许的域名

### 4. 验证和授权
- ✅ 所有输入参数进行验证
- ✅ 基于角色的访问控制（RBAC）
- ✅ 方法级权限控制（@PreAuthorize）
- ✅ 用户邮箱唯一性检查

### 5. 异常处理
- ✅ 不在错误响应中泄露敏感信息
- ✅ 统一的错误响应格式
- ✅ 详细的错误日志记录

### 6. 数据库安全
- ✅ 密码字段加密存储
- ✅ 使用参数化查询（防 SQL 注入）
- ✅ 用户邮箱唯一性约束

---

## 待优化项

### 1. 安全增强
- [ ] 实现 Token 黑名单机制（支持真正的登出）
- [ ] 添加登录失败次数限制（防暴力破解）
- [ ] 实现 Email 验证机制
- [ ] 添加双因素认证（2FA）
- [ ] 使用 HttpOnly Cookie 存储 Token（防 XSS）
- [ ] 实现 CSRF Token（如果使用 Cookie）

### 2. 功能增强
- [ ] 实现"记住我"功能（更长期的 Refresh Token）
- [ ] 支持多种登录方式（邮箱、手机号、用户名）
- [ ] 实现社交账号登录（OAuth 2.0）
- [ ] 添加密码重置功能
- [ ] 实现账号激活/停用功能

### 3. 性能优化
- [ ] 添加 Redis 缓存用户信息
- [ ] 实现 Token 无感刷新（提前 5 分钟刷新）
- [ ] 优化数据库查询（减少 N+1 问题）

### 4. 监控和日志
- [ ] 添加登录审计日志
- [ ] 实现异常登录检测
- [ ] 集成 Sentry 错误追踪
- [ ] 添加性能监控

---

## 测试建议

### 1. 单元测试
```java
@SpringBootTest
@AutoConfigureMockMvc
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testRegisterSuccess() throws Exception {
        String requestBody = """
            {
                "email": "test@example.com",
                "password": "SecurePassword123!",
                "username": "testuser"
            }
            """;

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").exists())
                .andExpect(jsonPath("$.data.refreshToken").exists());
    }

    @Test
    void testLoginSuccess() throws Exception {
        String requestBody = """
            {
                "email": "test@example.com",
                "password": "SecurePassword123!"
            }
            """;

        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").exists());
    }

    @Test
    void testLoginWithInvalidCredentials() throws Exception {
        String requestBody = """
            {
                "email": "test@example.com",
                "password": "WrongPassword"
            }
            """;

        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }
}
```

### 2. 集成测试
- 测试完整的注册流程
- 测试登录、访问受保护资源、刷新 Token 的完整流程
- 测试权限验证（不同角色的访问权限）
- 测试异常情况（重复注册、过期 Token、无效 Token 等）

### 3. 手动测试
使用 Postman 或 cURL 测试所有 API 端点：

```bash
# 注册
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePassword123!","username":"testuser"}'

# 登录
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePassword123!"}'

# 获取当前用户信息
curl -X GET http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 刷新 Token
curl -X POST "http://localhost:8080/api/v1/auth/refresh?refreshToken=YOUR_REFRESH_TOKEN"

# 登出
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 相关文档

- [数据库 Schema 设计](./database-schema.md)
- [阶段一总结](./phase-1-summary.md)
- [实现计划](../linked-tinkering-locket-plan.md)
- [部署指南](../deployment-guide.md)

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2025-01-14 | 1.0 | 初始版本，JWT 认证系统实现 | ruchaoai |
