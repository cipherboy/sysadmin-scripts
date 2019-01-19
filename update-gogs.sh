#!/bin/sh

systemctl stop gogs

gogs_url="$1"

su git -c "cd ~git && wget \"$gogs_url\" -O linux_amd64.tar.gz && rm -rf tmp && mkdir tmp && cd tmp && tar -xf ../linux_amd64.tar.gz && cd ../ && rm -rf gogs.bak && cp -pr gogs gogs.bak && rm gogs/templates gogs/scripts gogs/public -r && cp tmp/gogs ./ -r"

systemctl start gogs
