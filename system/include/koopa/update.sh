#!/usr/bin/env bash

# e.g. /usr/local/koopa
koopa_prefix="$(_koopa_prefix)"
# e.g. ~/.config/koopa
config_prefix="$(_koopa_config_prefix)"
# e.g. /usr/local/opt
app_prefix="$(_koopa_app_prefix)"
# e.g. /usr/local
make_prefix="$(_koopa_make_prefix)"

system=0
user=0
verbose=0

# Detect if rsync configuration is enabled. Note that we're allowing the user to
# override automatic detection with '--no-rsync' flag.
if _koopa_has_rsync_config
then
    rsync=1
else
    rsync=0
fi

while (("$#"))
do
    case "$1" in
        --no-rsync)
            rsync=0
            shift 1
            ;;
        --system)
            system=1
            shift 1
            ;;
        --user)
            user=1
            shift 1
            ;;
        --verbose)
            verbose=1
            shift 1
            ;;
        *)
            _koopa_invalid_arg "$1"
            ;;
    esac
done

if [[ "$verbose" -eq 1 ]]
then
    set -x
fi

# Allow passthrough of specific arguments to 'configure-vm' script.
configure_flags=()
if [[ "$rsync" -eq 0 ]]
then
    configure_flags+=("--no-rsync")
fi

_koopa_h1 "Updating koopa at '${koopa_prefix}'."

# Note that stable releases are not git, and can't be updated.
if ! _koopa_is_git "$koopa_prefix"
then
    version="$(_koopa_version)"
    url="$(_koopa_url)"
    _koopa_note "Stable release of koopa ${version} detected."
    _koopa_note "To update, first run the 'uninstall' script."
    _koopa_note "Then run the default install command at '${url}'."
    exit 1
fi

_koopa_set_permissions --recursive "$koopa_prefix"

(
    cd "$koopa_prefix" || exit 1
    _koopa_git_pull
    cd "${koopa_prefix}/dotfiles" || exit 1
    _koopa_git_reset
    _koopa_git_pull
) 2>&1 | tee "$(_koopa_tmp_log_file)"

_koopa_set_permissions --recursive "$koopa_prefix"

_koopa_update_xdg_config

if [[ "$system" -eq 1 ]]
then
    _koopa_h1 "Updating system configuration."
    _koopa_assert_has_sudo

    _koopa_dl "app prefix" "${app_prefix}"
    _koopa_dl "config prefix" "${config_prefix}"
    _koopa_dl "make prefix" "${make_prefix}"

    if _koopa_is_linux
    then
        _koopa_update_etc_profile_d
        _koopa_update_ldconfig
    fi

    if _koopa_is_macos
    then
        update-homebrew
        # Homebrew doesn't currently update Google Cloud SDK correctly.
        update-google-cloud-sdk
        update-microsoft-office
        # > update-macos
    elif _koopa_is_installed configure-vm
    then
        configure-vm "${configure_flags[@]}"
    fi

    if [[ "$rsync" -eq 1 ]]
    then
        update-r-packages
        update-conda
        update-python-packages
        update-rust
        update-rust-packages
        update-perlbrew
        if _koopa_is_linux
        then
            update-pyenv
            update-rbenv
        fi
    fi
fi

_koopa_fix_zsh_permissions

if [[ "$user" -eq 1 ]]
then
    _koopa_h1 "Updating user configuration."

    # Remove legacy directories from user config, if necessary.
    rm -frv "${config_prefix}/"{Rcheck,autojump,oh-my-zsh,pyenv,rbenv,spacemacs}

    # Update git repos.
    repos=(
        "${config_prefix}/docker"
        "${config_prefix}/docker-private"
        "${config_prefix}/dotfiles-private"
        "${config_prefix}/scripts-private"
        "${XDG_DATA_HOME}/Rcheck"
        "${HOME}/.emacs.d-doom"
    )
    for repo in "${repos[@]}"
    do
        [ -d "$repo" ] || continue
        (
            _koopa_cd "$repo"
            git pull
        )
    done

    _koopa_install_dotfiles
    _koopa_install_dotfiles_private
    _koopa_update_spacemacs
fi

_koopa_success "koopa update was successful."
_koopa_restart

if [[ "$system" -eq 1 ]]
then
    koopa check
fi
