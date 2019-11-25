#!/usr/bin/env bash
set -Eeu -o pipefail

name="zsh"
version="$(_koopa_variable "$name")"
prefix="$(_koopa_cellar_prefix)/${name}/${version}"
tmp_dir="$(_koopa_tmp_dir)/${name}"
build="$(_koopa_make_build_string)"
jobs="$(_koopa_cpu_count)"

_koopa_message "Installing ${name} ${version}."

(
    _koopa_cd_tmp_dir "$tmp_dir"
    url_stem="https://sourceforge.net/projects/zsh/files/zsh"
    file="zsh-${version}.tar.xz"
    _koopa_download "${url_stem}/${version}/${file}/download" "$file"
    _koopa_extract "$file"
    cd "zsh-${version}" || exit 1
    ./configure \
        --build="$build" \
        --prefix="$prefix"
    make --jobs="$jobs"
    make check
    make test
    make install
    rm -fr "$tmp_dir"
)

_koopa_link_cellar "$name" "$version"
_koopa_update_shells "$name"
