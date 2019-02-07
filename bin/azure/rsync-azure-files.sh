# rsync to Azure Samba (SMB) file shares.

# Useful rsync flags:
# -n, --dry-run               perform a trial run with no changes made
# -r, --recursive
#
# -v, --verbose
# -h, --human-readable        output numbers in a human-readable format
#     --progress              show progress during transfer
#     --stats                 give some file-transfer stats
#
# -L, --copy-links            transform symlink into referent file/dir
#     --safe-links            ignore symlinks that point outside the tree
#     --munge-links
# -k, --copy-dirlinks         transform symlink to dir into referent dir
# -K, --keep-dirlinks         treat symlinked dir on receiver as dir
#
#     --delete                delete extraneous files from dest dirs
#     --preallocate           allocate dest files before writing
#     --size-only             skip files that match in size
#
# Incompatible with Azure file shares mounted over Samba (SMB):
# -a, --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
# -p, --perms                 preserve permissions
# -l, --links                 copy links as symlinks
# -H, --hard-links            preserve hard links
#
# --super                 receiver attempts super-user activities
# --fake-super            store/recover privileged attrs using xattrs

rsync \
    --recursive \
    --human-readable --progress --stats --verbose \
    --no-links \
    --size-only \
    --exclude=".git" \
    --exclude=".gitignore" \
    --exclude=".Rproj.user" \
    "$@"
