#!/usr/bin/env bash
# shellcheck disable=SC2154

# """
# If system doesn't have gettext (msgfmt) installed:
# Note that this doesn't work on Ubuntu 18 LTS.
# NO_GETTEXT=YesPlease
#
# Git source code releases on GitHub:
# > file="v${version}.tar.gz"
# > url="https://github.com/git/${name}/archive/${file}"
# """

file="${name}-${version}.tar.gz"
url="https://mirrors.edge.kernel.org/pub/software/scm/${name}/${file}"
koopa::download "$url"
koopa::extract "$file"
koopa::cd "git-${version}"
make configure
./configure \
    --prefix="$prefix" \
    --with-openssl='/bin/openssl'
make --jobs="$jobs" V=1
make install
