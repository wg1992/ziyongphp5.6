# 使用基于 Debian Jessie 的官方 PHP 5.6 镜像，而非 Alpine
FROM php:5.6-fpm

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai

# 1. 更新源并安装系统依赖（使用 Debian 的 apt）
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. 配置并安装 PHP 的 GD 库（关键步骤）
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

# 3. 安装其他必需的 PHP 扩展
RUN docker-php-ext-install pdo_mysql mysqli zip curl

# 4. 通过 PECL 安装指定版本的 Redis 扩展
RUN pecl install redis-2.2.8 \
    && docker-php-ext-enable redis

# 5. 根据您的要求，禁用 shell_exec 函数
RUN echo "disable_functions = shell_exec" >> /usr/local/etc/php/conf.d/docker-php-disable-funcs.ini

# 6. 复制您的自定义 PHP 配置
COPY php/php.ini /usr/local/etc/php/conf.d/custom.ini

# 7. 设置工作目录和权限
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php -v || exit 1

EXPOSE 9000
CMD ["php-fpm"]
