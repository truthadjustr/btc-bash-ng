#!/bin/bash

get_bc ()
{
    if ! sha256sum -c "${build_dir}/bc-1.07.1.tar.gz.sha256"; then
        wget -q --show-progress --tries=5 -O bc-1.07.1.tar.gz https://ftp.gnu.org/gnu/bc/bc-1.07.1.tar.gz
    fi
    if ! sha256sum -c "${build_dir}/bc-1.07.1.tar.gz.sig.sha256"; then
        wget -q --show-progress --tries=5 -O bc-1.07.1.tar.gz.sig https://ftp.gnu.org/gnu/bc/bc-1.07.1.tar.gz.sig
    fi
}

verify_bc ()
{
    wget -q --show-progress --tries=5 -O 81C24FF12FB7B14B.pub 'https://pgp.mit.edu/pks/lookup?op=get&search=0x81C24FF12FB7B14B'
    gpg --dearmor <81C24FF12FB7B14B.pub >81C24FF12FB7B14B.pub.bin
    gpg --no-default-keyring --keyring ./81C24FF12FB7B14B.pub.bin --verify bc-1.07.1.tar.gz.sig
}

build_bc ()
{
    if [[ -d "$PWD/bc-1.07.1" ]]; then
        read -p "overwrite $PWD/bc-1.07.1 ? [y/n] " q 1>&2
        if [[ "${q}" =~ [Yy] ]]; then
            rm -rf "$PWD/bc-1.07.1"
        else
            echo "stopping.  move $PWD/bc-1.07.1 and retry." 1>&2
            exit 1
        fi
    fi
    tar -xaf bc-1.07.1.tar.gz
    pushd "bc-1.07.1"
    git init .
    git apply --verbose "${build_dir}/bc.patch" || ( echo "patch failed" 1>&2; exit 1 )
    ./configure --with-readline
    make
    if ! make check; then
        echo -e "\n\nre-run as `./build_bc.sh 2>&1 > build_bc.log` and tell arubi" 1>&2
        exit 1
    fi
    strip bc/bc
    popd
    ln -sf "${build_dir}/deps/bc-1.07.1/bc/bc" "${build_dir}/bin/bc"
}

unset BC_ENV_ARGS
build_dir="$PWD"
mkdir -p "${build_dir}/deps"
pushd ./deps
get_bc
verify_bc
build_bc