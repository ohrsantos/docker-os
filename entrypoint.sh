#!/bin/bash
set -e

USERNAME=${USERNAME:-ohrs}
USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}
HOME_DIR=${HOME_DIR:-/home/$USERNAME}

TARGET_USER="$USERNAME"
TARGET_GROUP="$USERNAME"

# Create group with requested GID when possible, otherwise reuse existing group.
if getent group "$TARGET_GROUP" >/dev/null; then
    :
elif getent group "$USER_GID" >/dev/null; then
    TARGET_GROUP=$(getent group "$USER_GID" | cut -d: -f1)
else
    groupadd -g "$USER_GID" "$TARGET_GROUP"
fi

USERADD_OPTS=(
    -g "$TARGET_GROUP"
    -d "$HOME_DIR"
    -s /usr/bin/zsh
)

# If HOME already exists (common when mounting dotfiles), skip -m to avoid warnings.
if [ ! -d "$HOME_DIR" ]; then
    USERADD_OPTS=(-m "${USERADD_OPTS[@]}")
fi

# Create user when missing; if UID already exists, create target user with a free UID.
if id -u "$TARGET_USER" >/dev/null 2>&1; then
    HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)
elif getent passwd "$USER_UID" >/dev/null; then
    echo "Warning: UID $USER_UID already exists in container; creating $TARGET_USER with a free UID." >&2
    useradd "${USERADD_OPTS[@]}" "$TARGET_USER"
else
    useradd \
        -K UID_MIN=0 \
        -K UID_MAX=60000 \
        -u "$USER_UID" \
        "${USERADD_OPTS[@]}" \
        "$TARGET_USER"
fi

mkdir -p "$HOME_DIR"

# Compatibility for host dotfiles that expect HOME under /Users/<username>.
if [ ! -e "/Users/$TARGET_USER" ]; then
    mkdir -p /Users
    ln -s "$HOME_DIR" "/Users/$TARGET_USER"
fi

# Docker may create HOME as root when mounting individual files; fix owner/permissions.
TARGET_UID=$(id -u "$TARGET_USER")
TARGET_GID=$(id -g "$TARGET_USER")
chown "$TARGET_UID:$TARGET_GID" "$HOME_DIR"
chmod u+rwx "$HOME_DIR"

# Enable passwordless sudo for the development user.
if getent group sudo >/dev/null; then
    usermod -aG sudo "$TARGET_USER"
fi
echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$TARGET_USER"
chmod 0440 "/etc/sudoers.d/90-$TARGET_USER"

cd "$HOME_DIR"

# Interactive session: avoid su -c so Ctrl+C stops commands without killing the container.
if [ "$#" -eq 0 ] || { [ "$#" -eq 1 ] && [ "$1" = "zsh" ]; }; then
    exec su - "$TARGET_USER"
fi

# Preserve arguments when switching user (including redirections in -c).
cmd_escaped=$(printf ' %q' "$@")
cmd_escaped=${cmd_escaped:1}

exec su - "$TARGET_USER" -c "$cmd_escaped"
