#!/bin/sh
set -eu

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

if [ ! -f "$GANESHA_CONFIG" ]; then
  echo "missing Ganesha config: $GANESHA_CONFIG" >&2
  exit 1
fi

mkdir -p /run/rpcbind /usr/local/var/lib/nfs/ganesha /usr/local/var/run/ganesha
rpcbind -w

exec /usr/local/bin/ganesha.nfsd \
  -F \
  -x \
  -f "$GANESHA_CONFIG" \
  -L STDOUT \
  -p /usr/local/var/run/ganesha/ganesha.pid
