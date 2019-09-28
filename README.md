# koopa 🐢

[![Travis CI build status](https://travis-ci.com/acidgenomics/koopa.svg?branch=master)](https://travis-ci.com/acidgenomics/koopa)
[![Repo status: active](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)

Shell bootloader for bioinformatics.

## Installation

These [POSIX][]-compliant shells are supported: [bash][], [zsh][].

[dash][], [ksh][], and [tcsh][] shells aren't supported.

Support for the non-POSIX [fish][] shell may be added in a future release, but
is currently unsupported.

Requirements:

- Linux or macOS. Windows isn't supported.
- [Bash][] >= 4. Required even when using a different shell.
- [Python][] >= 3.7.
- [R][] >= 3.6.

Tested on:

- macOS Mojave
- Ubuntu 18 LTS
- Debian Buster
- RHEL 8 / CentOS 8
- RHEL 7 / CentOS 7
- Amazon Linux 2

### Shared user installation

**Recommended.** This requires sudo permissions.

```sh
curl -sSL https://raw.githubusercontent.com/acidgenomics/koopa/develop/install | bash
```

This will add a shared profile configuration file at `/etc/profile.d/koopa.sh` for supported Linux distros.

If you're going to install any programs using the cellar scripts, also adjust the permissions for `/usr/local/`. Otherwise the link cellar commands will error and you will see symlink errors.

```sh
sudo chgrp -Rh "$group" /usr/local
sudo chmod g+w -R /usr/local
sudo chmod g+s /usr/local
```

### Local user installation

Use this approach on machines without sudo permissions.

Clone the repository. Installation following the [XDG base directory specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) is recommended.

```sh
source_repo="https://github.com/acidgenomics/koopa.git"
XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
target_dir="${XDG_DATA_HOME}/koopa"
mkdir -pv "$target_dir"
git clone --recursive "$source_repo" "$target_dir"
"${target_dir}/install"
```

Add these lines to your shell configuration file.

```sh
# koopa shell
# https://koopa.acidgenomics.com/
# shellcheck source=/dev/null
XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
. "${XDG_DATA_HOME}/koopa/activate"
```

### Check installation

Restart the shell. Koopa should now activate automatically at login. You can
verify this with `command -v koopa`. Next, check your environment dependencies
with `koopa check`. To obtain information about the working environment, run
`koopa info`.

## Troubleshooting

### Shell configuration file

Not sure where to source `activate` in your configuration? Here are some general
recommendations, in order of priority for each shell. These can differ depending
on the operating system, so refer to your shell documentation for details.

- [bash][]: `.bash_profile`, `.bashrc`.
- [zsh][]: `.zshrc`, `.zprofile`.

## Exported tools

Upon activation, koopa makes scripts available in `$PATH`, which are defined in the [`bin/`](bin/) directory of the repo. Run `koopa list` for a complete list.

## Automatic program configuration

Koopa provides automatic configuration and `$PATH` variable support for a number
of popular bioinformatics tools. When configuring manually, ensure that
variables are defined before sourcing the activation script.

### Aspera Connect

[Aspera Connect][] is a secure file transfer application commonly used by
numerous organizations, including the NIH and Broad Institute. Koopa will
automatically detect Aspera when it is installed at the default path of
`~/.aspera/`. Otherwise, the installation path can be defined manually using
the `$ASPERA_EXE` variable.

```bash
export ASPERA_EXE="${HOME}/.aspera/connect/bin/asperaconnect"
```

### bcbio

[bcbio][] is a [Python][] toolkit that provides modern NGS analysis pipelines
for RNA-seq, single-cell RNA-seq, ChIP-seq, and variant calling. Koopa provides
automatic configuration support for the Harvard O2 and Odyssey high-performance
computing clusters. Otherwise, the installation path can be defined manually
using the `$BCBIO_EXE` variable.

```bash
export BCBIO_EXE="/usr/local/bin/bcbio_nextgen.py"
```

### conda

[Conda][] is an open source package management system that provides pre-built
binaries using versioned recipes for Linux and macOS.

Koopa provides automatic detection and activation support when conda is
installed at any of these locations (note priority):

- `~/anaconda3/`
- `~/miniconda3/`
- `/usr/local/anaconda3/`
- `/usr/local/miniconda3/`

Oherwise, the installation path can be defined manually using the `$CONDA_EXE` variable.

```bash
export CONDA_EXE="${HOME}/miniconda3/bin/conda"
```

### SSH key

On Linux, koopa will launch `ssh-agent` and attempt to import the default [SSH][] key at `~/.ssh/id_rsa`, if the key file exists. A different default key can be defined manually using the `$SSH_KEY` variable.

```bash
export SSH_KEY="${HOME}/.ssh/id_rsa"
```

On macOS, instead we recommend adding these lines to `~/.ssh/config` to use the system keychain:

```
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_rsa
    UseKeychain yes
```

[aspera connect]: https://downloads.asperasoft.com/connect2/
[bash]: https://www.gnu.org/software/bash/  "Bourne Again SHell"
[bcbio]: https://bcbio-nextgen.readthedocs.io/
[conda]: https://conda.io/
[dash]: https://wiki.archlinux.org/index.php/Dash  "Debian Almquist SHell"
[dotfiles]: https://github.com/mjsteinbaugh/dotfiles/
[fish]: https://fishshell.com/  "Friendly Interactive SHell"
[git]: https://git-scm.com/
[ksh]: http://www.kornshell.com/  "KornSHell"
[pgp]: https://www.openpgp.org/
[posix]: https://en.wikipedia.org/wiki/POSIX  "Portable Operating System Interface"
[python]: https://www.python.org/
[r]: https://www.r-project.org/
[ssh]: https://en.wikipedia.org/wiki/Secure_Shell
[tcsh]: https://en.wikipedia.org/wiki/Tcsh  "TENEX C Shell"
[zsh]: https://www.zsh.org/  "Z SHell"
