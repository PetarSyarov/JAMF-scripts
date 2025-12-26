#!/bin/bash

# =======================
# CONFIGURATION
# =======================
ADMIN_USER="ADMIN_ACCOUNT"
LOGFILE="/var/log/jamf_ssh_setup.log"
PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Jamf binary detection
if [[ -x /usr/local/bin/jamf ]]; then
    JAMF="/usr/local/bin/jamf"
elif [[ -x /usr/local/jamf/bin/jamf ]]; then
    JAMF="/usr/local/jamf/bin/jamf"
else
    JAMF=""
fi

# =======================
# LOGGING
# =======================
exec >> "$LOGFILE" 2>&1
echo "=================================================="
echo "$(date): Starting SSH enablement for LAPS admin [$ADMIN_USER]"
echo "=================================================="

# =======================
# STEP 1: ENSURE USER EXISTS
# =======================
if ! id "$ADMIN_USER" &>/dev/null; then
    echo "Creating hidden local admin account: $ADMIN_USER"
    /usr/sbin/sysadminctl \
        -addUser "$ADMIN_USER" \
        -admin \
        -hiddenUser 1 \
        >/dev/null 2>&1 || {
            echo "ERROR: Failed to create user $ADMIN_USER"
            exit 1
        }
else
    echo "User $ADMIN_USER already exists"
fi

# =======================
# STEP 2: ENSURE ADMIN PRIVILEGES
# =======================
if ! /usr/bin/dscl . -read /Groups/admin GroupMembership 2>/dev/null | grep -qw "$ADMIN_USER"; then
    echo "Adding $ADMIN_USER to admin group"
    /usr/bin/dscl . -append /Groups/admin GroupMembership "$ADMIN_USER" || {
        echo "ERROR: Failed to add $ADMIN_USER to admin group"
        exit 1
    }
else
    echo "$ADMIN_USER already in admin group"
fi

# =======================
# STEP 3: ENABLE SSH SERVICE
# =======================
SSH_STATUS="$(/usr/sbin/systemsetup -getremotelogin 2>/dev/null)"

if [[ "$SSH_STATUS" != *"On"* ]]; then
    echo "Enabling Remote Login (SSH)"
    /usr/sbin/systemsetup -setremotelogin on >/dev/null 2>&1 || {
        echo "ERROR: Failed to enable SSH"
        exit 1
    }
else
    echo "SSH already enabled"
fi

# Ensure sshd launch daemon is enabled
/bin/launchctl enable system/com.openssh.sshd >/dev/null 2>&1 || true

# =======================
# STEP 4: RESTRICT SSH ACCESS TO EXPLICIT USERS
# =======================
if ! /usr/bin/dscl . read /Groups/com.apple.access_ssh &>/dev/null; then
    echo "Creating com.apple.access_ssh group"
    /usr/bin/dscl . create /Groups/com.apple.access_ssh
fi

CURRENT_MEMBERS="$(/usr/bin/dscl . -read /Groups/com.apple.access_ssh GroupMembership 2>/dev/null | awk -F': ' '{print $2}')"

if [[ ! " $CURRENT_MEMBERS " =~ " $ADMIN_USER " ]]; then
    echo "Granting SSH access to $ADMIN_USER"
    /usr/bin/dscl . append /Groups/com.apple.access_ssh GroupMembership "$ADMIN_USER" \
        >/dev/null 2>&1 || {
            echo "ERROR: Failed to add $ADMIN_USER to SSH access group"
            exit 1
        }
else
    echo "$ADMIN_USER already authorized for SSH"
fi

# =======================
# STEP 5: VERIFICATION
# =======================
echo "Verification:"
/usr/bin/dscl . -read /Groups/com.apple.access_ssh GroupMembership 2>/dev/null || \
    echo "WARNING: Unable to read SSH group membership"

echo "Remote Login Status: $(/usr/sbin/systemsetup -getremotelogin 2>/dev/null || echo 'Unknown')"

# =======================
# STEP 6: JAMF INVENTORY UPDATE
# =======================
if [[ -n "$JAMF" ]]; then
    echo "Running jamf recon"
    "$JAMF" recon >/dev/null 2>&1 || echo "WARNING: jamf recon failed"
else
    echo "Jamf binary not found — skipping recon"
fi

echo "SUCCESS: SSH enabled and restricted to $ADMIN_USER"
exit 0
