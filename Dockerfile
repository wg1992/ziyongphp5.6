# 使用已验证的 PHP 5.6 FPM 基础镜像
FROM zlilizh/phpfpm5.6:latest

# 设置环境变量
ENV TZ=Asia/Shanghai \
    REDIS_VERSION=5.0.14

# 1. 安装 Redis 服务器
# 从官方仓库下载、编译并安装指定版本的 Redis
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \
        gcc \
        make \
        libc6-dev \
    && wget -q https://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz \
    && tar xzf redis-$REDIS_VERSION.tar.gz \
    && cd redis-$REDIS_VERSION \
    && make -j$(nproc) && make install PREFIX=/usr/local \
    && cd .. && rm -rf redis-$REDIS_VERSION* \
    && apt-get purge -y --auto-remove wget gcc make libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. 配置 Redis
# 创建配置目录和数据目录，调整基本配置
RUN mkdir -p /etc/redis /data/redis \
    && chown -R www-data:www-data /data/redis
COPY redis.conf /etc/redis/redis.conf

# 3. 启用 shell_exec 函数
# 注释掉 php.ini 中对 shell_exec 的禁用
RUN sed -i 's/^disable_functions.*shell_exec.*//' /usr/local/etc/php/php.ini \
    && echo "已解除 shell_exec 函数禁用"

# 4. 安装并启用 SourceGuardian (SG15) 加载器
# 注意：请确保已从官网下载 ixed.5.6.lin 并放在构建上下文
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
