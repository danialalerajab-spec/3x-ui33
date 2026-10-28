#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

export NGINX_PORT="${PORT:-3000}"
echo "🌐 Nginx will listen on port: $NGINX_PORT"

cd /usr/local/x-ui

echo "🔧 Applying panel settings via x-ui CLI..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

echo "🔧 Building nginx.conf for fixed port: $NGINX_PORT"
if [ -f "/etc/nginx/nginx.conf.template" ]; then
    envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
else
    echo "❌ nginx.conf.template not found!"
    exit 1
fi

echo "▶️  Starting x-ui in background..."
./x-ui &
X_UI_PID=$!

sleep 2

echo "▶️  Starting nginx in foreground..."
nginx -t
exec nginx -g "daemon off;"
