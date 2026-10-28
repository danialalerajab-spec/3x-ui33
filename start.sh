#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

# استفاده از پورت پلتفرم (اگر PORT وجود نداشت از 3000 استفاده کن)
export NGINX_PORT="${PORT:-3000}"
echo "🌐 Nginx will listen on port: $NGINX_PORT"

# بررسی اینکه آیا x-ui نصب شده است یا خیر
if [ ! -d "/usr/local/x-ui" ]; then
    echo "⬇️ x-ui not found. Downloading and installing..."
    
    # در محیط Railpack معمولاً curl نیست، از wget یا ابزارهای پایه استفاده می‌کنیم
    if command -v curl &> /dev/null; then
        curl -L -o /tmp/x-ui.tar.gz https://github.com/mhsanaei/3x-ui/releases/download/v3.8.5/x-ui-linux-amd64.tar.gz
    elif command -v wget &> /dev/null; then
        wget -O /tmp/x-ui.tar.gz https://github.com/mhsanaei/3x-ui/releases/download/v3.8.5/x-ui-linux-amd64.tar.gz
    else
        echo "❌ Neither curl nor wget found. Cannot download x-ui."
        exit 1
    fi

    # استخراج فایل‌ها
    mkdir -p /usr/local/x-ui
    tar -xzf /tmp/x-ui.tar.gz -C /usr/local/
    # جابجایی فایل‌ها به مسیر اصلی
    if [ -d "/usr/local/x-ui-linux-amd64" ]; then
        mv /usr/local/x-ui-linux-amd64/* /usr/local/x-ui/
    fi
    chmod +x /usr/local/x-ui/x-ui
    rm /tmp/x-ui.tar.gz
    echo "✅ x-ui installed successfully."
fi

cd /usr/local/x-ui

echo "🔧 Applying panel settings via x-ui CLI..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

echo "🔧 Building nginx.conf for fixed port: $NGINX_PORT"
# بررسی وجود فایل تمپلیت
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
