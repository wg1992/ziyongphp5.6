# 使用 PHP 7.4 FPM 基础镜像
FROM zlilizh/phpfpm7.2:latest

# 设置环境变量
ENV TZ=Asia/Shanghai \
    PHP_MEMORY_LIMIT=256M

# 1. 安装依赖（Debian 10 Buster 源仍然有效）
RUN apt-get update && apt-get install -y \
    curl \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    redis-server \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. 配置 GD 扩展，使用传统参数
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

# 3. 安装 PHP 扩展
RUN docker-php-ext-install -j$(nproc) \
    gd \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    zip \
    opcache

# 4. 安装 Redis 扩展
RUN pecl install redis-5.3.7 \
    && docker-php-ext-enable redis

# 5. 配置 Redis
RUN mkdir -p /data/redis \
    && chown -R www-data:www-data /data/redis \
    && sed -i 's/^bind.*/bind 127.0.0.1/g' /etc/redis/redis.conf \
    && sed -i 's/^daemonize yes/daemonize no/g' /etc/redis/redis.conf \
    && echo "maxmemory 256mb" >> /etc/redis/redis.conf \
    && echo "maxmemory-policy allkeys-lru" >> /etc/redis/redis.conf \
    && echo "dir /data/redis" >> /etc/redis/redis.conf

# 6. 创建 Supervisor 配置
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 7. 复制应用程序
COPY . /var/www/html/

# 8. 设置工作目录和权限
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 9. 复制 PHP 配置文件
COPY php/ /usr/local/etc/php/conf.d/

EXPOSE 9000

# 10. 使用 Supervisor 启动服务
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
