#!/bin/bash

set -euxo pipefail

now="$(date +%s --utc)"
remote_dir=/home/git
local_dir=/media/large/Backups/git.cipherboy.com/$now

mkdir -p "$local_dir"

rsync -rliv "root@git.cipherboy.com:$remote_dir/" "$local_dir/"
