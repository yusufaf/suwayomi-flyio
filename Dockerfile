# Suwayomi-Server for Fly.io.
#
# This is a thin wrapper around the official image. It exists for exactly one
# reason: Fly mounts volumes owned by root:root, but upstream runs as the
# unprivileged `suwayomi` user (uid 1000) and never chowns its data directory,
# so the very first write (server.conf) would fail with "permission denied".
#
# The wrapper starts as root just long enough for fly-entrypoint.sh to fix
# ownership, then drops back to uid 1000 before running upstream's startup
# script. Nothing else about the image is changed.

FROM ghcr.io/suwayomi/suwayomi-server:stable

USER root

COPY --chmod=755 fly-entrypoint.sh /usr/local/bin/fly-entrypoint.sh

ENTRYPOINT ["tini", "--", "/usr/local/bin/fly-entrypoint.sh"]
CMD ["/home/suwayomi/startup_script.sh"]
