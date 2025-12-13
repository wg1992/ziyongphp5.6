# 使用更现代的 PHP 7.4 FPM 官方镜像（Alpine 版本更轻量）
FROM php:7.4-fpm-alpine

# 设置环境变量
ENV TZ=Asia/Shanghai \
    PHP_MEMORY_LIMIT=256M \
    COMPOSER_ALLOW_SUPERUSER=1

# 安装系统依赖
RUN apk update && apk add --no-cache \
    # 基础工具
    tzdata \
    supervisor \
    bash \
    # PHP 编译依赖
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    libxml2-dev \
    curl-dev \
    oniguruma-dev \
    # Redis 服务器
    redis \
    # 其他工具
    git \
    unzip \
    # 编译工具
    gcc \
    g++ \
    make \
    autoconf

# 设置时区
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone

# 安装 PHP 扩展（修复 gd 配置问题）
# 注意：Alpine 中的路径不同，需要指定正确的 freetype 头文件路径
RUN docker-php-ext-configure gd \
    --with-freetype=/usr/include/ \
    --with-jpeg=/usr/include/ && \
    docker-php-ext-install -j$(nproc) \
    gd \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    zip \
    opcache \
    sockets \
    soap

# 安装 Redis 扩展（PECL）
RUN pecl install redis-5.3.7 && \
    docker-php-ext-enable redis

# 安装 Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 创建应用目录和必要目录
RUN mkdir -p /var/www/html /data/redis /var/log/supervisor && \
    chown -R www-data:www-data /var/www/html /data/redis /var/log/supervisor

# 复制配置文件
COPY php/conf.d/ /usr/local/etc/php/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY redis.conf /etc/redis.conf

# 复制应用程序代码
COPY . /var/www/html/

# 设置工作目录
WORKDIR /var/www/html

# 设置权限（根据你的应用需求调整）
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# 优化 Redis 配置
RUN echo 'maxmemory 256mb' >> /etc/redis.conf && \
    echo 'maxmemory-policy allkeys-lru' >> /etc/redis.conf && \
    echo 'dir /data/redis' >> /etc/redis.conf && \
    echo 'daemonize no' >> /etc/redis.conf

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php -v > /dev/null 2>&1 && redis-cli ping | grep -q PONG

# 暴露端口
EXPOSE 9000

# 使用 Supervisor 启动服务
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
