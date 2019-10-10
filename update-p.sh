#!/bin/sh

function update_p() {(
    set -e

    if [ ! -e "$HOME/GitHub/cipherboy/sharg" ]; then
        mkdir -p "$HOME/GitHub/cipherboy"
        cd "$HOME/GitHub/cipherboy"
        git clone https://github.com/cipherboy/sharg
    fi

    if [ ! -e "$HOME/GitHub/cipherboy/p" ]; then
        mkdir -p "$HOME/GitHub/cipherboy"
        cd "$HOME/GitHub/cipherboy"
        git clone https://github.com/cipherboy/p
    fi

    # Update sharg first
    cd "$HOME/GitHub/cipherboy/sharg"

    local commit="$(git rev-parse HEAD)"
    git pull || true
    git log --color=always --oneline "$commit..HEAD" | cat -

    pip3 install --user -e .

    # Then update p
    cd "$HOME/GitHub/cipherboy/p"

    commit="$(git rev-parse HEAD)"
    git pull || true
    git log --color=always --oneline "$commit..HEAD" | cat -

    mkdir -p bin && python3 ./build.py

    mkdir -p "$HOME/bin" || true
    cp bin/p "$HOME/bin/p"
)}

update_p "@"
