#!/bin/sh

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
