#!/bin/bash
set -euo pipefail

CONTAINER_HOST_NAME="ubuntu-26-04-docker"
HOST_HOME="$HOME"
HOST_USER="$(id -un)"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
CONTAINER_HOME="/home/$HOST_USER"

LEGACY_XDG_DATA_HOME="$HOST_HOME/.local/xdg-ubuntu-26-04"
LEGACY_XDG_STATE_HOME="$HOST_HOME/.local/state-ubuntu-26-04"
HOST_XDG_DATA_HOME="$HOST_HOME/.local/share/ubuntu-26-04"
HOST_XDG_STATE_HOME="$HOST_HOME/.local/state/ubuntu-26-04"
HOST_SHELL_HISTORY_DIR="$HOST_XDG_STATE_HOME/shell-history"

merge_tree() {
    local source_dir="$1"
    local target_dir="$2"

    [ -d "$source_dir" ] || return 0

    mkdir -p "$target_dir"
    cp -R "$source_dir"/. "$target_dir"/
    rm -rf "$source_dir"
}

merge_tree "$LEGACY_XDG_DATA_HOME" "$HOST_XDG_DATA_HOME"
merge_tree "$LEGACY_XDG_STATE_HOME" "$HOST_XDG_STATE_HOME"

mkdir -p "$HOST_XDG_DATA_HOME" "$HOST_XDG_STATE_HOME" "$HOST_SHELL_HISTORY_DIR"
touch "$HOST_SHELL_HISTORY_DIR/.bash_history" "$HOST_SHELL_HISTORY_DIR/.zsh_history"
chmod 600 "$HOST_SHELL_HISTORY_DIR/.bash_history" "$HOST_SHELL_HISTORY_DIR/.zsh_history"

MOUNTS=(
    -v /etc/localtime:/etc/localtime:ro
    -v "$HOST_HOME/ohrs-stuff:$CONTAINER_HOME/ohrs-stuff:rw"
    -v "$HOST_HOME/.cache:$CONTAINER_HOME/.cache:rw"
    -v "$HOST_HOME/.local:$CONTAINER_HOME/.local:rw"
    -v "$HOST_HOME/.cargo:$CONTAINER_HOME/.cargo:rw"
    -v "$HOST_HOME/br-partners:$CONTAINER_HOME/br-partners:rw"
)

for path in .ssh .aws .zsh .zshenv .zshrc .config; do
    host_path="$HOST_HOME/$path"
    if [ -e "$host_path" ]; then
        MOUNTS+=( -v "$host_path:$CONTAINER_HOME/${path}:ro" )
    else
        echo "Warning: $host_path does not exist on host; mount skipped." >&2
    fi
done

CONTAINER_CMD=(zsh)
if [ "$#" -gt 0 ]; then
    CONTAINER_CMD=("$@")
fi

docker run --rm -it \
    --init \
    --hostname "$CONTAINER_HOST_NAME" \
    "${MOUNTS[@]}" \
    -e USERNAME="$HOST_USER" \
    -e USER_UID="$HOST_UID" \
    -e USER_GID="$HOST_GID" \
    -e XDG_DATA_HOME="$CONTAINER_HOME/.local/share/ubuntu-26-04" \
    -e XDG_STATE_HOME="$CONTAINER_HOME/.local/state/ubuntu-26-04" \
    -w "$CONTAINER_HOME" \
    ubuntu-26-04:latest \
    "${CONTAINER_CMD[@]}"
