#!/usr/bin/env bash
set -Eeu -o pipefail

name="shellcheck"
version="$(_koopa_variable "$name")"
prefix="$(_koopa_cellar_prefix)/${name}/${version}"
tmp_dir="$(_koopa_tmp_dir)/${name}"

_koopa_message "Installing ${name} ${version}."

(
    _koopa_cd_tmp_dir "$tmp_dir"
    file="shellcheck-v${version}.linux.x86_64.tar.xz"
    url="https://storage.googleapis.com/shellcheck/${file}"
    _koopa_download "$url"
    _koopa_extract "$file"
    mkdir -pv "${prefix}/bin"
    cp "shellcheck-v${version}/shellcheck" "${prefix}/bin"
    rm -fr "$tmp_dir"
)

_koopa_link_cellar "$name" "$version"
