# 使用已验证可用的第三方镜像，预装 PHP 5.6 FPM 及常用扩展 (redis, gd, mysqli 等)
FROM zlilizh/phpfpm5.6:latest

# 设置环境变量（时区）
ENV TZ=Asia/Shanghai

# 1. 根据您的要求，禁用 shell_exec 函数
RUN echo "disable_functions = shell_exec" >> /usr/local/etc/php/conf.d/disable.ini

# 2. 设置时区
RUN echo "date.timezone = ${TZ}" > /usr/local/etc/php/conf.d/timezone.ini

# 3. 复制您的自定义 PHP 配置（如果存在，会覆盖基础配置）
COPY php/php.ini /usr/local/etc/php/conf.d/custom.ini

# 设置工作目录和权限
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php -v || exit 1

EXPOSE 9000
CMD ["php-fpm"]
