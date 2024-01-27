#!/usr/bin/env bash
set -e

while true
do
    backup.sh
    sleep "$RB_INTERVAL"
done
