FROM debian:12

RUN apt-get update \
    && apt-get install -y ca-certificates

COPY rsyncer.sources /etc/apt/sources.list.d/rsyncer.sources

RUN apt-get update \
    && apt-get install -y tini rsync openssh-client postgresql-client mariadb-client

COPY backup.sh /usr/local/bin/backup.sh
COPY backup_on_interval.sh /usr/local/bin/backup_on_interval.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/backup_on_interval.sh

# Default settings
ENV RB_SOURCE=/volumes
ENV RB_INTERVAL="3600"
ENV RB_DATE_FORMAT="%Y-%m-%d/%H%M"
ENV RB_RSYNC_PATH=rsync
ENV TZ=Europe/Amsterdam

ENTRYPOINT ["tini", "--"]
CMD ["backup_on_interval.sh"]
