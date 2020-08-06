#!/usr/bin/env bash

koopa::add_user_to_etc_passwd() { # {{{1
    # """
    # Any any type of user, including domain user to passwd file.
    # @note Updated 2020-08-06.
    #
    # Necessary for running 'chsh' with a Kerberos / Active Directory domain
    # account, on AWS or Azure for example.
    #
    # Note that this function will enable use of RStudio for domain users.
    # """
    local passwd_file user user_string
    koopa::assert_has_args_le "$#" 1
    passwd_file='/etc/passwd'
    koopa::assert_is_file "$passwd_file"
    user="${1:-${USER:?}}"
    user_string="$(getent passwd "$user")"
    koopa::info "Updating '${passwd_file}' to include '${user}'."
    if ! sudo grep -q "$user" "$passwd_file"
    then
        sudo sh -c "printf '%s\n' '${user_string}' >> '${passwd_file}'"
    else
        koopa::note "$user already defined in '${passwd_file}'."
    fi
    return 0
}

koopa::add_user_to_group() { # {{{1
    # """
    # Add user to group.
    # @note Updated 2020-08-06.
    #
    # Alternate approach:
    # > usermod -a -G group user
    #
    # @examples
    # koopa::add_user_to_group 'docker'
    # """
    local group user
    koopa::assert_has_args_le "$#" 2
    koopa::assert_is_installed gpasswd
    group="${1:?}"
    user="${2:-${USER:?}}"
    koopa::info "Adding user '${user}' to group '${group}'."
    sudo gpasswd --add "$user" "$group"
    return 0
}

koopa::java_update_alternatives() { # {{{1
    # """
    # Update Java alternatives.
    # @note Updated 2020-07-05.
    #
    # This step is intentionally skipped for non-admin installs, when calling
    # from 'install-openjdk' script.
    # """
    local prefix priority
    koopa::assert_has_args_eq "$#" 1
    koopa::is_shared_install || return 0
    koopa::is_installed update-alternatives || return 0
    prefix="${1:?}"
    prefix="$(realpath "$prefix")"
    priority=100
    sudo rm -fv /var/lib/alternatives/java
    sudo update-alternatives --install \
        '/usr/bin/java' \
        'java' \
        "${prefix}/bin/java" \
        "$priority"
    sudo update-alternatives --set \
        'java' \
        "${prefix}/bin/java"
    sudo rm -fv /var/lib/alternatives/javac
    sudo update-alternatives --install \
        '/usr/bin/javac' \
        'javac' \
        "${prefix}/bin/javac" \
        "$priority"
    sudo update-alternatives --set \
        'javac' \
        "${prefix}/bin/javac"
    sudo rm -fv /var/lib/alternatives/jar
    sudo update-alternatives --install \
        '/usr/bin/jar' \
        'jar' \
        "${prefix}/bin/jar" \
        "$priority"
    sudo update-alternatives --set \
        'jar' \
        "${prefix}/bin/jar"
    update-alternatives --display java
    update-alternatives --display javac
    update-alternatives --display jar
    return 0
}

koopa::link_docker() { # {{{1
    # """
    # Link Docker library onto data disk for VM.
    # @note Updated 2020-07-05.
    # """
    local dd_link_prefix etc_source lib_n lib_sys os_id
    koopa::assert_has_no_args "$#"
    koopa::is_installed docker || return 0
    koopa::assert_has_sudo
    # e.g. '/mnt/data01/n' to '/n' for AWS.
    dd_link_prefix="$(koopa::data_disk_link_prefix)"
    [[ -d "$dd_link_prefix" ]] || return 0
    koopa::info 'Updating Docker configuration.'
    koopa::assert_is_installed systemctl
    koopa::note 'Stopping Docker.'
    sudo systemctl stop docker
    lib_sys='/var/lib/docker'
    lib_n="${dd_link_prefix}/var/lib/docker"
    os_id="$(koopa::os_id)"
    koopa::note "Moving Docker lib from '${lib_sys}' to '${lib_n}'."
    etc_source="$(koopa::prefix)/os/${os_id}/etc/docker"
    if [[ -d "$etc_source" ]]
    then
        koopa::ln -S -t '/etc/docker' "${etc_source}/"*
    fi
    sudo rm -frv "$lib_sys"
    sudo mkdir -pv "$lib_n"
    sudo ln -fnsv "$lib_n" "$lib_sys"
    koopa::note 'Restarting Docker.'
    sudo systemctl enable docker
    sudo systemctl start docker
    return 0
}

koopa::remove_user_from_group() { # {{{1
    # """
    # Remove user from group.
    # @note Updated 2020-07-05.
    #
    # @examples
    # koopa::remove_user_from_group 'docker'
    # """
    local group user
    koopa::assert_has_args_le "$#" 2
    koopa::assert_is_installed gpasswd sudo
    koopa::assert_has_sudo
    group="${1:?}"
    user="${2:-${USER}}"
    sudo gpasswd --delete "$user" "$group"
    return 0
}

koopa::update_etc_profile_d() { # {{{1
    # """
    # Link shared 'zzz-koopa.sh' configuration file into '/etc/profile.d/'.
    # @note Updated 2020-08-06.
    # """
    local file koopa_prefix string
    koopa::assert_has_no_args "$#"
    koopa::is_shared_install || return 0
    koopa::assert_has_sudo
    file='/etc/profile.d/zzz-koopa.sh'
    # Early return if file exists and is not a symlink.
    # Previous verisons of koopa prior to 2020-05-09 created a symlink here.
    if [[ -f "$file" ]] && [[ ! -L "$file" ]]
    then
        return 0
    fi
    sudo rm -fv "$file"
    koopa_prefix="$(koopa::prefix)"
    read -r -d '' string << END || true
#!/bin/sh

# koopa shell
# https://koopa.acidgenomics.com/
# shellcheck source=/dev/null
. "${koopa_prefix}/activate"
END
    koopa::sudo_write_string "$string" "$file"
}

koopa::update_ldconfig() { # {{{1
    # """
    # Update dynamic linker (LD) configuration.
    # @note Updated 2020-08-06.
    # """
    local conf_source dest_file os_id prefix source_file
    koopa::assert_has_no_args "$#"
    [[ -d '/etc/ld.so.conf.d' ]] || return 0
    koopa::assert_is_installed ldconfig
    koopa::assert_has_sudo
    os_id="$(koopa::os_id)"
    prefix="$(koopa::prefix)"
    conf_source="${prefix}/os/${os_id}/etc/ld.so.conf.d"
    [[ -d "$conf_source" ]] || return 0
    # Create symlinks with 'koopa-' prefix.
    # Note that we're using shell globbing here.
    # https://unix.stackexchange.com/questions/218816
    koopa::h2 "Updating ldconfig in '/etc/ld.so.conf.d/'."
    for source_file in "${conf_source}/"*".conf"
    do
        dest_file="/etc/ld.so.conf.d/koopa-$(basename "$source_file")"
        sudo ln -fnsv "$source_file" "$dest_file"
    done
    sudo ldconfig
    return 0
}

koopa::update_lmod_config() { # {{{1
    # """
    # Link lmod configuration files in '/etc/profile.d/'.
    # @note Updated 2020-08-06.
    #
    # Need to check for this case:
    # ln: failed to create symbolic link '/etc/fish/conf.d/z00_lmod.fish':
    # No suchfile or directory
    # """
    local etc_dir init_dir
    koopa::assert_has_no_args "$#"
    koopa::assert_has_sudo
    init_dir="$(koopa::app_prefix)/lmod/apps/lmod/lmod/init"
    [[ -d "$init_dir" ]] || return 0
    koopa::h2 'Updating Lmod init configuration.'
    etc_dir='/etc/profile.d'
    sudo mkdir -pv "$etc_dir"
    # bash, zsh
    sudo ln -fnsv "${init_dir}/profile" "${etc_dir}/z00_lmod.sh"
    # csh, tcsh
    sudo ln -fnsv "${init_dir}/cshrc" "${etc_dir}/z00_lmod.csh"
    # fish
    if koopa::is_installed fish
    then
        etc_dir='/etc/fish/conf.d'
        sudo mkdir -pv "$etc_dir"
        sudo ln -fnsv "${init_dir}/profile.fish" "${etc_dir}/z00_lmod.fish"
    fi
    return 0
}
