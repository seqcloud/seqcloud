#!/usr/bin/env bash

koopa::rhel_install_base() { # {{{1
    # """
    # Install Red Hat Enterprise Linux (RHEL) base system.
    # @note Updated 2020-08-06.
    # """
    local dev name_fancy pkgs
    koopa::assert_is_installed dnf sudo
    dev=1
    # Install Fedora base first.
    koopa::fedora_install_base "$@"
    name_fancy='Red Hat Enterprise Linux (RHEL) base system'
    koopa::install_start "$name_fancy"

    # Default {{{2
    # --------------------------------------------------------------------------

    koopa::h2 'Installing default packages.'
    # 'dnf-plugins-core' installs 'config-manager'.
    sudo dnf -y install dnf-plugins-core util-linux-user
    sudo dnf config-manager --set-enabled PowerTools
    koopa::rhel_enable_epel

    # Developer {{{2
    # --------------------------------------------------------------------------

    if [[ "$dev" -eq 1 ]]
    then
        koopa::h2 'Installing developer libraries.'
        pkgs=('libgit2' 'libssh2')
        sudo dnf -y install "${pkgs[@]}"
    fi

    koopa::install_success "$name_fancy"
    return 0
}
