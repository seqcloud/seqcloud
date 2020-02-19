#!/usr/bin/env bash

_koopa_set_permissions() {  # {{{1
    # """
    # Set permissions on target prefix(es).
    # @note Updated 2020-02-19.
    #
    # @param --recursive
    #   Change permissions recursively.
    # @param --user
    #   Change ownership to current user, rather than koopa default, which is
    #   root for shared installs.
    # """
    local recursive
    recursive=0

    local user
    user=0

    local verbose
    verbose=0

    pos=()
    while (("$#"))
    do
        case "$1" in
            --recursive)
                recursive=1
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
            --)
                shift 1
                break
                ;;
            --*|-*)
                _koopa_invalid_arg "$1"
                ;;
            *)
                pos+=("$1")
                shift 1
                ;;
        esac
    done
    set -- "${pos[@]}"

    [ "$#" -ne 0 ] || return 1

    # chmod flags.
    local chmod_flags
    mapfile -t chmod_flags < <(_koopa_chmod_flags)
    if [[ "$recursive" -eq 1 ]]
    then
        chmod_flags+=("--recursive")  # '-R'
    fi
    if [[ "$verbose" -eq 1 ]]
    then
        chmod_flags+=("--verbose")  # '-v'
    fi

    # chown flags.
    local chown_flags
    chown_flags=("--no-dereference")  # '-h'
    if [[ "$recursive" -eq 1 ]]
    then
        chown_flags+=("--recursive")  # '-R'
    fi
    if [[ "$verbose" -eq 1 ]]
    then
        chown_flags+=("--verbose")  # '-v'
    fi
    local group
    group="$(_koopa_group)"
    local who
    case "$user" in
        0)
            who="$(_koopa_user)"
            ;;
        1)
            who="${USER:?}" \
            ;;
    esac
    chown_flags+=("${who}:${group}")

    # Loop across input and set permissions.
    for arg
    do
        # Ensure we resolve symlinks here.
        arg="$(realpath "$arg")"
        _koopa_chmod "${chmod_flags[@]}" "$arg"
        _koopa_chown "${chown_flags[@]}" "$arg"
    done

    return 0
}
