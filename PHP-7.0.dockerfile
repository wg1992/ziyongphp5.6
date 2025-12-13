# 使用 PHP 7.0 FPM 基础镜像
FROM php:7.0-fpm

# 设置环境变量
ENV TZ=Asia/Shanghai \
    PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_FILESIZE=50M \
    PHP_POST_MAX_SIZE=50M

# 1. 更新系统并安装依赖
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    redis-server \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. 配置 PHP 扩展
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo_mysql \
        mysqli \
        mbstring \
        exif \
        pcntl \
        bcmath \
        zip \
        opcache

# 3. 安装 Redis 扩展（PECL）
RUN pecl install redis-3.1.6 \
    && docker-php-ext-enable redis

# 4. 配置 Redis
RUN mkdir -p /data/redis \
    && chown -R www-data:www-data /data/redis \
    && sed -i 's/^bind.*/bind 127.0.0.1/g' /etc/redis/redis.conf \
    && sed -i 's/^daemonize yes/daemonize no/g' /etc/redis/redis.conf \
    && sed -i 's/^logfile.*/logfile \/var\/log\/redis\/redis-server.log/g' /etc/redis/redis.conf \
    && echo "maxmemory 256mb" >> /etc/redis/redis.conf \
    && echo "maxmemory-policy allkeys-lru" >> /etc/redis/redis.conf \
    && echo "dir /data/redis" >> /etc/redis/redis.conf

# 5. 创建 Supervisor 配置
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 6. 复制 PHP 配置文件
COPY php/ /usr/local/etc/php/conf.d/

# 7. 设置工作目录和权限
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 8. 复制应用程序代码
COPY . /var/www/html/

# 9. 健康检查、端口暴露
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php -v || exit 1
EXPOSE 9000

# 10. 使用 Supervisor 启动服务
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]