#!/usr/bin/env bash

koopa::install_dotfiles() { # {{{1
    # """
    # Install dot files.
    # @note Updated 2020-07-07.
    # """
    local prefix script
    koopa::assert_has_no_args "$#"
    prefix="$(koopa::dotfiles_prefix)"
    [[ ! -d "$prefix" ]] && koopa::git_clone_dotfiles
    koopa::add_config_link "$prefix"
    script="${prefix}/install"
    koopa::assert_is_file "$script"
    "$script"
    return 0
}

koopa::install_dotfiles_private() { # {{{1
    # """
    # Install private dot files.
    # @note Updated 2020-07-07.
    # """
    local prefix script
    koopa::assert_has_no_args "$#"
    prefix="$(koopa::dotfiles_private_prefix)"
    koopa::add_monorepo_config_link 'dotfiles-private'
    [[ ! -d "$prefix" ]] && koopa::git_clone_dotfiles_private
    script="${prefix}/install"
    koopa::assert_is_file "$script"
    "$script"
    return 0
}

koopa::uninstall_dotfiles() { # {{{1
    # """
    # Uninstall dot files.
    # @note Updated 2020-07-05.
    # """
    local prefix script
    koopa::assert_has_no_args "$#"
    prefix="$(koopa::dotfiles_prefix)"
    if [[ ! -d "$prefix" ]]
    then
        koopa::note "No dotfiles at '${prefix}'."
        return 0
    fi
    script="${prefix}/uninstall"
    koopa::assert_is_file "$script"
    "$script"
    return 0
}

koopa::uninstall_dotfiles_private() { # {{{1
    # """
    # Uninstall private dot files.
    # @note Updated 2020-07-05.
    # """
    local prefix script
    koopa::assert_has_no_args "$#"
    prefix="$(koopa::dotfiles_private_prefix)"
    if [[ ! -d "$prefix" ]]
    then
        koopa::note "No private dotfiles at '${prefix}'."
        return 0
    fi
    script="${prefix}/uninstall"
    koopa::assert_is_file "$script"
    "$script"
    return 0
}

koopa::update_dotfiles() { # {{{1
    # """
    # Update dotfiles repo and run install script, if defined.
    # @note Updated 2021-01-19.
    # """
    local repo repos script
    koopa::assert_has_args "$#"
    repos=("$@")
    for repo in "${repos[@]}"
    do
        [[ -d "$repo" ]] || continue
        (
            koopa::update_start "$repo"
            koopa::cd "$repo"
            koopa::git_reset
            koopa::git_pull
            # Run the install script, if defined.
            script="${repo}/install"
            [[ -x "$script" ]] && "$script"
            koopa::update_success "$repo"
        )
    done
    return 0
}
