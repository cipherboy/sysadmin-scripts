#!/bin/bash

systemctl stop gitea

gitea_url="$1"

su git -c "cd ~git && wget \"$gitea_url\" && unxz gitea-*.xz && rm gitea && ln -s \"\$(ls gitea-*-amd64 | sort | tail -n 1)\" gitea && chmod +x gitea-*-amd64"

systemctl start gitea
