#!/bin/sh
# Runs as root before upstream's startup script, then drops to `suwayomi`.
#
# Fly mounts the volume at the data directory owned by root:root. Upstream
# runs as uid 1000 and does no chown of its own, so ownership is fixed here.
#
# The recursive chown only runs when the top-level owner is wrong (i.e. a
# fresh volume), so a large downloads/ folder doesn't slow down every boot.
set -e

DATA_DIR=/home/suwayomi/.local/share/Tachidesk

mkdir -p "$DATA_DIR"
if [ "$(stat -c %u "$DATA_DIR")" != "1000" ]; then
  chown -R 1000:1000 "$DATA_DIR"
fi

export HOME=/home/suwayomi
exec setpriv --reuid=1000 --regid=1000 --init-groups "$@"
