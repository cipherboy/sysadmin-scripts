#!/bin/bash

set -eux

function main() {
# Configuration

local branch="master"
local rebase="master"
local with_nss="true"
local with_openssl="true"

export CXX=clang++
export CC=clang
export CFLAGS="-Og -ggdb -fsanitize=fuzzer-no-link -DDEBUG"
export CXXFLAGS="-Og -ggdb -fsanitize=fuzzer-no-link -DDEBUG"
export LINK_FLAGS="-ldl -lpthread"
export LIBFUZZER_LINK="/usr/lib64/clang/8.0.0/lib/libclang_rt.fuzzer-x86_64.a"

local base_dir="$(pwd)/cryptofuzz"

if [ ! -d cryptofuzz ]; then
    # Install necessary packages in Fedora

    sudo dnf install -y gdb gcc clang valgrind python2 compiler-rt git mercurial

    # Clone cryptofuzz base repository

    git clone https://github.com/cipherboy/cryptofuzz && cd cryptofuzz
    git remote add upstream https://github.com/cipherboy/cryptofuzz
    git fetch --all

    [ -n "$branch" ] && git checkout "$branch"
    [ -n "$rebase" ] && git rebase -i "upstream/$rebase"

    git submodule init && git submodule update
else
    cd "$base_dir"
fi

python2 ./gen_repository.py

# Set up crypto projects
local crypto_base="$base_dir/crypto"
mkdir -p "$crypto_base"

if [ "$with_nss" == "true" ]; then
    export NSS_NSPR_PATH="$crypto_base/sandbox"
    mkdir -p "$NSS_NSPR_PATH"
    cd "$NSS_NSPR_PATH"

    [ ! -d nspr ] && hg clone https://hg.mozilla.org/projects/nspr
    [ ! -d nss ] && git clone https://github.com/nss-dev/nss

    if [ ! -e "$base_dir/modules/nss/module.a" ]; then
        cd nss
        rm -rf out ../dist
        CC="" CFLAGS="-Og -ggdb" ./build.sh --fuzz --clang --asan --static

        cd "$base_dir/modules/nss"
        make
    fi
fi

if [ "$with_openssl" == "true" ]; then
    local openssl_path="$base_dir/crypto/openssl"

    [ ! -d "$openssl_path" ] && git clone https://github.com/openssl/openssl "$openssl_path"

    if [ ! -e "$base_dir/modules/openssl/module.a" ]; then
        cd "$openssl_path"
        ./config --debug enable-md2 enable-rc5
        make -j $(nproc)

        export OPENSSL_LIBCRYPTO_A_PATH="$openssl_path/libcrypto.a"
        export OPENSSL_INCLUDE_PATH="$openssl_path/include"

        cd "$base_dir/modules/openssl"
        make
    fi
fi

# Create the corpus to test
if [ ! -d "$base_dir/corpus" ]; then
    mkdir "$base_dir/corpus" && cd "$base_dir/corpus"
    unzip ../cryptofuzz-corpora/all_latest.zip
fi

# Build and run cryptofuzz
cd "$base_dir"
make && ./cryptofuzz ./corpus
}

main "$@"
