#!/bin/bash
set -euo pipefail

USERNAME="openstack"
USER_ID=${OPENSTACK_USER_ID:-1000}
GROUP_ID=${OPENSTACK_GROUP_ID:-1000}

if ! getent group "$USERNAME" >/dev/null; then
    groupadd -r "$USERNAME" -g "$GROUP_ID"
fi

if ! id -u "$USERNAME" >/dev/null 2>&1; then
    useradd -u "$USER_ID" -g "$USERNAME" -s /bin/bash -c "Openstack user" "$USERNAME" 2>/dev/null
fi

HOME_DIR=$(getent passwd "$USERNAME" | cut -d: -f6)
chown -R "$USER_ID:$GROUP_ID" "$HOME_DIR"

exec gosu "$USERNAME" "$@"
