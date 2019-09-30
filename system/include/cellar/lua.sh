#!/usr/bin/env bash

usage() {
cat << EOF
usage: install-cellar-bash [--help|-h]

Install Bash.

see also:
    - https://www.gnu.org/software/bash/

note:
    Bash script.
    Updated 2019-09-23.
EOF
}

_koopa_help "$@"

name="bash"
version="$(_koopa_variable "$name")"
prefix="$(_koopa_cellar_prefix)/${name}/${version}"
tmp_dir="$(_koopa_tmp_dir)/${name}"
build_os_string="$(_koopa_build_os_string)"
gnu_mirror="http://ftpmirror.gnu.org"
exe_file="${prefix}/bin/${name}"

printf "Installing %s %s.\n" "$name" "$version"

(
    rm -frv "$prefix"
    rm -fr "$tmp_dir"
    mkdir -pv "$tmp_dir"
    cd "$tmp_dir" || exit 1
    wget "${gnu_mirror}/bash/bash-${version}.tar.gz"
    tar -xzvf "bash-${version}.tar.gz"
    cd "bash-${version}" || exit 1
    ./configure \
        --build="$build_os_string" \
        --prefix="$prefix"
    make --jobs="$CPU_COUNT"
    make test
    make install
    rm -fr "$tmp_dir"
)

_koopa_link_cellar "$name" "$version"
_koopa_update_shells "$name"

"$exe_file" --version
command -v "$exe_file"
