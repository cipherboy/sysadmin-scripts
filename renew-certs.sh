#!/bin/sh

systemctl stop nginx

cd /opt/letsencrypt
./certbot-auto --standalone renew

systemctl start nginx
