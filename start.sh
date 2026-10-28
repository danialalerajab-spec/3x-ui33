#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

# 1. تنظیم پورت Nginx
export NGINX_PORT=3000

# 2. نصب پیش‌نیازهای لازم (چون محیط Railpack خالی است)
echo "📦 Installing dependencies (nginx, gettext-base, curl)..."
apt-get update && apt-get install -y nginx gettext-base curl ca-certificates || true

# 3. دانلود و نصب x-ui (چون پوشه از قبل وجود ندارد)
echo "⬇️ Downloading and installing x-ui..."
mkdir -p /usr/local/x-ui
# دانلود آخرین نسخه x-ui (معمولاً به صورت فایل فشرده)
curl -L -o /tmp/x-ui.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz
tar -xzf /tmp/x-ui.tar.gz -C /usr/local/
# اگر فایل‌ها در پوشه x-ui استخراج شدند، آنها را به مسیر اصلی منتقل می‌کنیم
if [ -d "/usr/local/x-ui-linux-amd64" ]; then
    mv /usr/local/x-ui-linux-amd64/* /usr/local/x-ui/
fi
chmod +x /usr/local/x-ui/x-ui
cd /usr/local/x-ui

# 4. اعمال تنظیمات پنل
echo "🔧 Applying panel settings via x-ui CLI..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

# 5. ساخت فایل کانفیگ Nginx
echo "🔧 Building nginx.conf for fixed port: $NGINX_PORT"
# نکته: باید مطمئن شوید فایل nginx.conf.template در مخزن گیت‌هاب شما وجود دارد
# اگر وجود ندارد، باید آن را بسازید. در غیر این صورت خط زیر ارور می‌دهد.
if [ -f "/etc/nginx/nginx.conf.template" ]; then
    envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
else
    # یک کانفیگ پیش‌فرض ساده در صورت نبود تمپلیت
    cat <<EOF > /etc/nginx/nginx.conf
worker_processes 1;
events { worker_connections 1024; }
http {
    server {
        listen ${NGINX_PORT};
        location / {
            proxy_pass http://127.0.0.1:2053;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF
fi

# 6. اجرای x-ui در پس‌زمینه
echo "▶️  Starting x-ui in background..."
./x-ui &
X_UI_PID=$!

sleep 2

# 7. اجرای Nginx در پیش‌زمینه
echo "▶️  Starting nginx in foreground on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"
