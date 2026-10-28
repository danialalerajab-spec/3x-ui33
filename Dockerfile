FROM alpine:3.19

RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates \
    socat \
    tzdata \
    sqlite \
    nginx \
    gettext \
    && ln -sf /usr/share/zoneinfo/Asia/Tehran /etc/localtime

# دانلود و نصب 3x-ui
RUN curl -L https://github.com/mhsanaei/3x-ui/releases/download/v3.8.5/x-ui-linux-amd64.tar.gz -o /tmp/x-ui.tar.gz \
    && tar -xzf /tmp/x-ui.tar.gz -C /usr/local/ \
    && rm /tmp/x-ui.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui

RUN mkdir -p /etc/x-ui /var/log/x-ui /etc/nginx

# کپی کردن فایل‌های کانفیگ
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY run.sh /start.sh
RUN chmod +x /start.sh

# (اختیاری) اگر پلتفرم از متغیر PORT استفاده می‌کند، این خط به Nginx می‌فهماند که کدام پورت را باز کند
ENV NGINX_PORT=3000

CMD ["/start.sh"]
