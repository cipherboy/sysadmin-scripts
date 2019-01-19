#!/bin/sh

set -e

if [ ! -e "$HOME/GitHub/cipherboy/p" ]; then
    mkdir -p "$HOME/GitHub/cipherboy"
    cd "$HOME/GitHub/cipherboy"
    git clone https://github.com/cipherboy/p
fi

cd "$HOME/GitHub/cipherboy/p"
git pull || true

mkdir -p bin && ./build.py

mkdir -p "$HOME/bin" || true
cp bin/p "$HOME/bin/p"
