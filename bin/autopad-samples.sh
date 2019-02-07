#!/usr/bin/env bash
set -Eeuo pipefail

# Autopad sample file names that begin with a number.
#
# Renaming with a "sample" prefix by default, to avoid issues in R.
#
# See also:
# - How to use `BASH_REMATCH`.
#   https://unix.stackexchange.com/questions/349686
# - Renaming hundreds of files at once.
#   https://askubuntu.com/questions/473236
# - Zero padding in bash.
#   https://stackoverflow.com/questions/55754
# - zeropad by Michael Metz.
#   https://github.com/Michael-Metz/zeropad
# - Perl `rename` isn't portable.
#   This ships by default with some Linux distros, but not Red Hat.
#   https://techblog.jeppson.org/2016/08/add-prefix-filenames-bash/  
#   rename 's/\d+/sprintf("%03d", $&)/e' *.fastq.gz

files=("$@")
padwidth=2
prefix="sample"

for file in "${files[@]}"
do
    if [[ "$file" =~ ^([0-9]+)(.*)$ ]]
    then
        oldname="${BASH_REMATCH[0]}"
        num=${BASH_REMATCH[1]}
        # Now pad the number prefix.
        num=$(printf "%.${padwidth}d" "$num")
        stem=${BASH_REMATCH[2]}
        # Combine with prefix to create desired file name.
        newname="${prefix}_${num}${stem}"
        mv -nv "$oldname" "$newname"
    else
        echo "Skipping ${file}"
    fi
done
