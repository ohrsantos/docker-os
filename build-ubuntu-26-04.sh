#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-ubuntu-26-04}"
DOCKERFILE="${DOCKERFILE:-ubuntu-26-04.Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"
PROGRESS="${PROGRESS:-plain}"
LOG_FILE="${LOG_FILE:-}"

cmd=(docker build --progress="$PROGRESS" -t "$IMAGE_NAME" -f "$DOCKERFILE")

# Allow passing extra docker build arguments, e.g. --no-cache --pull
if [ "$#" -gt 0 ]; then
	cmd+=("$@")
fi

cmd+=("$BUILD_CONTEXT")

if [ -n "$LOG_FILE" ]; then
	"${cmd[@]}" 2>&1 | tee "$LOG_FILE"
else
	"${cmd[@]}"
fi
