#!/bin/bash

set -eux

function main() {
# Configuration

local branch="master"
local rebase="master"
local with_nss="true"
local with_openssl="false"
local with_botan="true"

export LIBFUZZER_LINK="/usr/lib64/clang/8.0.0/lib/libclang_rt.fuzzer-x86_64.a"
export LIBFUZZER_NO_MAIN_LINK="/usr/lib64/clang/8.0.0/lib/libclang_rt.fuzzer_no_main-x86_64.a"
export CXX=clang++
export CC=clang
export CFLAGS="-O0 -g -fsanitize=fuzzer-no-link,address"
export CXXFLAGS="-O0 -g -fsanitize=fuzzer-no-link,address"
export LDFLAGS="-fsanitize=fuzzer-no-link,address -Wl,--unresolved-symbols=ignore-all"
export LINK_FLAGS=" -lsqlite3 -ldl -lpthread $LIBFUZZER_LINK -fsanitize=fuzzer-no-link,address"

export NSSCXXFLAGS=""
export OPENSSLCXXFLAGS=""
export BOTANCXXFLAGS=""

local base_dir="$(pwd)/cryptofuzz"

if [ ! -d cryptofuzz ]; then
    # Install necessary packages in Fedora

    sudo dnf install -y gdb clang valgrind python2 compiler-rt git mercurial gyp ninja-build python3

    # Clone cryptofuzz base repository

    git clone https://github.com/cipherboy/cryptofuzz && cd cryptofuzz
    git remote add upstream https://github.com/cipherboy/cryptofuzz
    git fetch --all

    [ -n "$branch" ] && git checkout "$branch"
    [ -n "$rebase" ] && git rebase "upstream/$rebase"

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
        rm -rf out ../dist && git clean -xdf

		if false; then
		(
		# Configure and build NSS -- doesn't work due to NSPR issues
		export IN_TREE_FREEBL_HEADERS_FIRST=1
		export NSS_FORCE_FIPS=1
		unset BUILD_OPT
		local all_flags="$CFLAGS"
		export LDFLAGS="$all_flags"
		export XCFLAGS="$all_flags"
		export XLDFLAGS="$all_flags"
		export PKG_CONFIG_ALLOW_SYSTEM_LIBS=1
		export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
		# export NSPR_INCLUDE_DIR="$(/usr/bin/pkg-config --cflags-only-I nspr | sed 's/-I//')"
		# export NSPR_LIB_DIR=/usr/lib64
		export NSS_USE_SYSTEM_SQLITE=1
		export USE_STATIC_LIBS=1
		export USE_64=1
		# export NSS_BUILD_CONTINUE_ON_ERROR=1
		export ZDEFS_FLAG=""
		export NSS_DISABLE_GTESTS=1
		export NSS_STATIC_SOFTOKEN=1
		export CCC=$CXX

		make nss_clean_all nss_build_all
	  	)
		fi

		if true; then
		  (
			# unset CFLAGS
			# unset CXXFLAGS
			# unset LDFLAGS
			unset LINK_FLAGS
			export CCC="$CXX"
			export XCFLAGS="$CFLAGS"
			export XLDFLAGS="$LDFLAGS"
			./build.sh --clang --enable-fips --static --asan --disable-tests -v
		  )
		fi

        cd "$base_dir/modules/nss"
        make clean all
    fi

	export NSSCXXFLAGS="-DCRYPTOFUZZ_NSS -I $NSS_NSPR_PATH/dist/public/nss -I $NSS_NSPR_PATH/dist/Debug/include/nspr -I $NSS_NSPR_PATH/nss/lib/pk11wrap"
	export LINK_FLAGS="$LINK_FLAGS"
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
        make clean all
    fi
else
	export OPENSSLCXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_NO_OPENSSL"
fi

if [ "$with_botan" == "true" ]; then
	local botan_path="$base_dir/crypto/botan"

	[ ! -d "$botan_path" ] && git clone https://github.com/randombit/botan.git "$botan_path"

	export BOTAN_INCLUDE_PATH="$botan_path/build/include"

	if [ ! -e "$base_dir/modules/botan/module.a" ]; then
	  	cd "$botan_path"
		./configure.py --cc-bin=$CXX --cc-abi-flags="$CXXFLAGS" --disable-shared --disable-modules=locking_allocator
		make -j $(nproc)

		export LIBBOTAN_A_PATH="$botan_path/libbotan-2.a"

		cd "$base_dir/modules/botan"
		make clean all
	fi

	export BOTANCXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_BOTAN -I $BOTAN_INCLUDE_PATH"
fi

# Create the corpus to test
if [ ! -d "$base_dir/corpus" ]; then
    mkdir "$base_dir/corpus" && cd "$base_dir/corpus"
    unzip ../cryptofuzz-corpora/all_latest.zip
fi

# Build and run cryptofuzz
cd "$base_dir"
export CXXFLAGS="$CXXFLAGS $NSSCXXFLAGS $OPENSSLCXXFLAGS $BOTANCXXFLAGS"
make && ./cryptofuzz ./corpus
}

main "$@"
