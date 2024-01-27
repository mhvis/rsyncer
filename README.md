# rsyncer (rsync + Docker)

Incremental backup of Docker volumes to another host over SSH, using `rsync`.


## Features

* Incremental backups, by hard-linking files that have not changed.
* Health check endpoint (TODO).
* Logical online database backups with `pg_dump` or `mysqldump`.


## Setup

Mount all volumes to backup as read-only under `/volumes` and set the settings as required.

To get the image: `docker pull mhvis/rsyncer`


### SSH authentication

The fingerprint of the destination host needs to be mounted in a file at
`/root/.ssh/known_hosts`.
To use public key authentication, mount the private key at `/root/.ssh/id_rsa`.

Alternatively you can use `RB_SSH_OPTS` to specify manual SSH options if you want to
use a different location of the identity or hosts file. For example:
`-i /path/to/identity`.

### File permissions

The remote SSH user needs root permissions. One way to accomplish this is to set
`RB_RSYNC_PATH` to `sudo rsync`. This requires passwordless sudo to be set up.

## Settings

| Environment variable | Description | Default value | Example |
| -------------------- | ----------- | ------------- | --- |
| `RB_SOURCE` | The directory to backup. Mount all volumes under this directory. | `/volumes` |
| `RB_DEST` | The destination host used by Rsync. | | `user@example.com` |
| `RB_DEST_DIR` | The base directory on the destination host. | | `/mnt/hdd/backup` |
| `RB_INTERVAL` | The backup script will sleep this amount of seconds between each backup. | 3600 | |
| `RB_RSYNC_PATH` | The path to rsync on the remote host. Can be used to prefix it with sudo if necessary. | `rsync` | |
| `RB_SSH_OPTS` | Additional options for SSH. This can be used to specify a different port. | | `-p 2222` |
| `RB_DATE_FORMAT` | The date format used as folder name for new backups. May include '/' for a multi-level hierarchy. See `man date`. | `%Y-%m-%d/%H%M` |
| `TZ` | Setting this affects the time used as folder name for each new backup. | Europe/Amsterdam | |

### Database dumps

To dump a database, specify the listed variables. The name is used as filename for the
SQL dump. Multiple databases can be specified, each with their own name. For PostgreSQL
only, the directory format is used to achieve better deduplication. The dumps are put
under `RB_SOURCE` in a subdirectory named `dumps`.


For PostgreSQL:

* `RB_POSTGRES_DATABASE_<name>` (required)
* `RB_POSTGRES_HOST_<name>`
* `RB_POSTGRES_PORT_<name>`
* `RB_POSTGRES_USER_<name>`
* `RB_POSTGRES_PASS_<name>`
* `RB_POSTGRES_PASSFILE_<name>`: can be used with a Docker secret for the password.

For MySQL:

* `RB_MYSQL_DATABASE_<name>` (required)
* `RB_MYSQL_HOST_<name>`
* `RB_MYSQL_PORT_<name>`
* `RB_MYSQL_USER_<name>`
* `RB_MYSQL_PASS_<name>`
* `RB_MYSQL_PASSFILE_<name>`
