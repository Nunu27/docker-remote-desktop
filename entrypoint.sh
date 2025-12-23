#!/bin/bash
set -e

# Default configuration (can be overridden by ENV vars)
# Using 1000 is generally standard for non-root users, but kept your 1020 default
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
    
    # Set password using chpasswd (avoids openssl dependency)
    echo "$USERNAME:$PASSWORD" | chpasswd
fi

# 3. Cleanup Stale PIDs
# Prevents "Address already in use" errors on container restart
rm -f /var/run/xrdp/xrdp-sesman.pid
rm -f /var/run/xrdp/xrdp.pid

# 4. Start Services
echo "Starting xrdp-sesman..."
/usr/sbin/xrdp-sesman

if [ -z "$1" ]; then
    echo "Starting xrdp..."
    # Exec into xrdp so it receives unix signals (SIGTERM/SIGINT) correctly
    exec /usr/sbin/xrdp --nodaemon
else
    /usr/sbin/xrdp
    exec "$@"
fi