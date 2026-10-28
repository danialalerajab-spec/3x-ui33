#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

# پلتفرم‌هایی مثل Railway پورت را در متغیر PORT قرار می‌دهند. 
# اگر PORT وجود نداشت، از 3000 استفاده می‌کنیم.
export NGINX_PORT="${PORT:-3000}"
echo "🌐 Nginx will listen on port: $NGINX_PORT"

cd /usr/local/x-ui

echo "🔧 Applying panel settings via x-ui CLI..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

echo "🔧 Building nginx.conf for fixed port: $NGINX_PORT"
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "▶️  Starting x-ui in background..."
./x-ui &
X_UI_PID=$!

sleep 2

echo "▶️  Starting nginx in foreground..."
# تست کانفیگ nginx
nginx -t
# اجرای nginx به عنوان پروسه اصلی (تا کانتینر خاموش نشود)
exec nginx -g "daemon off;"
