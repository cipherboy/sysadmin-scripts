#!/bin/sh

if ! command -v git >/dev/null 2>&1 ||
        ! command -v time >/dev/null 2>&1; then
    if (( EUID == 0 )) && command -v dnf >/dev/null 2>&1; then
        dnf install -y git time
    elif (( EUID == 0 )) && command -v apt >/dev/null 2>&1; then
        apt install -y git time
    else
        echo "Please install the following packages before continuing:" 1>&2
        echo "git time" 1>&2
        exit 1
    fi
fi

install_dotfiles() {(
    set -e

    if [ ! -e "$HOME/GitHub/cipherboy/dotfiles" ]; then
        mkdir -p "$HOME/GitHub/cipherboy"
        cd "$HOME/GitHub/cipherboy"
        git clone https://github.com/cipherboy/dotfiles

        touch ~/.no_powerline
    fi

    cd "$HOME/GitHub/cipherboy/dotfiles"
    git pull || true

    ./install.sh bash
    ./install.sh tmux
    ./install.sh vimrc
    ./agents/vim.sh
)}

install_dotfiles "$@"
