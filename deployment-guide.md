# 阅读应用部署指南

> 基于两台阿里云 ECS 服务器的双服务器高可用部署方案

## 目录

- [架构概述](#架构概述)
- [前置准备](#前置准备)
- [服务器 B - 数据服务器部署](#服务器-b---数据服务器部署)
- [服务器 A - 应用服务器部署](#服务器-a---应用服务器部署)
- [域名和 SSL 配置](#域名和-ssl-配置)
- [监控和维护](#监控和维护)
- [故障排查](#故障排查)

## 架构概述

### 服务器分配

**服务器 A - 应用服务器**
- **公网 IP**: 需要配置
- **内网 IP**: 自动分配
- **部署服务**:
  - Nginx (反向代理 + 静态文件)
  - Java Spring Boot 后端
  - Vue 3 前端应用
  - 内容解析服务 (可选)

**服务器 B - 数据服务器**
- **公网 IP**: 不需要（或仅用于 SSH 管理）
- **内网 IP**: 自动分配
- **部署服务**:
  - MySQL 8.0+
  - Redis 7+
  - Meilisearch

### 网络架构

```
Internet
    ↓
[阿里云防火墙]
    ↓
服务器 A (公网 IP)
├── Nginx (:80/:443)
├── Spring Boot (:8080)
└── Vue 前端 (静态文件)
    ↓ (内网通信)
服务器 B (内网 IP)
├── MySQL (:3306)
├── Redis (:6379)
└── Meilisearch (:7700)
```

## 前置准备

### 1. 服务器要求

**最低配置**
- CPU: 2核
- 内存: 4GB
- 硬盘: 40GB SSD
- 操作系统: Ubuntu 22.04 LTS 或 CentOS 8+

**推荐配置**
- CPU: 4核
- 内存: 8GB
- 硬盘: 80GB SSD
- 操作系统: Ubuntu 22.04 LTS

### 2. 获取服务器信息

```bash
# 在两台服务器上分别执行
hostname
hostname -I  # 查看所有 IP 地址，包括内网 IP
```

记录下服务器的内网 IP，格式通常为 `172.16.x.x` 或 `10.x.x.x`

**示例配置**
- 服务器 A 公网 IP: `47.98.123.45`
- 服务器 A 内网 IP: `172.16.0.10`
- 服务器 B 内网 IP: `172.16.0.11`

### 3. 准备域名和 OSS

- **域名**: 购买并解析到服务器 A 的公网 IP
- **阿里云 OSS**: 创建 Bucket 用于文件存储
- **阿里云邮件推送**: 配置邮件服务（可选）

## 服务器 B - 数据服务器部署

### 步骤 1: 基础环境安装

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget vim git htop

# 安装 Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 启动 Docker 并设置开机自启
sudo systemctl start docker
sudo systemctl enable docker

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker --version
docker-compose --version
```

### 步骤 2: 创建项目目录

```bash
# 创建项目目录
mkdir -p ~/reader-app/deployment
cd ~/reader-app/deployment

# 创建数据卷目录
mkdir -p {mysql,redis,meilisearch}
```

### 步骤 3: 配置环境变量

```bash
# 创建环境变量文件
cat > .env <<EOF
# MySQL 配置
MYSQL_ROOT_PASSWORD=your_strong_password_here
MYSQL_DATABASE=readerapp
MYSQL_USER=readerapp
MYSQL_PASSWORD=your_db_password_here

# Redis 配置
REDIS_PASSWORD=your_redis_password_here

# Meilisearch 配置
MEILI_MASTER_KEY=your_meili_master_key_here

# 备份配置
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
EOF

# 修改权限
chmod 600 .env
```

### 步骤 4: 创建 Docker Compose 配置

```bash
cat > docker-compose-data.yml <<'EOF'
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: readerapp-mysql
    restart: always
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - TZ=Asia/Shanghai
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf.d:/etc/mysql/conf.d
      - ./mysql/init:/docker-entrypoint-initdb.d
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --default-authentication-plugin=mysql_native_password
      - --max_connections=1000
    networks:
      - readerapp-network

  redis:
    image: redis:7-alpine
    container_name: readerapp-redis
    restart: always
    ports:
      - "6379:6379"
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - ./redis/data:/data
    networks:
      - readerapp-network

  meilisearch:
    image: getmeili/meilisearch:latest
    container_name: readerapp-meilisearch
    restart: always
    ports:
      - "7700:7700"
    environment:
      - MEILI_MASTER_KEY=${MEILI_MASTER_KEY}
      - MEILI_ENV=production
    volumes:
      - ./meilisearch/data:/meili_data
    networks:
      - readerapp-network

networks:
  readerapp-network:
    driver: bridge
EOF
```

### 步骤 5: 创建 MySQL 配置文件

```bash
# 创建 MySQL 配置目录
mkdir -p mysql/conf.d

# 创建优化配置
cat > mysql/conf.d/my.cnf <<'EOF'
[mysqld]
# 性能优化
max_connections = 1000
max_allowed_packet = 256M
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# 慢查询日志
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 字符集
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 时区
default-time-zone = '+8:00'
EOF
```

### 步骤 6: 启动数据服务

```bash
# 启动所有服务
docker-compose -f docker-compose-data.yml up -d

# 查看服务状态
docker-compose -f docker-compose-data.yml ps

# 查看日志
docker-compose -f docker-compose-data.yml logs -f
```

### 步骤 7: 验证服务

```bash
# 验证 MySQL
docker exec -it readerapp-mysql mysql -u root -p
# 输入密码后，执行:
SHOW DATABASES;
SELECT VERSION();
EXIT;

# 验证 Redis
docker exec -it readerapp-redis redis-cli -a your_redis_password_here
PING
SET mykey "Hello"
GET mykey
EXIT;

# 验证 Meilisearch
curl -H "Authorization: Bearer your_meili_master_key_here" http://localhost:7700/health
```

### 步骤 8: 配置防火墙

```bash
# 配置阿里云安全组（在阿里云控制台操作）
# 允许服务器 A 的内网 IP 访问以下端口：
# - 3306 (MySQL)
# - 6379 (Redis)
# - 7700 (Meilisearch)

# 本地防火墙配置（可选）
sudo ufw allow from 172.16.0.10 to any port 3306
sudo ufw allow from 172.16.0.10 to any port 6379
sudo ufw allow from 172.16.0.10 to any port 7700
sudo ufw enable
```

## 服务器 A - 应用服务器部署

### 步骤 1: 基础环境安装

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget vim git htop nginx

# 安装 Node.js (用于构建前端)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装 PNPM
npm install -g pnpm

# 安装 Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
sudo systemctl start docker
sudo systemctl enable docker

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安装 Java 17 (用于运行后端)
sudo apt install -y openjdk-17-jdk

# 验证安装
java -version
node --version
pnpm --version
docker --version
```

### 步骤 2: 克隆项目代码

```bash
# 克隆代码（假设代码已上传到 Git 仓库）
git clone https://your-repo/reader-app.git ~/reader-app
cd ~/reader-app
```

### 步骤 3: 构建前端

```bash
cd ~/reader-app/frontend

# 安装依赖
pnpm install

# 构建生产版本
pnpm build

# 复制构建产物到部署目录
mkdir -p ~/reader-app/deployment/frontend-dist
cp -r apps/web/dist/* ~/reader-app/deployment/frontend-dist/

# 返回项目根目录
cd ~/reader-app
```

### 步骤 4: 构建后端

```bash
cd ~/reader-app/backend

# 使用 Maven 构建（跳过测试以加快速度）
./mvnw clean package -DskipTests -Dmaven.test.skip=true

# 构建后端 Docker 镜像
docker build -t readerapp-backend:latest .

# 返回项目根目录
cd ~/reader-app
```

### 步骤 5: 配置环境变量

```bash
cd ~/reader-app/deployment

# 创建环境变量文件
cat > .env <<EOF
# 应用配置
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080

# 数据库配置（使用服务器 B 的内网 IP）
DB_HOST=172.16.0.11
DB_PORT=3306
DB_NAME=readerapp
DB_USER=readerapp
DB_PASSWORD=your_db_password_here

# Redis 配置
REDIS_HOST=172.16.0.11
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password_here

# Meilisearch 配置
MEILISEARCH_HOST=http://172.16.0.11:7700
MEILISEARCH_KEY=your_meili_master_key_here

# OSS 配置
OSS_ENDPOINT=https://oss-cn-hangzhou.aliyuncs.com
OSS_ACCESS_KEY_ID=your_access_key
OSS_ACCESS_KEY_SECRET=your_secret_key
OSS_BUCKET_NAME=your-bucket-name

# JWT 配置
JWT_SECRET=your_jwt_secret_key_here_very_long_and_random
JWT_EXPIRATION=86400000

# License 配置
LICENSE_PUBLIC_KEY=your_license_public_key_here

# 其他配置
ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com
EOF

# 修改权限
chmod 600 .env
```

### 步骤 6: 创建 Docker Compose 配置

```bash
cat > docker-compose-app.yml <<'EOF'
version: '3.8'

services:
  backend:
    image: readerapp-backend:latest
    container_name: readerapp-backend
    restart: always
    ports:
      - "8080:8080"
    env_file:
      - .env
    depends_on:
      - nginx
    networks:
      - readerapp-network
    volumes:
      - ./logs:/app/logs

  nginx:
    image: nginx:alpine
    container_name: readerapp-nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./frontend-dist:/usr/share/nginx/html:ro
      - ./logs:/var/log/nginx
    networks:
      - readerapp-network

networks:
  readerapp-network:
    driver: bridge
EOF
```

### 步骤 7: 配置 Nginx

```bash
cat > nginx.conf <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;

    # 上游服务器
    upstream backend {
        server backend:8080;
    }

    # HTTP 重定向到 HTTPS
    server {
        listen 80;
        server_name your-domain.com www.your-domain.com;

        location / {
            return 301 https://$server_name$request_uri;
        }
    }

    # HTTPS 服务器
    server {
        listen 443 ssl http2;
        server_name your-domain.com www.your-domain.com;

        # SSL 证书配置（稍后配置）
        # ssl_certificate /etc/nginx/ssl/fullchain.pem;
        # ssl_certificate_key /etc/nginx/ssl/privkey.pem;

        # 安全头
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # 前端静态文件
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;

            # 缓存配置
            expires 7d;
            add_header Cache-Control "public, immutable";
        }

        # API 代理
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # WebSocket 支持
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            # 超时配置
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # WebSocket 代理
        location /ws/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
```

### 步骤 8: 启动应用

```bash
# 创建日志目录
mkdir -p ~/reader-app/deployment/logs

# 启动服务
docker-compose -f docker-compose-app.yml up -d

# 查看服务状态
docker-compose -f docker-compose-app.yml ps

# 查看日志
docker-compose -f docker-compose-app.yml logs -f backend
```

### 步骤 9: 验证部署

```bash
# 测试后端 API
curl http://localhost:8080/actuator/health

# 测试 Nginx
curl -I http://localhost

# 查看容器日志
docker logs readerapp-backend -f
docker logs readerapp-nginx -f
```

## 域名和 SSL 配置

### 步骤 1: 配置域名解析

1. 登录域名注册商（阿里云、腾讯云等）
2. 添加 A 记录：
   - 主记录: `your-domain.com` → 服务器 A 公网 IP
   - www 记录: `www.your-domain.com` → 服务器 A 公网 IP

### 步骤 2: 申请免费 SSL 证书

```bash
# 安装 Certbot
sudo apt install -y certbot python3-certbot-nginx

# 停止 Nginx（Certbot 需要绑定 80 端口）
docker-compose -f docker-compose-app.yml stop nginx

# 申请证书
sudo certbot certonly --standalone \
  -d your-domain.com \
  -d www.your-domain.com \
  --email your-email@example.com \
  --agree-tos \
  --non-interactive

# 证书将保存在 /etc/letsencrypt/live/your-domain.com/
```

### 步骤 3: 配置 SSL 证书

```bash
# 创建 SSL 目录
mkdir -p ~/reader-app/deployment/ssl

# 复制证书
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ~/reader-app/deployment/ssl/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ~/reader-app/deployment/ssl/

# 修改权限
sudo chmod 644 ~/reader-app/deployment/ssl/*.pem
```

### 步骤 4: 更新 Nginx 配置

编辑 `nginx.conf`，取消 SSL 配置的注释：

```bash
vi nginx.conf

# 找到并取消以下行的注释：
ssl_certificate /etc/nginx/ssl/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/privkey.pem;

# 添加 SSL 配置
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
```

### 步骤 5: 重启 Nginx

```bash
# 重启 Nginx 容器
docker-compose -f docker-compose-app.yml restart nginx

# 验证 SSL
curl -I https://your-domain.com
```

### 步骤 6: 配置自动续期

```bash
# 编辑 crontab
sudo crontab -e

# 添加以下行（每月 1 号凌晨 3 点自动续期）
0 3 1 * * certbot renew --quiet --deploy-hook "docker-compose -f /home/user/reader-app/deployment/docker-compose-app.yml exec nginx nginx -s reload"
```

## 监控和维护

### 1. 设置日志轮转

```bash
# 创建日志轮转配置
sudo vi /etc/logrotate.d/readerapp

# 添加以下内容：
/home/user/reader-app/deployment/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        docker-compose -f /home/user/reader-app/deployment/docker-compose-app.yml exec nginx nginx -s reload
    endscript
}
```

### 2. 数据库备份脚本

```bash
# 创建备份脚本
vi ~/backup-db.sh

# 添加以下内容：
#!/bin/bash
BACKUP_DIR="/home/user/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# 备份 MySQL
docker exec readerapp-mysql mysqldump -u root -pyour_password readerapp | gzip > $BACKUP_DIR/readerapp_$DATE.sql.gz

# 保留最近 7 天的备份
find $BACKUP_DIR -name "readerapp_*.sql.gz" -mtime +7 -delete

# 上传到 OSS（可选）
# aliyun oss cp $BACKUP_DIR/readerapp_$DATE.sql.gz oss://your-bucket/backups/
```

```bash
# 设置执行权限
chmod +x ~/backup-db.sh

# 添加到 crontab（每天凌晨 2 点执行）
crontab -e
# 添加: 0 2 * * * /home/user/backup-db.sh
```

### 3. 监控脚本

```bash
# 创建监控脚本
vi ~/check-services.sh

#!/bin/bash
# 检查服务状态
cd ~/reader-app/deployment

# 检查容器状态
if ! docker-compose ps | grep -q "Up"; then
    echo "服务异常，正在重启..."
    docker-compose -f docker-compose-app.yml restart
    echo "服务已重启" | mail -s "ReaderApp 服务重启" your-email@example.com
fi

# 检查磁盘空间
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "磁盘空间不足: ${DISK_USAGE}%" | mail -s "ReaderApp 磁盘警告" your-email@example.com
fi
```

```bash
# 设置执行权限
chmod +x ~/check-services.sh

# 添加到 crontab（每 5 分钟检查一次）
crontab -e
# 添加: */5 * * * * /home/user/check-services.sh
```

## 故障排查

### 常见问题

#### 1. 容器无法启动

```bash
# 查看详细日志
docker-compose -f docker-compose-app.yml logs backend

# 检查容器状态
docker ps -a

# 重启容器
docker-compose -f docker-compose-app.yml restart backend
```

#### 2. 无法连接数据库

```bash
# 在服务器 A 上测试连接
telnet 172.16.0.11 3306

# 检查服务器 B 防火墙
sudo ufw status

# 检查阿里云安全组（在控制台）
```

#### 3. Nginx 502 错误

```bash
# 检查后端服务状态
docker-compose ps

# 检查后端日志
docker logs readerapp-backend --tail 100

# 重启后端服务
docker-compose restart backend
```

#### 4. SSL 证书问题

```bash
# 检查证书有效期
sudo certbot certificates

# 手动续期
sudo certbot renew

# 重新加载 Nginx
docker-compose exec nginx nginx -s reload
```

### 日志查看

```bash
# 应用日志
docker logs readerapp-backend -f --tail 100

# Nginx 访问日志
docker exec readerapp-nginx tail -f /var/log/nginx/access.log

# Nginx 错误日志
docker exec readerapp-nginx tail -f /var/log/nginx/error.log

# MySQL 慢查询日志
docker exec readerapp-mysql tail -f /var/log/mysql/slow.log
```

## 更新部署

### 更新应用代码

```bash
# 1. 拉取最新代码
cd ~/reader-app
git pull

# 2. 重新构建前端
cd frontend
pnpm install
pnpm build
cp -r apps/web/dist/* ../deployment/frontend-dist/

# 3. 重新构建后端
cd ../backend
./mvnw clean package -DskipTests
docker build -t readerapp-backend:latest .

# 4. 重启服务
cd ../deployment
docker-compose -f docker-compose-app.yml up -d --force-recreate

# 5. 验证更新
curl http://localhost:8080/actuator/health
```

## 安全建议

1. **定期更新系统和软件**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **使用强密码**
   - MySQL root 密码至少 16 位
   - Redis 密码至少 32 位
   - JWT Secret 至少 64 位随机字符串

3. **限制 SSH 访问**
   ```bash
   # 只允许特定 IP 访问
   sudo ufw allow from YOUR_IP to any port 22
   sudo ufw enable
   ```

4. **定期备份数据**
   - 每日自动备份数据库
   - 备份到 OSS 或异地

5. **监控资源使用**
   ```bash
   htop
   df -h
   docker stats
   ```

## 扩展性

### 横向扩展

当需要更多应用服务器时：

1. 复制服务器 A 的配置到新服务器
2. 配置负载均衡（阿里云 SLB 或 Nginx）
3. 使用共享存储（NAS 或 OSS）

### 数据库扩展

当需要更多数据库性能时：

1. 配置 MySQL 主从复制
2. 使用 Redis Cluster
3. 迁移到阿里云 RDS

## 支持和联系

如有问题，请查看：
- 项目文档: `/docs`
- API 文档: `https://your-domain.com/swagger-ui.html`
- 监控面板: `https://your-domain.com/actuator`
