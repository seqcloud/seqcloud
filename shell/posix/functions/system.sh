#!/bin/sh
# shellcheck disable=SC2039

_koopa_admin_group() {  # {{{1
    # """
    # Return the administrator group.
    # @note Updated 2020-02-19.
    #
    # Usage of 'groups' here is terribly slow for domain users.
    # Currently seeing this with CPI AWS Ubuntu config.
    # Instead of grep matching against 'groups' return, just set the
    # expected default per Linux distro. In the event that we're unsure,
    # the function will intentionally error.
    # """
    local group
    if _koopa_is_root
    then
        group='root'
    elif _koopa_is_debian
    then
        group='sudo'
    elif _koopa_is_fedora
    then
        group='wheel'
    elif _koopa_is_macos
    then
        group='admin'
    else
        _koopa_stop 'Failed to detect admin group.'
    fi
    _koopa_print "$group"
}

_koopa_cd() {  # {{{1
    # """
    # Change directory quietly.
    # @note Updated 2019-10-29.
    # """
    cd "$@" > /dev/null || return 1
    return 0
}

_koopa_cd_tmp_dir() {  # {{{1
    # """
    # Prepare and navigate (cd) to temporary directory.
    # @note Updated 2020-02-16.
    #
    # Used primarily for cellar build scripts.
    # """
    local dir
    dir="${1:-$(_koopa_tmp_dir)}"
    rm -fr "$dir"
    mkdir -p "$dir"
    _koopa_cd "$dir"
}

_koopa_chgrp() {  # {{{1
    # """
    # chgrp with dynamic sudo handling.
    # @note Updated 2020-02-16.
    # """
    if _koopa_is_shared_install
    then
        sudo chgrp "$@"
    else
        chgrp "$@"
    fi
    return 0
}

_koopa_chmod() {  # {{{1
    # """
    # chmod with dynamic sudo handling.
    # @note Updated 2020-02-16.
    # """
    if _koopa_is_shared_install
    then
        sudo chmod "$@"
    else
        chmod "$@"
    fi
    return 0
}

_koopa_chmod_flags() {
    # """
    # Default recommended flags for chmod.
    # @note Updated 2020-04-16.
    # """
    local flags
    if _koopa_is_shared_install
    then
        flags='u+rw,g+rw'
    else
        flags='u+rw,g+r,g-w'
    fi
    _koopa_print "$flags"
}

_koopa_chown() {  # {{{1
    # """
    # chown with dynamic sudo handling.
    # @note Updated 2020-02-16.
    # """
    if _koopa_is_shared_install
    then
        sudo chown "$@"
    else
        chown "$@"
    fi
    return 0
}

_koopa_commit() {  # {{{1
    # """
    # Get the koopa commit ID.
    # @note Updated 2020-02-26.
    # """
    local x
    x="$( \
        _koopa_cd "$koopa_prefix"; \
        _koopa_git_last_commit_local \
    )"
    _koopa_print "$x"
}

_koopa_cp() {  # {{{1
    # """
    # Koopa copy.
    # @note Updated 2020-02-28.
    # """
    local source_file
    source_file="${1:?}"
    _koopa_assert_is_existing "$source_file"

    local target_file
    target_file="${2:?}"
    _koopa_mkdir "$(dirname "$target_file")"

    if _koopa_is_shared_install
    then
        sudo cp -af "$source_file" "$target_file"
    else
        cp -af "$source_file" "$target_file"
    fi

    return 0
}

_koopa_cpu_count() {  # {{{1
    # """
    # Return a usable number of CPU cores.
    # @note Updated 2020-03-03.
    #
    # Dynamically assigns 'n-1' or 'n-2' depending on the machine power.
    # """
    local n
    if _koopa_is_installed nproc
    then
        n="$(nproc)"
    elif _koopa_is_macos
    then
        n="$(sysctl -n hw.ncpu)"
    elif _koopa_is_linux
    then
        n="$(getconf _NPROCESSORS_ONLN)"
    else
        # Otherwise assume single threaded.
        n=1
    fi
    # Subtract some cores for login use on powerful machines.
    if [ "$n" -ge 17 ]
    then
        # For 17+ cores, use 'n-2'.
        n=$((n - 2))
    elif [ "$n" -ge 5 ] && [ "$n" -le 16 ]
    then
        # For 5-16 cores, use 'n-1'.
        n=$((n - 1))
    fi
    _koopa_print "$n"
}

_koopa_current_group() {  # {{{1
    # """
    # Current (default) group.
    # @note Updated 2020-04-16.
    # """
    id -gn
    return 0
}

_koopa_current_group_id() {  # {{{1
    # """
    # Current (default) group ID.
    # @note Updated 2020-04-16.
    # """
    id -g
    return 0
}

_koopa_current_user() {  # {{{1
    # """
    # Current user.
    # @note Updated 2020-04-16.
    # """
    id -un
    return 0
}

_koopa_current_user_id() {  # {{{1
    # """
    # Current user ID.
    # @note Updated 2020-04-16.
    # """
    id -u
    return 0
}

_koopa_date() {  # {{{1
    # """
    # Koopa date.
    # @note Updated 2020-02-26.
    # """
    _koopa_variable "koopa-date"
}

_koopa_dotfiles_config_link() {  # {{{1
    # """
    # Dotfiles directory.
    # @note Updated 2019-11-04.
    #
    # Note that we're not checking for existence here, which is handled inside
    # 'link-dotfile' script automatically instead.
    # """
    _koopa_print "$(_koopa_config_prefix)/dotfiles"
}

_koopa_dotfiles_private_config_link() {  # {{{1
    # """
    # Private dotfiles directory.
    # @note Updated 2019-11-04.
    # """
    _koopa_print "$(_koopa_dotfiles_config_link)-private"
}

_koopa_dotfiles_source_repo() {  # {{{1
    # """
    # Dotfiles source repository.
    # @note Updated 2019-11-04.
    # """
    if [ -d "${DOTFILES:-}" ]
    then
        _koopa_print "$DOTFILES"
        return 0
    fi
    local dotfiles
    dotfiles="$(_koopa_prefix)/dotfiles"
    if [ ! -d "$dotfiles" ]
    then
        _koopa_stop "Dotfiles are not installed at '${dotfiles}'."
    fi
    _koopa_print "$dotfiles"
}

_koopa_download() {  # {{{1
    # """
    # Download a file.
    # @note Updated 2020-03-23.
    #
    # Potentially useful curl flags:
    # * --connect-timeout <seconds>
    # * --silent
    # * --stderr
    # * --verbose
    #
    # Note that '--fail-early' flag is useful, but not supported on old versions
    # of curl (e.g. 7.29.0; RHEL 7).
    #
    # Alternatively, can use wget instead of curl:
    # > wget -O file url
    # > wget -q -O - url (piped to stdout)
    # > wget -qO-
    # """
    _koopa_assert_is_installed curl
    local url
    url="${1:?}"
    local file
    file="${2:-}"
    if [ -z "$file" ]
    then
        local wd
        wd="$(pwd)"
        local bn
        bn="$(basename "$url")"
        file="${wd}/${bn}"
    fi
    _koopa_info "Downloading '${url}' to '${file}'."
    curl \
        --create-dirs \
        --fail \
        --location \
        --output "$file" \
        --progress-bar \
        --retry 5 \
        --show-error \
        "$url"
    return 0
}

_koopa_expr() {  # {{{1
    # """
    # Quiet regular expression matching that is POSIX compliant.
    # @note Updated 2020-02-16.
    #
    # Avoid using '[[ =~ ]]' in sh config files.
    # 'expr' is faster than using 'case'.
    #
    # See also:
    # - https://stackoverflow.com/questions/21115121
    # """
    expr "${1:?}" : "${2:?}" 1>/dev/null
}

_koopa_extract() {  # {{{1
    # """
    # Extract compressed files automatically.
    # @note Updated 2020-02-13.
    #
    # As suggested by Mendel Cooper in "Advanced Bash Scripting Guide".
    #
    # See also:
    # - https://github.com/stephenturner/oneliners
    # """
    local file
    file="${1:?}"
    if [ ! -f "$file" ]
    then
        _koopa_stop "Invalid file: '${file}'."
    fi
    _koopa_h2 "Extracting '${file}'."
    case "$file" in
        *.tar.bz2)
            tar -xj -f "$file"
            ;;
        *.tar.gz)
            tar -xz -f "$file"
            ;;
        *.tar.xz)
            tar -xJ -f "$file"
            ;;
        *.bz2)
            _koopa_assert_is_installed bunzip2
            bunzip2 "$file"
            ;;
        *.gz)
            gunzip "$file"
            ;;
        *.rar)
            _koopa_assert_is_installed unrar
            unrar -x "$file"
            ;;
        *.tar)
            tar -x -f "$file"
            ;;
        *.tbz2)
            tar -xj -f "$file"
            ;;
        *.tgz)
            tar -xz -f "$file"
            ;;
        *.xz)
            _koopa_assert_is_installed xz
            xz --decompress "$file"
            ;;
        *.zip)
            _koopa_assert_is_installed unzip
            unzip -qq "$file"
            ;;
        *.Z)
            uncompress "$file"
            ;;
        *.7z)
            _koopa_assert_is_installed 7z
            7z -x "$file"
            ;;
        *)
            _koopa_stop "Unsupported extension: '${file}'."
            ;;
   esac
   return 0
}

_koopa_find_local_bin_dirs() {  # {{{1
    # """
    # Find local bin directories.
    # @note Updated 2020-03-28.
    #
    # See also:
    # - https://stackoverflow.com/questions/23356779
    # - https://stackoverflow.com/questions/7442417
    # """
    local prefix
    prefix="$(_koopa_make_prefix)"
    local x
    x="$( \
        find "$prefix" \
            -mindepth 2 \
            -maxdepth 3 \
            -type d \
            -name "bin" \
            -not -path "*/Caskroom/*" \
            -not -path "*/Cellar/*" \
            -not -path "*/Homebrew/*" \
            -not -path "*/anaconda3/*" \
            -not -path "*/bcbio/*" \
            -not -path "*/conda/*" \
            -not -path "*/lib/*" \
            -not -path "*/miniconda3/*" \
            -not -path "*/opt/*" \
            -print | sort \
    )"
    _koopa_print "$x"
}

_koopa_fix_sudo_setrlimit_error() {  # {{{1
    # """
    # Fix bug in recent version of sudo.
    # @note Updated 2020-03-16.
    #
    # This is popping up on Docker builds:
    # sudo: setrlimit(RLIMIT_CORE): Operation not permitted
    #
    # @seealso
    # - https://ask.fedoraproject.org/t/
    #       sudo-setrlimit-rlimit-core-operation-not-permitted/4223
    # - https://bugzilla.redhat.com/show_bug.cgi?id=1773148
    # """
    local target_file
    target_file='/etc/sudo.conf'
    # Ensure we always overwrite for Docker images.
    # Note that Fedora base image contains this file by default.
    if ! _koopa_is_docker
    then
        [ -e "$target_file" ] && return 0
    fi
    local source_file
    source_file="$(_koopa_prefix)/os/linux/etc/sudo.conf"
    sudo cp -v "$source_file" "$target_file"
    return 0
}

_koopa_github_url() {  # {{{1
    # """
    # Koopa GitHub URL.
    # @note Updated 2020-04-16.
    # """
    _koopa_variable 'koopa-github-url'
    return 0
}

_koopa_gnu_mirror() {  # {{{1
    # """
    # Get GNU FTP mirror URL.
    # @note Updated 2020-04-16.
    # """
    _koopa_variable 'gnu-mirror'
    return 0
}

_koopa_group() {  # {{{1
    # """
    # Return the appropriate group to use with koopa installation.
    # @note Updated 2020-04-16.
    #
    # Returns current user for local install.
    # Dynamically returns the admin group for shared install.
    #
    # Admin group priority: admin (macOS), sudo (Debian), wheel (Fedora).
    # """
    local group
    if _koopa_is_shared_install
    then
        group="$(_koopa_admin_group)"
    else
        group="$(_koopa_current_group)"
    fi
    _koopa_print "$group"
    return 0
}

_koopa_header() {  # {{{1
    # """
    # Source script header.
    # @note Updated 2020-01-16.
    #
    # Useful for private scripts using koopa code outside of package.
    # """
    local header_type
    header_type="${1:?}"
    local koopa_prefix
    koopa_prefix="$(_koopa_prefix)"
    local file
    case "$header_type" in
        # shell ----------------------------------------------------------------
        bash)
            file="${koopa_prefix}/shell/bash/include/header.sh"
            ;;
        zsh)
            file="${koopa_prefix}/shell/zsh/include/header.sh"
            ;;
        # os -------------------------------------------------------------------
        amzn)
            file="${koopa_prefix}/os/amzn/include/header.sh"
            ;;
        centos)
            file="${koopa_prefix}/os/centos/include/header.sh"
            ;;
        darwin)
            file="${koopa_prefix}/os/darwin/include/header.sh"
            ;;
        debian)
            file="${koopa_prefix}/os/debian/include/header.sh"
            ;;
        fedora)
            file="${koopa_prefix}/os/fedora/include/header.sh"
            ;;
        linux)
            file="${koopa_prefix}/os/linux/include/header.sh"
            ;;
        macos)
            file="${koopa_prefix}/os/macos/include/header.sh"
            ;;
        rhel)
            file="${koopa_prefix}/os/rhel/include/header.sh"
            ;;
        ubuntu)
            file="${koopa_prefix}/os/ubuntu/include/header.sh"
            ;;
        # host -----------------------------------------------------------------
        aws)
            file="${koopa_prefix}/host/aws/include/header.sh"
            ;;
        azure)
            file="${koopa_prefix}/host/azure/include/header.sh"
            ;;
        *)
            _koopa_invalid_arg "$1"
            ;;
    esac
    _koopa_print "$file"
    return 0
}

_koopa_host_id() {  # {{{1
    # """
    # Simple host ID string to load up host-specific scripts.
    # @note Updated 2019-12-06.
    #
    # Currently intended to support AWS, Azure, and Harvard clusters.
    #
    # Returns useful host type matching either:
    # - VMs: "aws", "azure".
    # - HPCs: "harvard-o2", "harvard-odyssey".
    #
    # Returns empty for local machines and/or unsupported types.
    #
    # Alternatively, can use 'hostname -d' for reverse lookups.
    # """
    local id
    if [ -r /etc/hostname ]
    then
        id="$(cat /etc/hostname)"
    else
        _koopa_assert_is_installed hostname
        id="$(hostname -f)"
    fi
    case "$id" in
        # VMs
        *.ec2.internal)
            id="aws"
            ;;
        awslab*)
            id="aws"
            ;;
        azlab*)
            id="azure"
            ;;
        # HPCs
        *.o2.rc.hms.harvard.edu)
            id="harvard-o2"
            ;;
        *.rc.fas.harvard.edu)
            id="harvard-odyssey"
            ;;
    esac
    _koopa_print "$id"
    return 0
}

_koopa_ln() {  # {{{1
    # """
    # Create symlink quietly.
    # @note Updated 2020-03-02.
    # """
    local source_file
    source_file="${1:?}"

    local target_file
    target_file="${2:?}"
    _koopa_rm "$target_file"

    if _koopa_is_shared_install
    then
        sudo ln -fnsv "$source_file" "$target_file"
    else
        ln -fnsv "$source_file" "$target_file"
    fi

    return 0
}

_koopa_local_ip_address() {  # {{{1
    # """
    # Local IP address.
    # @note Updated 2020-02-23.
    #
    # Some systems (e.g. macOS) will return multiple IP address matches for
    # Ethernet and WiFi. Here we're simplying returning the first match, which
    # corresponds to the default on macOS.
    # """
    local x
    if _koopa_is_macos
    then
        x="$( \
            ifconfig \
            | grep "inet " \
            | grep "broadcast" \
            | awk '{print $2}' \
        )"
    else
        x="$( \
            hostname -I \
            | awk '{print $1}' \
        )"
    fi
    _koopa_print "$x" | head -n 1
    return 0
}

_koopa_make_build_string() {  # {{{1
    # """
    # OS build string for 'make' configuration.
    # @note Updated 2020-03-04.
    #
    # Use this for 'configure --build' flag.
    #
    # - macOS: x86_64-darwin15.6.0
    # - Linux: x86_64-linux-gnu
    # """
    if _koopa_is_macos
    then
        local mach
        mach="$(uname -m)"
        local os_type
        os_type="${OSTYPE:?}"
        string="${mach}-${os_type}"
    else
        string="x86_64-linux-gnu"
    fi
    _koopa_print "$string"
    return 0
}

_koopa_mkdir() {  # {{{1
    # """
    # mkdir with dynamic sudo handling.
    # @note Updated 2020-02-16.
    # """
    if _koopa_is_shared_install
    then
        sudo mkdir -p "$@"
    else
        mkdir -p "$@"
    fi
    _koopa_chmod "$(_koopa_chmod_flags)" "$@"
    _koopa_chgrp "$(_koopa_group)" "$@"
    return 0
}

_koopa_mktemp() {  # {{{1
    # """
    # Wrapper function for system 'mktemp'.
    # @note Updated 2020-04-16.
    #
    # Traditionally, many shell scripts take the name of the program with the
    # pid as a suffix and use that as a temporary file name. This kind of
    # naming scheme is predictable and the race condition it creates is easy for
    # an attacker to win. A safer, though still inferior, approach is to make a
    # temporary directory using the same naming scheme. While this does allow
    # one to guarantee that a temporary file will not be subverted, it still
    # allows a simple denial of service attack. For these reasons it is
    # suggested that mktemp be used instead.
    #
    # Note that old version of mktemp (e.g. macOS) only supports '-t' instead of
    # '--tmpdir' flag for prefix.
    #
    # See also:
    # - https://stackoverflow.com/questions/4632028
    # - https://stackoverflow.com/a/10983009/3911732
    # - https://gist.github.com/earthgecko/3089509
    # """
    _koopa_assert_is_installed mktemp

    local user_id
    user_id="$(_koopa_current_user_id)"
    local date_id
    date_id="$(date "+%Y%m%d%H%M%S")"
    local template
    template="koopa-${user_id}-${date_id}-XXXXXXXXXX"
    mktemp "$@" -t "$template"
    return 0
}

_koopa_mv() {  # {{{1
    # """
    # Koopa move.
    # @note Updated 2020-03-05.
    #
    # This function works on 1 file or directory at a time.
    # It ensures that the target parent directory exists automatically.
    # """
    local source_file
    source_file="${1:?}"

    local target_file
    target_file="${2:?}"

    local target_parent
    target_parent="$(dirname "$target_file")"
    _koopa_mkdir "$target_parent"

    if _koopa_is_shared_install
    then
        sudo mv -Tf --strip-trailing-slashes "$@"
    else
        mv -Tf --strip-trailing-slashes "$@"
    fi

    return 0
}

_koopa_os_codename() {  # {{{1
    # """
    # Operating system code name.
    # @note Updated 2020-02-27.
    #
    # Alternate approach:
    # > awk -F= '$1=="VERSION_CODENAME" { print $2 ;}' /etc/os-release \
    # >     | tr -d '"'
    # """
    _koopa_assert_is_debian
    _koopa_assert_is_installed lsb_release
    local os_codename
    if _koopa_is_kali
    then
        os_codename="buster"
    else
        os_codename="$(lsb_release -cs)"
    fi
    _koopa_print "$os_codename"
    return 0
}

_koopa_os_id() {  # {{{1
    # """
    # Operating system ID.
    # @note Updated 2020-02-27.
    #
    # Just return the OS platform ID (e.g. "debian").
    # """
    local os_id
    if _koopa_is_kali
    then
        os_id="debian"
    else
        os_id="$(_koopa_os_string | cut -d '-' -f 1)"
    fi
    _koopa_print "$os_id"
    return 0
}

_koopa_os_string() {  # {{{1
    # """
    # Operating system string.
    # @note Updated 2020-01-13.
    #
    # Returns 'ID' and major 'VERSION_ID' separated by a '-'.
    #
    # Always returns lowercase, with unique names for Linux distros
    # (e.g. "rhel-8").
    #
    # Alternatively, use hostnamectl.
    # https://linuxize.com/post/how-to-check-linux-version/
    local id
    local version
    local string
    if _koopa_is_macos
    then
        # > id="$(uname -s | tr '[:upper:]' '[:lower:]')"
        id="macos"
        version="$(_koopa_get_version "$id")"
        version="$(_koopa_major_minor_version "$version")"
    elif _koopa_is_linux
    then
        if [ -r /etc/os-release ]
        then
            id="$( \
                awk -F= '$1=="ID" { print $2 ;}' /etc/os-release \
                | tr -d '"' \
            )"
            # Include the major release version.
            version="$( \
                awk -F= '$1=="VERSION_ID" { print $2 ;}' /etc/os-release \
                | tr -d '"'
            )"
            if [ -n "$version" ]
            then
                version="$(_koopa_major_version "$version")"
            else
                # This is the case for Arch Linux.
                version="rolling"
            fi
        else
            id="linux"
        fi
    fi
    if [ -z "$id" ]
    then
        _koopa_stop "Failed to detect OS ID."
    fi
    string="$id"
    if [ -n "${version:-}" ]
    then
        string="${string}-${version}"
    fi
    _koopa_print "$string"
    return 0
}

_koopa_public_ip_address() {  # {{{1
    # """
    # Public (remote) IP address.
    # @note Updated 2020-02-23.
    #
    # @seealso
    # https://www.cyberciti.biz/faq/
    #     how-to-find-my-public-ip-address-from-command-line-on-a-linux/
    # """
    _koopa_is_installed dig || return 1
    local x
    x="$(dig +short myip.opendns.com @resolver1.opendns.com)"
    _koopa_print "$x"
    return 0
}

_koopa_python_remove_pycache() {  # {{{1
    # """
    # Remove Python '__pycache__/' from site packages.
    # @note Updated 2020-02-19.
    #
    # These directories can create permission issues when attempting to rsync
    # installation across multiple VMs.
    # """
    local prefix
    prefix="${1:-}"
    if [ -z "$prefix" ]
    then
        # e.g. /usr/local/cellar/python/3.8.1
        local python
        python="$(_koopa_which_realpath "python3")"
        prefix="$(realpath "$(dirname "$python")/..")"
    fi
    _koopa_h2 "Removing pycache in '${prefix}'."
    # > find "$prefix" \
    # >     -type d \
    # >     -name "__pycache__" \
    # >     -print0 \
    # >     -exec rm -frv "{}" \;
    find "$prefix" \
        -type d \
        -name "__pycache__" \
        -print0 \
        | xargs -0 -I {} rm -frv "{}"
    return 0
}

_koopa_relink() {  # {{{1
    # """
    # Re-create a symbolic link dynamically, if broken.
    # @note Updated 2020-02-16.
    # """
    local source_file
    source_file="${1:?}"
    local dest_file
    dest_file="${2:?}"
    # Relaxing this check, in case dotfiles haven't been cloned.
    [ -e "$source_file" ] || return 0
    [ -L "$dest_file" ] && return 0
    _koopa_rm "$dest_file"
    ln -fns "$source_file" "$dest_file"
    return 0
}

_koopa_rm() {  # {{{1
    # """
    # Remove files/directories without dealing with permissions.
    # @note Updated 2020-02-16.
    # """
    if _koopa_is_shared_install
    then
        sudo rm -fr "$@" > /dev/null 2>&1
    else
        rm -fr "$@" > /dev/null 2>&1
    fi
    return 0
}

_koopa_rsync_flags() {  # {{{1
    # """
    # rsync flags.
    # @note Updated 2020-04-06.
    #
    #     --delete-before         receiver deletes before xfer, not during
    #     --iconv=CONVERT_SPEC    request charset conversion of filenames
    #     --numeric-ids           don't map uid/gid values by user/group name
    #     --partial               keep partially transferred files
    #     --progress              show progress during transfer
    # -A, --acls                  preserve ACLs (implies -p)
    # -H, --hard-links            preserve hard links
    # -L, --copy-links            transform symlink into referent file/dir
    # -O, --omit-dir-times        omit directories from --times
    # -P                          same as --partial --progress
    # -S, --sparse                handle sparse files efficiently
    # -X, --xattrs                preserve extended attributes
    # -a, --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
    # -g, --group                 preserve group
    # -h, --human-readable        output numbers in a human-readable format
    # -n, --dry-run               perform a trial run with no changes made
    # -o, --owner                 preserve owner (super-user only)
    # -r, --recursive             recurse into directories
    # -x, --one-file-system       don't cross filesystem boundaries    
    # -z, --compress              compress file data during the transfer
    #
    # Use '--rsync-path="sudo rsync"' to sync across machines with sudo.
    #
    # See also:
    # - https://unix.stackexchange.com/questions/165423
    # """
    _koopa_print "--archive --delete-before --human-readable --progress"
    return 0
}

_koopa_set_sticky_group() {  # {{{1
    # """
    # Set sticky group bit for target prefix(es).
    # @note Updated 2020-01-24.
    #
    # This never works recursively.
    # """
    _koopa_chmod g+s "$@"
    return 0
}

_koopa_shell() {  # {{{1
    # """
    # Current shell.
    # @note Updated 2020-03-28.
    #
    # @seealso
    # - https://stackoverflow.com/questions/3327013
    # """
    local shell
    if [ -n "${BASH_VERSION:-}" ]
    then
        shell='bash'
    elif [ -n "${ZSH_VERSION:-}" ]
    then
        shell='zsh'
    elif [ -d '/proc' ]
    then
        # Standard approach on Linux.
        shell="$(basename "$(readlink /proc/$$/exe)")"
    else
        # This approach works on macOS.
        # The sed step converts '-zsh' to 'zsh', for example.
        # The basename step handles the case when ps returns full path.
        # This can happen inside of editors, such as vim.
        shell="$(basename "$(ps -p "$$" -o 'comm=' | sed 's/^-//g')")"
    fi
    _koopa_print "$shell"
    return 0
}

_koopa_test_find_files() {  # {{{1
    # """
    # Find relevant files for unit tests.
    # @note Updated 2020-03-28.
    # """
    local prefix
    prefix="$(_koopa_prefix)"
    local x
    x="$( \
        find "$prefix" \
            -mindepth 1 \
            -type f \
            -not -name "$(basename "$0")" \
            -not -name "*.md" \
            -not -name ".pylintrc" \
            -not -path "${prefix}/.git/*" \
            -not -path "${prefix}/cellar/*" \
            -not -path "${prefix}/coverage/*" \
            -not -path "${prefix}/dotfiles/*" \
            -not -path "${prefix}/opt/*" \
            -not -path "${prefix}/tests/*" \
            -not -path "*/etc/R/*" \
            -print | sort \
    )"
    _koopa_print "$x"
}

_koopa_test_true_color() {  # {{{1
    # """
    # Test 24-bit true color support.
    # @note Updated 2020-02-15.
    #
    # @seealso
    # https://jdhao.github.io/2018/10/19/tmux_nvim_true_color/
    # """
    awk 'BEGIN{
        s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
        for (colnum = 0; colnum<77; colnum++) {
            r = 255-(colnum*255/76);
            g = (colnum*510/76);
            b = (colnum*255/76);
            if (g>255) g = 510-g;
            printf "\033[48;2;%d;%d;%dm", r,g,b;
            printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
            printf "%s\033[0m", substr(s,colnum+1,1);
        }
        printf "\n";
    }'
    return 0
}

_koopa_tmp_dir() {  # {{{1
    # """
    # Create temporary directory.
    # @note Updated 2020-02-06.
    # """
    _koopa_mktemp -d
    return 0
}

_koopa_tmp_file() {  # {{{1
    # """
    # Create temporary file.
    # @note Updated 2020-02-06.
    # """
    _koopa_mktemp
    return 0
}

_koopa_tmp_log_file() {  # {{{1
    # """
    # Create temporary log file.
    # @note Updated 2020-02-27.
    #
    # Used primarily for debugging cellar make install scripts.
    #
    # Note that mktemp on macOS and BusyBox doesn't support '--suffix' flag.
    # Otherwise, we can use:
    # > _koopa_mktemp --suffix=".log"
    # """
    _koopa_tmp_file
    return 0
}

_koopa_umask() {  # {{{1
    # """
    # Set default file permissions.
    # @note Updated 2020-06-03.
    #
    # - 'umask': Files and directories.
    # - 'fmask': Only files.
    # - 'dmask': Only directories.
    #
    # Use 'umask -S' to return 'u,g,o' values.
    #
    # - 0022: u=rwx,g=rx,o=rx
    #         User can write, others can read. Usually default.
    # - 0002: u=rwx,g=rwx,o=rx
    #         User and group can write, others can read.
    #         Recommended setting in a shared coding environment.
    # - 0077: u=rwx,g=,o=
    #         User alone can read/write. More secure.
    #
    # Access control lists (ACLs) are sometimes preferable to umask.
    #
    # Here's how to use ACLs with setfacl.
    # > setfacl -d -m group:name:rwx /dir
    #
    # @seealso
    # - https://stackoverflow.com/questions/13268796
    # - https://askubuntu.com/questions/44534
    # """
    umask 0002
    return 0
}

_koopa_url() {  # {{{1
    # """
    # Koopa URL.
    # @note Updated 2020-04-16.
    # """
    _koopa_variable 'koopa-url'
    return 0
}

_koopa_user() {  # {{{1
    # """
    # Set the default user.
    # @note Updated 2020-04-16.
    # """
    local user
    if _koopa_is_shared_install
    then
        user='root'
    else
        user="$(_koopa_current_user)"
    fi
    _koopa_print "$user"
    return 0
}

_koopa_variable() {  # {{{1
    # """
    # Get version stored internally in versions.txt file.
    # @note Updated 2020-02-27.
    # """
    local file
    file="$(_koopa_prefix)/system/include/variables.txt"
    local key
    key="${1:?}"
    local value
    # Note that this approach handles inline comments.
    value="$( \
        grep -Eo "^${key}=\"[^\"]+\"" "$file" \
        || _koopa_stop "'${key}' not defined in '${file}'." \
    )"
    value="$( \
        _koopa_print "$value" \
            | head -n 1 \
            | cut -d "\"" -f 2
    )"
    _koopa_print "$value"
    return 0
}

_koopa_view_latest_tmp_log_file() {  # {{{1
    # """
    # View the latest temporary log file.
    # @note Updated 2020-04-16.
    # """
    local dir
    dir="${TMPDIR:-/tmp}"
    local log_file
    log_file="$( \
        find "$dir" \
            -mindepth 1 \
            -maxdepth 1 \
            -type f \
            -name "koopa-$(_koopa_current_user_id)-*" \
            | sort \
            | tail -n 1 \
    )"
    [ -f "$log_file" ] || return 1
    _koopa_h1 "Viewing '${log_file}'."
    # Note that this will skip to the end automatically.
    less +G "$log_file"
    return 0
}
