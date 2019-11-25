#!/usr/bin/env bash
set -Eeu -o pipefail

_koopa_assert_is_installed docbook2x-texi

name="git"
version="$(_koopa_variable "$name")"
prefix="$(_koopa_cellar_prefix)/${name}/${version}"
tmp_dir="$(_koopa_tmp_dir)/${name}"
build="$(_koopa_make_build_string)"
jobs="$(_koopa_cpu_count)"

_koopa_message "Installing ${name} ${version}."

(
    _koopa_cd_tmp_dir "$tmp_dir"
    file="v${version}.tar.gz"
    _koopa_download "https://github.com/git/git/archive/${file}"
    _koopa_extract "$file"
    cd "git-${version}" || exit 1
    make configure
    ./configure \
        --build="$build" \
        --prefix="$prefix" \
        --with-openssl="/bin/openssl"
    # This is now erroring on RHEL 7.7:
    # > make --jobs="$jobs" all doc info
    # > make install install-doc install-html install-info
    make --jobs="$jobs"
    make install
    rm -fr "$tmp_dir"
)

_koopa_link_cellar "$name" "$version"
