# 使用官方 PHP 5.6 Alpine 镜像，体积小且更可靠
FROM php:5.6-fpm-alpine

# 设置环境变量
ENV TZ=Asia/Shanghai

# 安装系统依赖并编译安装 PHP 扩展
# 使用 Alpine 的 apk 包管理器，并清理缓存以减小镜像体积
RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        linux-headers \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        libzip-dev \
        curl-dev \
        openssl-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql mysqli zip curl \
    && pecl install redis-2.2.8 \
    && docker-php-ext-enable redis \
    && apk del .build-deps \
    && rm -rf /tmp/pear

# 禁用 shell_exec 函数（根据您的原始要求）
RUN echo "disable_functions = shell_exec" >> /usr/local/etc/php/conf.d/docker-php-disable-funcs.ini

# 复制自定义配置（请确保您的 php/php.ini 文件存在）
COPY php/php.ini /usr/local/etc/php/conf.d/custom.ini

# 设置工作目录和权限
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php -v || exit 1

# 暴露端口，启动 PHP-FPM
EXPOSE 9000
CMD ["php-fpm"]
