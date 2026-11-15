#! /usr/bin/env sh
set -eu

USER_NAME="zandronum"

TARGET_UID=${PUID:-99}
TARGET_GID=${PUID:-100}

# Look up the user's current account information.
USER_ENTRY="$(getent passwd "$USER_NAME")"
CURRENT_UID="$(echo "$USER_ENTRY" | cut -d: -f3)"
HOME_DIR="$(echo "$USER_ENTRY" | cut -d: -f6)"

GROUP_ENTRY="$(getent group "$USER_NAME")"
CURRENT_GID="$(echo "$GROUP_ENTRY" | cut -d: -f3)"

# Update the group first, if necessary.
if [ "$CURRENT_GID" != "$TARGET_GID" ]; then
    groupmod -o -g "$TARGET_GID" "$USER_NAME"
fi

# Update the user UID, if necessary.
if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
    usermod -o -u "$TARGET_UID" "$USER_NAME"
fi

# We mount the home directory, it should already belong to the correct user!
# Ensure the home directory belongs to the updated account.
#chown -R "$TARGET_UID:$TARGET_GID" "$HOME_DIR"

# Drop privileges and execute the requested command.
exec su-exec "$USER_NAME" "$@"

