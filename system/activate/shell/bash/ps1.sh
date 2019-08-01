#!/usr/bin/env bash

# Define the prompt string.
# Updated 2019-06-25.

# Useful variables:
# https://www.cyberciti.biz/tips/howto-linux-unix-bash-shell-setup-prompt.html

# \! : the history number of this command
# \# : the command number of this command
# \$ : if the effective UID is 0, a #, otherwise a $
# \@ : the current time in 12-hour am/pm format
# \A : the current time in 24-hour HH:MM format
# \D{format} : the format is passed to strftime(3)
# \H : hostname
# \T : the current time in 12-hour HH:MM:SS format
# \V : the release of bash, version + patch level (e.g., 2.00.0)
# \W : the basename of the current working directory, with $HOME as tilde
# \[ : begin a sequence of non-printing characters
# \\ : a backslash
# \] : end a sequence of non-printing characters
# \a : an ASCII bell character (07)
# \d : the date in “Weekday Month Date” format (e.g., “Tue May 26”)
# \e : an ASCII escape character (033)
# \h : hostname up to the first `.`
# \j : the number of jobs currently managed by the shell
# \l : the basename of the shellâ€™s terminal device name
# \n : newline
# \nnn : the character corresponding to the octal number nnn
# \r : carriage return
# \s : shell name, the basename of `$0`
# \t : the current time in 24-hour HH:MM:SS format
# \u : the username of the current user
# \v : the version of bash (e.g., 2.00)
# \w : the current working directory, with $HOME abbreviated with a tilde

# The default value is `\s-\v\$ `.

# Add the conda environment name.
# Note that we have to source conda first (see shrc.rc above).
# https://stackoverflow.com/questions/42481726
# > CONDA_PROMPT_MODIFIER="($(basename "$CONDA_PREFIX"))"
# > export CONDA_PROMPT_MODIFIER
# > conda="$CONDA_PROMPT_MODIFIER"

# User name and host.
user="\u@\h"

# Remote machine information.
mach=
if _koopa_is_remote
then
    host_type="$(_koopa_host_type)"
    [[ -n "$host_type" ]] && mach="${host_type}"
    os_type="$(_koopa_os_type)"
    [[ -n "$os_type" ]] && [[ -n "$mach" ]] && mach="${mach} ${os_type}"
fi

# Shell name.
shell="$(_koopa_shell) \v"

# History.
history="c\# h\!"

# Working directory.
wd="\w"

# Unicode doesn't work with some monospace fonts on Windows.
# > prompt="\$"
prompt="❯"

# Enable colorful prompt.
# Match either "xterm-256color" or "screen-256color" here.
if [[ "${TERM:-}" =~ -256color ]]
then
    # Foreground colors (text)
    # https://misc.flogisoft.com/bash/tip_colors_and_formatting
    # 39 default
    # 30 black
    # 31 red
    # 32 green
    # 33 yellow
    # 34 blue
    # 35 magenta
    # 36 cyan
    # 37 light gray
    # 90 dark gray
    # 91 light red
    # 92 light green
    # 93 light yellow
    # 94 light blue
    # 95 light magenta
    # 96 light cyan
    # 97 white

    # Change the user color based on connection type.
    if _koopa_is_remote
    then
        user_color="33"
    else
        user_color="36"
    fi

    user="\[\033[01;${user_color}m\]${user}\[\033[00m\]"

    if [[ -n "$mach" ]]
    then
        mach_color="$user_color"
        mach="\[\033[${mach_color}m\]${mach}\[\033[00m\]"
    fi

    shell_color="39"
    shell="\[\033[${shell_color}m\]${shell}\[\033[00m\]"

    history_color="$shell_color"
    history="\[\033[${history_color}m\]${history}\[\033[00m\]"

    wd_color="34"
    wd="\[\033[01;${wd_color}m\]${wd}\[\033[00m\]"

    # Match the color of zsh pure prompt.
    prompt_color="35" 
    prompt="\[\033[01;${prompt_color}m\]${prompt}\[\033[00m\]"
fi

PS1="\n${user}"
[[ -n "$mach" ]] && PS1="${PS1} | ${mach}"
PS1="${PS1} | ${shell} | ${history}\n"
PS1="${PS1}${wd}\n"
PS1="${PS1}${prompt} "
export PS1

unset -v history mach prompt prompt_color user user_color wd wd_color
