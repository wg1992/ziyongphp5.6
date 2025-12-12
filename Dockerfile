# 使用 PHP 5.6 官方镜像
FROM php:5.6-fpm

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    gcc \
    make \
    libssl-dev \
    libcurl4-openssl-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 安装 Redis 扩展
RUN pecl install redis-2.2.8 \
    && docker-php-ext-enable redis

# 安装其他 PHP 扩展
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd pdo_mysql mysqli zip curl

# 禁用 shell_exec 函数
RUN echo "disable_functions = shell_exec" >> /usr/local/etc/php/php.ini

# 复制自定义配置
COPY php/php.ini /usr/local/etc/php/conf.d/custom.ini

# 设置工作目录
WORKDIR /var/www/html

# 设置权限
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php -v || exit 1

# 暴露端口
EXPOSE 9000

# 启动命令
CMD ["php-fpm"]