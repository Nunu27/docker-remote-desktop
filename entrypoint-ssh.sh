#!/bin/bash
set -e

PUID=${PUID:-1020}
PGID=${PGID:-1020}
USERNAME=${USERNAME:-ubuntu}
PASSWORD=${PASSWORD:-ubuntu}

# 1. Create Group
if ! getent group "$PGID" >/dev/null; then
    groupadd --gid "$PGID" "$USERNAME"
fi

# 2. Create User
if ! id -u "$USERNAME" >/dev/null 2>&1; then
    # Create user with specified UID/GID and add to sudo group
    useradd --shell /bin/bash \
            --uid "$PUID" \
            --gid "$PGID" \
            --groups sudo \
            --create-home \
            --home-dir "/home/$USERNAME" \
            "$USERNAME"
    
    # Set password using chpasswd
    echo "$USERNAME:$PASSWORD" | chpasswd
fi

# 3. Start SSH daemon
echo "Starting sshd..."
exec /usr/sbin/sshd -D -e "$@"
