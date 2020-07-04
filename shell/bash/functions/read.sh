#!/usr/bin/env bash

koopa::_int_to_yn() { # {{{1
    # """
    # Convert integer to yes/no choice.
    # @note Updated 2020-07-02.
    # """
    _koopa_assert_has_args_eq "$#" 1
    local x
    case "${1:?}" in
        0)
            x="no"
            ;;
        1)
            x="yes"
            ;;
        *)
            _koopa_stop "Invalid choice: requires 0 or 1."
            ;;
    esac
    _koopa_print "$x"
    return 0
}

koopa::_read_prompt_yn() { # {{{1
    # """
    # Show colorful yes/no default choices in prompt.
    # @note Updated 2020-07-02.
    # """
    _koopa_assert_has_args_eq "$#" 2
    local no no_default prompt yes yes_default yn
    no="$(_koopa_print_red "no")"
    no_default="$(_koopa_print_red_bold "NO")"
    yes="$(_koopa_print_green "yes")"
    yes_default="$(_koopa_print_green_bold "YES")"
    prompt="${1:?}"
    case "${2:?}" in
        0)
            yn="${yes}/${no_default}"
            ;;
        1)
            yn="${yes_default}/${no}"
            ;;
        *)
            _koopa_stop "Invalid choice: requires 0 or 1."
            ;;
    esac
    _koopa_print "${prompt}? [${yn}]: "
    return 0
}

_koopa_read() { # {{{1
    # """
    # Read a string from the user.
    # @note Updated 2020-07-02.
    # """
    _koopa_assert_has_args_eq "$#" 2
    local choice default flags prompt
    default="${2:?}"
    prompt="${1:?} [${default}]: "
    flags=(-r -p "$prompt")
    if ! _koopa_is_bash_ok
    then
        flags+=(-e -i "${koopa_prefix}")
    fi
    # shellcheck disable=SC2162
    read "${flags[@]}" choice
    choice="${choice:-$default}"
    _koopa_print "$choice"
    return 0
}

_koopa_read_yn() { # {{{1
    # """
    # Read a yes/no choice from the user.
    # @note Updated 2020-07-02.
    #
    # Checks if Bash version is ancient (e.g. macOS clean install), so we can
    # adjust interactive read input flags accordingly.
    # """
    _koopa_assert_has_args_eq "$#" 2
    local choice default flags x
    prompt="$(koopa::_read_prompt_yn "$@")"
    default="$(koopa::_int_to_yn "${2:?}")"
    flags=(-r -p "$prompt")
    if _koopa_is_bash_ok
    then
        flags+=(-e -i "$default")
    fi
    # shellcheck disable=SC2162
    read "${flags[@]}" choice
    choice="${choice:-$default}"
    case "$choice" in
        1|T|TRUE|True|Y|YES|Yes|true|y|yes)
            x=1
            ;;
        0|F|FALSE|False|N|NO|No|false|n|no)
            x=0
            ;;
        *)
            _koopa_stop "Invalid 'yes/no' choice."
            ;;
    esac
    _koopa_print "$x"
    return 0
}
