# 使用已验证的 PHP 5.6 FPM 基础镜像
FROM zlilizh/phpfpm5.6:latest

# 设置环境变量
ENV TZ=Asia/Shanghai

# ---------- 关键修复 1：更换为有效的 Debian 存档源 ----------
RUN echo "deb http://archive.debian.org/debian/ stretch main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99no-check-valid-until

# 1. 安装 Redis 服务器 (使用系统包管理器安装旧版本，简单可靠)
RUN apt-get update && apt-get install -y --no-install-recommends \
        redis-server \
    && rm -rf /var/lib/apt/lists/*

# 2. 配置 Redis
RUN mkdir -p /data/redis \
    && chown -R www-data:www-data /data/redis \
    # 调整Redis配置：绑定本地，关闭守护进程，设置内存策略
    && sed -i 's/^bind.*/bind 127.0.0.1/g' /etc/redis/redis.conf \
    && sed -i 's/^daemonize yes/daemonize no/g' /etc/redis/redis.conf \
    && sed -i 's/^logfile.*/logfile \/var\/log\/redis\/redis-server.log/g' /etc/redis/redis.conf \
    && echo "maxmemory 256mb" >> /etc/redis/redis.conf \
    && echo "maxmemory-policy allkeys-lru" >> /etc/redis/redis.conf \
    && echo "dir /data/redis" >> /etc/redis/redis.conf

# 3. 启用 shell_exec 函数 (根据您的要求)
RUN sed -i 's/^disable_functions.*shell_exec.*//' /usr/local/etc/php/php.ini \
    && echo "已解除 shell_exec 函数禁用"

# 4. 安装并启用 SourceGuardian (SG15) 加载器
# 注意：请确保已从官网下载 ixed.5.6.lin 并放在构建上下文目录
COPY ixed.5.6.lin /usr/local/lib/php/extensions/no-debug-non-zts-20131226/
RUN chmod 755 /usr/local/lib/php/extensions/no-debug-non-zts-20131226/ixed.5.6.lin \
    && echo "extension=/usr/local/lib/php/extensions/no-debug-non-zts-20131226/ixed.5.6.lin" > /usr/local/etc/php/conf.d/sourceguardian.ini

# 5. 复制您的应用配置（可选）
COPY php/php.ini /usr/local/etc/php/conf.d/custom.ini

# 6. 设置工作目录和权限
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# 7. 创建启动脚本（同时启动 Redis 和 PHP-FPM）
COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

# 健康检查、端口暴露
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php -v || exit 1
EXPOSE 9000

# 使用自定义启动脚本
CMD ["/usr/local/bin/start.sh"]
