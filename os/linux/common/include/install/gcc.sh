#!/usr/bin/env bash
# shellcheck disable=SC2154

# """
# Official GCC links:
# - https://ftp.gnu.org/gnu/gcc/
# - https://gcc.gnu.org/install/
# - https://gcc.gnu.org/install/prerequisites.html
# - https://gcc.gnu.org/wiki/InstallingGCC
# - https://gcc.gnu.org/wiki/FAQ
#
# Do not run './configure' from within the source directory.
# Instead, you need to run configure from outside the source directory,
# in a separate directory created for the build.
#
# Prerequisites:
#
# If you do not have the GMP, MPFR and MPC support libraries already installed
# as part of your operating system then there are two simple ways to proceed,
# and one difficult, error-prone way. For some reason most people choose the
# difficult way. The easy ways are:
#
# If it provides sufficiently recent versions, use your OS package management
# system to install the support libraries in standard system locations.
#
# For Debian-based systems, including Ubuntu, you should install:
# - libgmp-dev
# - libmpc-dev
# - libmpfr-dev
#
# For RPM-based systems, including Fedora and SUSE, you should install:
# - gmp-devel
# - libmpc-devel (or mpc-devel on SUSE)
# - mpfr-devel
#
# The packages will install the libraries and headers in standard system
# directories so they can be found automatically when building GCC.
#
# Alternatively, after extracting the GCC source archive, simply run the
# './contrib/download_prerequisites' script in the GCC source directory.
# That will download the support libraries and create symlinks, causing them to
# be built automatically as part of the GCC build process.
# Set 'GRAPHITE_LOOP_OPT=no' in the script if you want to build GCC without ISL,
# which is only needed for the optional Graphite loop optimizations. 
#
# The difficult way, which is not recommended, is to download the sources for
# GMP, MPFR and MPC, then configure and install each of them in non-standard
# locations.
#
# See also:
# - https://solarianprogrammer.com/2016/10/07/building-gcc-ubuntu-linux/
# - https://medium.com/@darrenjs/building-gcc-from-source-dcc368a3bb70
# """

koopa::assert_is_linux
file="${name}-${version}.tar.xz"
url="${gnu_mirror}/${name}/${name}-${version}/${file}"
koopa::download "$url"
koopa::extract "$file"
# Need to build outside of source code directory.
koopa::mkdir build
koopa::cd build
flags=(
    "--prefix=${prefix}"
    '--disable-multilib'
    '--enable-languages=c,c++,fortran'
    '-v'
)
"../${name}-${version}/configure" "${flags[@]}"
make --jobs="$jobs"
make install
