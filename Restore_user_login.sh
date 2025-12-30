#!/bin/bash

# Re-enable user login script for macOS
# Skips system users and preserves admin access for exempt users

# Users to exclude from processing
EXEMPT_USERS=("LAPS_ADMIN" "HelpDESK_ADMIN")

# Function to check if a user is a system user
is_system_user() {
    local username="$1"
    uid=$(id -u "$username" 2>/dev/null)
    if [[ -z "$uid" || "$uid" -lt 500 ]]; then
        return 0  # system user
    else
        return 1  # regular user
    fi
}

# Function to check if a user is in the exempt list
is_exempt_user() {
    local username="$1"
    for exempt in "${EXEMPT_USERS[@]}"; do
        if [[ "$username" == "$exempt" ]]; then
            return 0  # exempt
        fi
    done
    return 1  # not exempt
}

# Default shell to restore
DEFAULT_SHELL="/bin/bash"

# Get all users on the system
all_users=$(dscl . list /Users)

for user in $all_users; do
    if is_system_user "$user"; then
        echo "Skipping system user: $user"
        continue
    fi

    if is_exempt_user "$user"; then
        echo "Skipping exempt user: $user"
        continue
    fi

    # Get the current shell
    current_shell=$(dscl . -read /Users/"$user" UserShell | awk '{print $2}')

    # Only change shell if it was disabled previously (/usr/bin/false)
    if [[ "$current_shell" == "/usr/bin/false" ]]; then
        echo "Re-enabling login for user: $user"
        dscl . -change /Users/"$user" UserShell "$current_shell" "$DEFAULT_SHELL"
    else
        echo "User $user already has a valid shell, skipping."
    fi
done

echo "All eligible users processed."
exit 0
