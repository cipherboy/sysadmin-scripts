#!/bin/sh

systemctl stop nginx

if [ -d "/opt/letsencrypt" ]; then
    cd /opt/letsencrypt
    ./certbot-auto --standalone renew
elif command -v "certbot" 1>/dev/null; then
    certbot --standalone renew
fi

systemctl start nginx
