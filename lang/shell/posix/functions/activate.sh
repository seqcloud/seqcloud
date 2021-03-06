#!/bin/sh

_koopa_activate_aspera() { # {{{1
    # """
    # Include Aspera Connect binaries in PATH, if defined.
    # @note Updated 2020-06-30.
    # """
    _koopa_activate_prefix "$(_koopa_aspera_prefix)/latest"
    return 0
}

_koopa_activate_bcbio() { # {{{1
    # """
    # Activate bcbio-nextgen tool binaries.
    # @note Updated 2021-03-02.
    #
    # Attempt to locate bcbio installation automatically on supported platforms.
    #
    # Exporting at the end of PATH so we don't mask gcc or R.
    # This is particularly important to avoid unexpected compilation issues
    # due to compilers in conda masking the system versions.
    # """
    # shellcheck disable=SC2039
    local prefix
    _koopa_is_linux || return 0
    _koopa_is_installed bcbio_nextgen.py && return 0
    prefix="$(_koopa_bcbio_tools_prefix)"
    [ -d "$prefix" ] || return 0
    _koopa_force_add_to_path_end "${prefix}/bin"
    unset -v PYTHONHOME PYTHONPATH
    return 0
}

_koopa_activate_conda() { # {{{1
    # """
    # Activate conda.
    # @note Updated 2020-11-19.
    #
    # It's no longer recommended to directly export conda in '$PATH'.
    # Instead source the 'activate' script.
    # This must be reloaded inside of subshells to work correctly.
    # """
    # shellcheck disable=SC2039
    local name nounset prefix
    prefix="${1:-}"
    [ -z "$prefix" ] && prefix="$(_koopa_opt_prefix)/conda"
    [ -d "$prefix" ] || return 0
    name="${2:-base}"
    script="${prefix}/bin/activate"
    [ -r "$script" ] || return 0
    nounset="$(_koopa_boolean_nounset)"
    [ "$nounset" -eq 1 ] && set +u
    # shellcheck source=/dev/null
    . "$script"
    # Ensure base environment gets deactivated by default.
    if [ "$name" = 'base' ]
    then
        # Don't use the full conda path here; will return config error.
        conda deactivate
    fi
    [ "$nounset" -eq 1 ] && set -u
    return 0
}

_koopa_activate_coreutils() { # {{{1
    # """
    # Activate hardened interactive aliases for coreutils.
    # @note Updated 2021-01-07.
    #
    # These aliases get unaliased inside of koopa scripts, and they should only
    # apply to interactive use at the command prompt.
    #
    # macOS ships with a very old version of GNU coreutils. Use Homebrew.
    # """
    _koopa_has_gnu_coreutils || return 0
    # The '--archive/-a' flag seems to have issues on some file systems.
    alias cp='cp --interactive' # -i
    alias ln='ln --interactive --no-dereference --symbolic' # -ins
    alias mkdir='mkdir --parents' # -p
    alias mv='mv --interactive' # -i
    # Problematic on some file systems: --dir --preserve-root
    alias rm='rm --interactive=once' # -I
    return 0
}

_koopa_activate_emacs() { # {{{1
    # """
    # Activate Emacs.
    # @note Updated 2020-06-30.
    # """
    _koopa_activate_prefix "${HOME}/.emacs.d"
    return 0
}

_koopa_activate_ensembl_perl_api() { # {{{1
    # """
    # Activate Ensembl Perl API.
    # @note Updated 2020-12-31.
    #
    # Note that this currently requires Perl 5.26.
    # > perlbrew switch perl-5.26
    # """
    # shellcheck disable=SC2039
    local prefix
    prefix="$(_koopa_ensembl_perl_api_prefix)"
    [ -d "$prefix" ] || return 0
    _koopa_activate_prefix "${prefix}/ensembl-git-tools"
    PERL5LIB="${PERL5LIB}:${prefix}/bioperl-1.6.924"
    PERL5LIB="${PERL5LIB}:${prefix}/ensembl/modules"
    PERL5LIB="${PERL5LIB}:${prefix}/ensembl-compara/modules"
    PERL5LIB="${PERL5LIB}:${prefix}/ensembl-variation/modules"
    PERL5LIB="${PERL5LIB}:${prefix}/ensembl-funcgen/modules"
    export PERL5LIB
    return 0
}

_koopa_activate_gcc_colors() { # {{{1
    # """
    # Activate GCC colors.
    # @note Updated 2020-06-30.
    # """
    # Colored GCC warnings and errors.
    [ -n "${GCC_COLORS:-}" ] && return 0
    export GCC_COLORS="caret=01;32:error=01;31:locus=01:note=01;36:\
quote=01:warning=01;35"
    return 0
}

_koopa_activate_go() { # {{{1
    # """
    # Activate Go.
    # @note Updated 2020-11-23.
    # """
    # shellcheck disable=SC2039
    local prefix
    prefix="$(_koopa_go_prefix)/latest"
    [ -d "$prefix" ] && _koopa_activate_prefix "$prefix"
    _koopa_is_installed go || return 0
    [ -z "${GOPATH:-}" ] && GOPATH="$(_koopa_go_gopath)"
    export GOPATH
    # This can error on shared installs, so skip.
    # > [ ! -d "$GOPATH" ] && mkdir -p "$GOPATH"
    return 0
}

_koopa_activate_homebrew() { # {{{1
    # """
    # Activate Homebrew.
    # @note Updated 2021-03-02.
    # """
    # shellcheck disable=SC2039
    local prefix
    prefix="$(_koopa_homebrew_prefix)"
    if ! _koopa_is_installed brew
    then
        _koopa_activate_prefix "$prefix"
    fi
    _koopa_is_installed brew || return 0
    export HOMEBREW_INSTALL_CLEANUP=1
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    # Stopgap fix for TLS SSL issues with some Homebrew casks.
    if [ -x "${prefix}/opt/curl/bin/curl" ]
    then
        export HOMEBREW_FORCE_BREWED_CURL=1
    fi
    if _koopa_is_macos
    then
        export HOMEBREW_CASK_OPTS='--no-quarantine'
    fi
    _koopa_activate_homebrew_prefix binutils
    _koopa_activate_homebrew_gnu_prefix coreutils
    _koopa_activate_homebrew_gnu_prefix findutils
    _koopa_activate_homebrew_gnu_prefix gnu-sed
    _koopa_activate_homebrew_gnu_prefix gnu-tar
    _koopa_activate_homebrew_gnu_prefix gnu-units
    _koopa_activate_homebrew_gnu_prefix grep
    _koopa_activate_homebrew_gnu_prefix make
    _koopa_activate_homebrew_libexec_prefix man-db
    _koopa_activate_homebrew_prefix bc
    _koopa_activate_homebrew_prefix curl
    _koopa_activate_homebrew_prefix icu4c
    _koopa_activate_homebrew_prefix ncurses
    _koopa_activate_homebrew_prefix ruby
    _koopa_activate_homebrew_prefix sqlite
    _koopa_activate_homebrew_prefix texinfo
    _koopa_activate_homebrew_google_cloud_sdk
    _koopa_activate_homebrew_ruby_gems
    _koopa_activate_homebrew_python
    return 0
}

_koopa_activate_homebrew_gnu_prefix() { # {{{1
    # """
    # Activate a Homebrew cellar-only GNU program.
    # @note Updated 2020-11-23.
    #
    # Linked using 'g' prefix by default.
    #
    # Note that libtool is always prefixed with 'g', even in 'opt/'.
    #
    # @seealso:
    # - brew info binutils
    # - brew info coreutils
    # - brew info findutils
    # - brew info gnu-sed
    # - brew info gnu-tar
    # - brew info gnu-time
    # - brew info gnu-units
    # - brew info gnu-which
    # - brew info grep
    # - brew info libtool
    # - brew info make
    # """
    # shellcheck disable=SC2039
    local prefix
    prefix="$(_koopa_homebrew_prefix)/opt/${1:?}/libexec"
    [ -d "$prefix" ] || return 0
    _koopa_force_add_to_path_start "${prefix}/gnubin"
    _koopa_force_add_to_manpath_start "${prefix}/gnuman"
    return 0
}

_koopa_activate_homebrew_google_cloud_sdk() { # {{{1
    # """
    # Activate Homebrew Google Cloud SDK.
    # @note Updated 2020-11-16.
    # """
    # shellcheck disable=SC2039
    local prefix shell
    prefix="$(_koopa_homebrew_prefix)"
    prefix="${prefix}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
    [ -d "$prefix" ] || return 0
    shell="$(_koopa_shell)"
    # shellcheck source=/dev/null
    [ -f "${prefix}/path.${shell}.inc" ] && \
        . "${prefix}/path.${shell}.inc"
    # shellcheck source=/dev/null
    [ -f "${prefix}/completion.${shell}.inc" ] && \
        . "${prefix}/completion.${shell}.inc"
    return 0
}

_koopa_activate_homebrew_libexec_prefix() { # {{{1
    # """
    # Activate a Homebrew cellar-only program.
    # @note Updated 2020-06-30.
    # """
    _koopa_activate_prefix "$(_koopa_homebrew_prefix)/opt/${1:?}/libexec"
    return 0
}

_koopa_activate_homebrew_prefix() { # {{{1
    # """
    # Activate a Homebrew cellar-only program.
    # @note Updated 2020-06-30.
    # """
    _koopa_activate_prefix "$(_koopa_homebrew_prefix)/opt/${1:?}"
    return 0
}

_koopa_activate_homebrew_python() { # {{{1
    # """
    # Activate Homebrew Python.
    # @note Updated 2020-10-27.
    # """
    # shellcheck disable=SC2039
    local version
    version="$(_koopa_major_minor_version "$(_koopa_variable 'python')")"
    _koopa_activate_homebrew_prefix "python@${version}"
    return 0
}

_koopa_activate_homebrew_ruby_gems() { # {{{1
    # """
    # Activate Homebrew Ruby gems.
    # @note Updated 2020-12-31.
    #
    # @seealso
    # - https://github.com/Homebrew/homebrew-core/blob/master/Formula/ruby.rb
    # - https://stackoverflow.com/questions/12287882/
    # """
    _koopa_activate_prefix "$(_koopa_homebrew_ruby_gems_prefix)"
    return 0
}

_koopa_activate_koopa_paths() { # {{{1
    # """
    # Automatically configure koopa PATH and MANPATH.
    # @note Updated 2021-01-19.
    # """
    # shellcheck disable=SC2039
    local config_prefix distro_prefix koopa_prefix linux_prefix shell
    koopa_prefix="$(_koopa_prefix)"
    config_prefix="$(_koopa_config_prefix)"
    shell="$(_koopa_shell)"
    _koopa_activate_prefix "$koopa_prefix"
    _koopa_activate_prefix "${koopa_prefix}/lang/shell/${shell}"
    if _koopa_is_linux
    then
        linux_prefix="${koopa_prefix}/os/linux"
        distro_prefix="${linux_prefix}/distro"
        _koopa_activate_prefix "${linux_prefix}/common"
        if _koopa_is_debian_like
        then
            _koopa_activate_prefix "${distro_prefix}/debian"
            _koopa_is_ubuntu_like && \
                _koopa_activate_prefix "${distro_prefix}/ubuntu"
        elif _koopa_is_fedora_like
        then
            _koopa_activate_prefix "${distro_prefix}/fedora"
            _koopa_is_rhel_like && \
                _koopa_activate_prefix "${distro_prefix}/rhel"
        fi
    fi
    _koopa_activate_prefix "$(_koopa_distro_prefix)"
    _koopa_activate_prefix "${config_prefix}/scripts-private"
    return 0
}

_koopa_activate_llvm() { # {{{1
    # """
    # Activate LLVM config.
    # @note Updated 2020-08-05.
    # """
    # shellcheck disable=SC2039
    local config make_prefix
    [ -x "${LLVM_CONFIG:-}" ] && return 0
    make_prefix="$(_koopa_make_prefix)"
    if _koopa_is_macos
    then
        config="${make_prefix}/opt/llvm/bin/llvm-config"
    else
        # Note that findutils isn't installed on Linux distros by default
        # (e.g. Docker fedora image), and will error here otherwise.
        _koopa_is_installed find || return 0
        # Attempt to find the latest version automatically.
        config="$(find '/usr/bin' -name 'llvm-config-*' | sort | tail -n 1)"
    fi
    [ -x "$config" ] && export LLVM_CONFIG="$config"
    return 0
}

_koopa_activate_local_etc_profile() { # {{{1
    # """
    # Source 'profile.d' scripts in '/usr/local/etc'.
    # @note Updated 2020-08-05.
    #
    # Currently only supported for Bash.
    # """
    # shellcheck disable=SC2039
    local make_prefix prefix
    case "$(_koopa_shell)" in
        bash)
            ;;
        *)
            return 0
            ;;
    esac
    make_prefix="$(_koopa_make_prefix)"
    prefix="${make_prefix}/etc/profile.d"
    [ -d "$prefix" ] || return 0
    for script in "${prefix}/"*'.sh'
    do
        if [ -r "$script" ]
        then
            # shellcheck source=/dev/null
            . "$script"
        fi
    done
    return 0
}

_koopa_activate_local_paths() { # {{{1
    # """
    # Activate local user paths.
    # @note Updated 2020-12-31.
    # """
    _koopa_force_add_to_path_start \
        "${HOME}/bin" \
        "${HOME}/.local/bin"
    _koopa_force_add_to_manpath_start \
        "${HOME}/.local/share/man"
    return 0
}

_koopa_activate_macos_extras() { # {{{1
    # """
    # Activate macOS-specific extra settings.
    # @note Updated 2020-07-05.
    # """
    # Improve terminal colors.
    if [ -z "${CLICOLOR:-}" ]
    then
        export CLICOLOR=1
    fi
    # Refer to 'man ls' for 'LSCOLORS' section on color designators. #Note that
    # this doesn't get inherited by GNU coreutils, which uses 'LS_COLORS'.
    if [ -z "${LSCOLORS:-}" ]
    then
        export LSCOLORS='Gxfxcxdxbxegedabagacad'
    fi
    return 0
}

_koopa_activate_macos_python() { # {{{1
    # """
    # Activate macOS Python binary install.
    # @note Updated 2020-11-16.
    # """
    # shellcheck disable=SC2039
    local minor_version version
    _koopa_is_macos || return 1
    [ -z "${VIRTUAL_ENV:-}" ] || return 0
    version="$(_koopa_variable 'python')"
    minor_version="$(_koopa_major_minor_version "$version")"
    _koopa_activate_prefix "/Library/Frameworks/Python.framework/\
Versions/${minor_version}"
    return 0
}

_koopa_activate_nextflow() { # {{{1
    # """
    # Activate Nextflow configuration.
    # @note Updated 2020-07-21.
    # @seealso
    # - https://github.com/nf-core/smrnaseq/blob/master/docs/usage.md
    # """
    [ -z "${NXF_OPTS:-}" ] || return 0
    export NXF_OPTS='-Xms1g -Xmx4g'
    return 0
}

_koopa_activate_openjdk() { # {{{1
    # """
    # Activate OpenJDK.
    # @note Updated 2020-11-16.
    #
    # Use Homebrew instead to manage on macOS.
    #
    # We're using a symlink approach here to manage versions.
    # """
    # shellcheck disable=SC2039
    local prefix
    _koopa_is_linux || return 0
    prefix="$(_koopa_openjdk_prefix)/latest"
    [ -d "$prefix" ] || return 0
    _koopa_activate_prefix "$prefix"
    return 0
}

_koopa_activate_perlbrew() { # {{{1
    # """
    # Activate Perlbrew.
    # @note Updated 2020-06-30.
    #
    # Only attempt to autoload for bash or zsh.
    # Delete '~/.perlbrew' directory if you see errors at login.
    #
    # See also:
    # - https://perlbrew.pl
    # """
    # shellcheck disable=SC2039
    local nounset prefix script
    [ -n "${PERLBREW_ROOT:-}" ] && return 0
    ! _koopa_is_installed perlbrew || return 0
    _koopa_shell | grep -Eq '^(bash|zsh)$' || return 0
    prefix="$(_koopa_perlbrew_prefix)"
    [ -d "$prefix" ] || return 0
    script="${prefix}/etc/bashrc"
    [ -r "$script" ] || return 0
    nounset="$(_koopa_boolean_nounset)"
    [ "$nounset" -eq 1 ] && set +u
    # Note that this is also compatible with zsh.
    # shellcheck source=/dev/null
    . "$script"
    [ "$nounset" -eq 1 ] && set -u
    return 0
}

_koopa_activate_pipx() { # {{{1
    # """
    # Activate pipx for Python.
    # @note Updated 2021-01-01.
    #
    # Customize pipx location with environment variables.
    # https://pipxproject.github.io/pipx/installation/
    # """
    # shellcheck disable=SC2039
    local prefix
    _koopa_is_installed pipx || return 0
    prefix="$(_koopa_pipx_prefix)"
    PIPX_HOME="$prefix"
    PIPX_BIN_DIR="${prefix}/bin"
    _koopa_force_add_to_path_start "$PIPX_BIN_DIR"
    export PIPX_HOME PIPX_BIN_DIR
    return 0
}

_koopa_activate_pkg_config() { # {{{1
    # """
    # Configure PKG_CONFIG_PATH.
    # @note Updated 2021-02-26.
    #
    # Typical priorities (e.g. on Debian):
    # - /usr/local/lib/x86_64-linux-gnu/pkgconfig
    # - /usr/local/lib/pkgconfig
    # - /usr/local/share/pkgconfig
    # - /usr/lib/x86_64-linux-gnu/pkgconfig
    # - /usr/lib/pkgconfig
    # - /usr/share/pkgconfig
    #
    # These are defined primarily for R environment. In particular these make
    # building tricky pages from source, such as rgdal, sf and others  easier.
    #
    # This is necessary for rgdal, sf packages to install clean.
    #
    # @seealso
    # - https://askubuntu.com/questions/210210/
    # """
    # shellcheck disable=SC2039
    local homebrew_prefix make_prefix sys_pkg_config
    [ -n "${PKG_CONFIG_PATH:-}" ] && return 0
    make_prefix="$(_koopa_make_prefix)"
    sys_pkg_config='/usr/bin/pkg-config'
    if _koopa_is_installed "$sys_pkg_config"
    then
        PKG_CONFIG_PATH="$("$sys_pkg_config" --variable pc_path pkg-config)"
    fi
    _koopa_force_add_to_pkg_config_path_start \
        "${make_prefix}/share/pkgconfig" \
        "${make_prefix}/lib/pkgconfig" \
        "${make_prefix}/lib64/pkgconfig" \
        "${make_prefix}/lib/x86_64-linux-gnu/pkgconfig"
    if _koopa_is_macos && _koopa_is_installed brew
    then
        homebrew_prefix="$(_koopa_homebrew_prefix)"
        # This is useful for getting Ruby jekyll gem (requires ffi) to install.
        # Alternatively, this works but is annoying:
        # > gem install ffi -- --disable-system-libffi
        _koopa_force_add_to_pkg_config_path_start \
            "${homebrew_prefix}/opt/libffi/lib/pkgconfig"
    fi
    return 0
}

_koopa_activate_prefix() { # {{{1
    # """
    # Automatically configure PATH and MANPATH for a specified prefix.
    # @note Updated 2020-11-16.
    # """
    # shellcheck disable=SC2039
    local prefix
    for prefix in "$@"
    do
        [ -d "$prefix" ] || continue
        _koopa_force_add_to_path_start \
            "${prefix}/bin" \
            "${prefix}/sbin"
        _koopa_force_add_to_manpath_start \
            "${prefix}/man" \
            "${prefix}/share/man"
    done
    return 0
}

_koopa_activate_pyenv() { # {{{1
    # """
    # Activate Python version manager (pyenv).
    # @note Updated 2020-06-30.
    #
    # Note that pyenv forks rbenv, so activation is very similar.
    # """
    # shellcheck disable=SC2039
    local nounset prefix script
    _koopa_is_installed pyenv && return 0
    [ -n "${PYENV_ROOT:-}" ] && return 0
    prefix="$(_koopa_pyenv_prefix)"
    [ -d "$prefix" ] || return 0
    script="${prefix}/bin/pyenv"
    [ -r "$script" ] || return 0
    export PYENV_ROOT="$prefix"
    _koopa_activate_prefix "$prefix"
    nounset="$(_koopa_boolean_nounset)"
    [ "$nounset" -eq 1 ] && set +u
    eval "$("$script" init -)"
    [ "$nounset" -eq 1 ] && set -u
    return 0
}

_koopa_activate_python_site_packages() { # {{{1
    # """
    # Activate Python site packages library.
    # @note Updated 2020-12-31.
    #
    # This ensures that 'bin' will be added to PATH, which is useful when
    # installing via pip with '--target' flag.
    # """
    _koopa_activate_prefix "$(_koopa_python_site_packages_prefix)"
    return 0
}

_koopa_activate_python_startup() { # {{{1
    # """
    # Activate Python startup configuration.
    # @note Updated 2020-07-13.
    # @seealso
    # - https://stackoverflow.com/questions/33683744/
    # """
    # shellcheck disable=SC2039
    local file
    file="${HOME}/.pyrc"
    [ -f "$file" ] || return 0
    export PYTHONSTARTUP="$file"
    return 0
}

_koopa_activate_rbenv() { # {{{1
    # """
    # Activate Ruby version manager (rbenv).
    # @note Updated 2020-06-30.
    #
    # See also:
    # - https://github.com/rbenv/rbenv
    # """
    # shellcheck disable=SC2039
    local nounset prefix script
    if _koopa_is_installed rbenv
    then
        eval "$(rbenv init -)"
        return 0
    fi
    [ -n "${RBENV_ROOT:-}" ] && return 0
    prefix="$(_koopa_rbenv_prefix)"
    [ -d "$prefix" ] || return 0
    script="${prefix}/bin/rbenv"
    [ -r "$script" ] || return 0
    export RBENV_ROOT="$prefix"
    _koopa_activate_prefix "$prefix"
    nounset="$(_koopa_boolean_nounset)"
    [ "$nounset" -eq 1 ] && set +u
    eval "$("$script" init -)"
    [ "$nounset" -eq 1 ] && set -u
    return 0
}

_koopa_activate_ruby() { # {{{1
    # """
    # Activate Ruby gems.
    # @note Updated 2020-12-31.
    # """
    # shellcheck disable=SC2039
    local prefix
    prefix="$(_koopa_ruby_gems_prefix)"
    _koopa_activate_prefix "$(_koopa_ruby_gems_prefix)"
    export GEM_HOME="$prefix"
    return 0
}

_koopa_activate_rust() { # {{{1
    # """
    # Activate Rust programming language.
    # @note Updated 2020-11-24.
    #
    # Attempt to locate cargo home and source the env script.
    # This will put the rust cargo programs defined in 'bin/' in the PATH.
    #
    # Alternatively, can just add '${cargo_home}/bin' to PATH.
    # """
    # shellcheck disable=SC2039
    local cargo_prefix nounset script rustup_prefix
    cargo_prefix="$(_koopa_rust_cargo_prefix)"
    rustup_prefix="$(_koopa_rust_rustup_prefix)"
    [ -d "$cargo_prefix" ] || return 0
    [ -d "$rustup_prefix" ] || return 0
    script="${cargo_prefix}/env"
    [ -r "$script" ] || return 0
    nounset="$(_koopa_boolean_nounset)"
    [ "$nounset" -eq 1 ] && set +u
    export CARGO_HOME="$cargo_prefix"
    export RUSTUP_HOME="$rustup_prefix"
    # shellcheck source=/dev/null
    . "$script"
    [ "$nounset" -eq 1 ] && set -u
    return 0
}

_koopa_activate_secrets() { # {{{1
    # """
    # Source secrets file.
    # @note Updated 2020-07-07.
    # """
    # shellcheck disable=SC2039
    local file
    file="${1:-}"
    [ -z "$file" ] && file="${HOME}/.secrets"
    [ -r "$file" ] || return 0
    # shellcheck source=/dev/null
    . "$file"
    return 0
}

_koopa_activate_ssh_key() { # {{{1
    # """
    # Import an SSH key automatically.
    # @note Updated 2020-06-30.
    #
    # NOTE: SCP will fail unless this is interactive only.
    # ssh-agent will prompt for password if there's one set.
    #
    # To change SSH key passphrase:
    # > ssh-keygen -p
    #
    # List currently loaded keys:
    # > ssh-add -L
    # """
    # shellcheck disable=SC2039
    local key
    _koopa_is_linux || return 0
    _koopa_is_interactive || return 0
    key="${1:-}"
    if [ -z "$key" ] && [ -n "${SSH_KEY:-}" ]
    then
        key="$SSH_KEY"
    else
        key="${HOME}/.ssh/id_rsa"
    fi
    [ -r "$key" ] || return 0
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add "$key" >/dev/null 2>&1
    return 0
}

_koopa_activate_standard_paths() { # {{{1
    # """
    # Activate standard paths.
    # @note Updated 2020-12-31.
    #
    # Note that here we're making sure local binaries are included.
    # Inspect '/etc/profile' if system PATH appears misconfigured.
    #
    # @seealso
    # - https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
    # """
    # shellcheck disable=SC2039
    local make_prefix
    make_prefix="$(_koopa_make_prefix)"
    _koopa_add_to_path_end \
        '/usr/sbin' \
        '/usr/bin' \
        '/sbin' \
        '/bin'
    _koopa_add_to_manpath_end \
        '/usr/share/man'
    _koopa_force_add_to_path_start \
        "${make_prefix}/bin" \
        "${make_prefix}/sbin" \
    _koopa_force_add_to_manpath_start \
        "${make_prefix}/share/man"
    return 0
}

_koopa_activate_venv() { # {{{1
    # """
    # Activate Python virtual environment.
    # @note Updated 2020-06-30.
    #
    # Note that we're using this instead of conda as our default interactive
    # Python environment, so we can easily use pip.
    #
    # Here's how to write a function to detect virtual environment name:
    # https://stackoverflow.com/questions/10406926
    #
    # Only attempt to autoload for bash or zsh.
    #
    # This needs to be run last, otherwise PATH can get messed upon
    # deactivation, due to venv's current poor approach via '_OLD_VIRTUAL_PATH'.
    #
    # Refer to 'declare -f deactivate' for function source code.
    # """
    # shellcheck disable=SC2039
    local name nounset prefix script
    [ -n "${VIRTUAL_ENV:-}" ] && return 0
    _koopa_str_match_regex "$(_koopa_shell)" '^(bash|zsh)$' || return 0
    name="${1:-base}"
    prefix="$(_koopa_venv_prefix)"
    script="${prefix}/${name}/bin/activate"
    [ -r "$script" ] || return 0
    nounset="$(_koopa_boolean_nounset)"
    [ "$nounset" -eq 1 ] && set +u
    # shellcheck source=/dev/null
    . "$script"
    [ "$nounset" -eq 1 ] && set -u
    return 0
}

_koopa_activate_xdg() { # {{{1
    # """
    # Activate XDG base directory specification.
    # @note Updated 2020-08-05.
    #
    # XDG_RUNTIME_DIR:
    # - Can only exist for the duration of the user's login.
    # - Updated every 6 hours or set sticky bit if persistence is desired.
    # - Should not store large files as it may be mounted as a tmpfs.
    #
    # > if [ ! -d "$XDG_RUNTIME_DIR" ]
    # > then
    # >     mkdir -pv "$XDG_RUNTIME_DIR"
    # >     chown "$USER" "$XDG_RUNTIME_DIR"
    # >     chmod 0700 "$XDG_RUNTIME_DIR"
    # > fi
    #
    # @seealso
    # - https://developer.gnome.org/basedir-spec/
    # - https://wiki.archlinux.org/index.php/XDG_Base_Directory
    # """
    # shellcheck disable=SC2039
    local make_prefix
    make_prefix="$(_koopa_make_prefix)"
    [ -z "${XDG_CACHE_HOME:-}" ] && \
        XDG_CACHE_HOME="${HOME}/.cache"
    [ -z "${XDG_CONFIG_DIRS:-}" ] && \
        XDG_CONFIG_DIRS='/etc/xdg'
    [ -z "${XDG_CONFIG_HOME:-}" ] && \
        XDG_CONFIG_HOME="${HOME}/.config"
    [ -z "${XDG_DATA_DIRS:-}" ] && \
        XDG_DATA_DIRS="${make_prefix}/share:/usr/share"
    [ -z "${XDG_DATA_HOME:-}" ] && \
        XDG_DATA_HOME="${HOME}/.local/share"
    if [ -z "${XDG_RUNTIME_DIR:-}" ]
    then
        XDG_RUNTIME_DIR="/run/user/$(_koopa_user_id)"
        _koopa_is_macos && XDG_RUNTIME_DIR="/tmp${XDG_RUNTIME_DIR}"
    fi
    export \
        XDG_CACHE_HOME \
        XDG_CONFIG_DIRS \
        XDG_CONFIG_HOME \
        XDG_DATA_DIRS \
        XDG_DATA_HOME \
        XDG_RUNTIME_DIR
    return 0
}
