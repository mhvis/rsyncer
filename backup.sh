#!/usr/bin/env bash
set -e


dump_dir=/dumps
rm -rf "$dump_dir"
mkdir -p "$dump_dir"


# PostgreSQL dump
for envvar_database in "${!RB_POSTGRES_DATABASE_@}"
do
    name_upper="${envvar_database:21}"
    name="${name_upper@L}"
    envvar_host="RB_POSTGRES_HOST_$name_upper"
    envvar_port="RB_POSTGRES_PORT_$name_upper"
    envvar_user="RB_POSTGRES_USER_$name_upper"
    envvar_pass="RB_POSTGRES_PASS_$name_upper"
    envvar_passfile="RB_POSTGRES_PASSFILE_$name_upper"

    export PGDATABASE=${!envvar_database}
    export PGHOST=${!envvar_host}
    export PGPORT=${!envvar_port}
    export PGUSER=${!envvar_user}
    pass=${!envvar_pass}
    passfile=${!envvar_passfile}
    if [ -n "$passfile" ]
    then
        pass=$(cat "$passfile")
    fi
    export PGPASSWORD=$pass

    echo "dumping $name"
    pg_dump --file="$dump_dir/${name}/" --format=directory
done


# MySQL dump
for envvar_database in "${!RB_MYSQL_DATABASE_@}"
do
    name_upper="${envvar_database:18}"
    name="${name_upper@L}"
    envvar_host="RB_MYSQL_HOST_$name_upper"
    envvar_port="RB_MYSQL_PORT_$name_upper"
    envvar_user="RB_MYSQL_USER_$name_upper"
    envvar_pass="RB_MYSQL_PASS_$name_upper"
    envvar_passfile="RB_MYSQL_PASSFILE_$name_upper"

    db=${!envvar_database}
    host=${!envvar_host}
    port=${!envvar_port}
    user=${!envvar_user}
    pass=${!envvar_pass}
    passfile=${!envvar_passfile}
    if [ -n "$passfile" ]
    then
        pass=$(cat "$passfile")
    fi

    # On tablespaces: https://dba.stackexchange.com/a/274460/284471
    echo "dumping $name"
    mysqldump \
        --host="$host" \
        --port="$port" \
        --user="$user" \
        --password="$pass" \
        --no-tablespaces \
        "$db" | gzip --best > "$dump_dir/${name}.sql.gz"
done


# Copy into source directory.
#
# Using checksum to prevent that dumps with the exact same data but a newer
# modification time are copied. This way, these dumps will be hard-linked on the backup
# server, instead of transferred again.
echo "copying dumps"
rsync -vh --checksum --recursive --delete "$dump_dir/" "$RB_SOURCE/dumps/"


# Relevant `rsync` settings:
#
# --archive, -a            archive mode is -rlptgoD (no -A,-X,-U,-N,-H)
# --recursive, -r          recurse into directories
# --links, -l              copy symlinks as symlinks
# --perms, -p              preserve permissions
# --times, -t              preserve modification times
# --group, -g              preserve group
# --owner, -o              preserve owner (super-user only)
# -D                       same as --devices --specials
# --devices                preserve device files (super-user only)
# --specials               preserve special files
# --verbose, -v            increase verbosity
# --compress, -z           compress file data during the transfer
# --link-dest=DIR          hardlink to files in DIR when unchanged
# --human-readable, -h     output numbers in a human-readable format
# --modify-window=NUM, -@  set the accuracy for mod-time comparisons
# --delete                 delete extraneous files from dest dirs


# # Pass 1: update the base directory.
# #
# # This pass mirrors the data with the base directory on the backup host. Files that
# # have changed since last backup are transferred.
# time rsync -avh \
#     -e "ssh $RB_SSH_OPTS" \
#     --rsync-path="$RB_RSYNC_PATH" \
#     --delete \
#     "$RB_SOURCE/" \
#     "$RB_DEST:$RB_DEST_DIR/base/"


# Pass 2: create a backup for the current date, by hard-linking from the base directory.
backup_name=$(date +"$RB_DATE_FORMAT")
time rsync -avh \
    -e "ssh $RB_SSH_OPTS" \
    --rsync-path="$RB_RSYNC_PATH" \
    --link-dest="$RB_DEST_DIR/latest/" \
    --mkpath \
    "$RB_SOURCE/" \
    "$RB_DEST:$RB_DEST_DIR/$backup_name/"

# Create a (relative) symlink to the latest backup
ssh $RB_SSH_OPTS "$RB_DEST" ln -s -n -f "./$backup_name/" "$RB_DEST_DIR/latest"
