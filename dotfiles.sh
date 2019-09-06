#!/bin/sh

if ! command -v git >/dev/null 2>&1 ||
        ! command -v time >/dev/null 2>&1; then
    echo "Please install the following packages before continuing:" 1>&2
    echo "git time" 1>&2
    exit 1
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
