#!/usr/bin/env bash
set -Eeu -o pipefail

# shellcheck source=/dev/null
source "${KOOPA_DIR}/shell/bash/include/functions.sh"

assert_has_sudo
assert_is_os_debian
assert_is_installed apt-get
assert_has_no_environments
build_chgrp /usr/local
update_ldconfig

sudo apt-get -y update
