#!/bin/bash
set -e

echo “启动 Redis 服务...”
redis-server /etc/redis/redis.conf --daemonize no &

echo “启动 PHP-FPM...”
php-fpm
