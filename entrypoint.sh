#!/bin/bash
set -eufo pipefail
mkdir -p /data/objects /data/db /data/run
if radosgw-admin user info --uid="$RGW_UID" >/dev/null 2>&1; then
  # Existing data dir: make the env pair the user's only key. The DBStore user database
  # authenticates just one key per user (the lowest access key id), and removing a user's
  # last key deletes the user, so (re)create the env pair first, then drop the others.
  keys=$(radosgw-admin key create --uid="$RGW_UID" \
    --access-key="$RGW_ACCESS_KEY" --secret-key="$RGW_SECRET_KEY" | jq -r '.keys[].access_key')
  for k in $keys; do
    [[ $k == "$RGW_ACCESS_KEY" ]] || radosgw-admin key rm --uid="$RGW_UID" --access-key="$k" >/dev/null
  done
else
  radosgw-admin user create --uid="$RGW_UID" --display-name="$RGW_UID" \
    --access-key="$RGW_ACCESS_KEY" --secret-key="$RGW_SECRET_KEY" >/dev/null
fi
# Root on purpose: under rootless podman, container root maps to the host user, so a
# bind-mounted /data stays owned by whoever ran the container.
exec radosgw -d -n client.rgw.local --setuser root --setgroup root "$@"
