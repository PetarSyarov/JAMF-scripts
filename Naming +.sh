#!/bin/bash
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

[ -f /tmp/debug ] && set -x

# CONFIGURABLES ———————————————————————————————————————————————————————————————————————————
PREFIX="Company name-Location-Typology-"
DIGITS_NO=3
UPDATE_ASSET_TAG=true
TAG_VIRTUAL_MACHINES=true

# PREREQUISITES —————————————————————————————————————————————————————————————————————————
VM_SUFFIX="-VM"
JAMF=/usr/local/bin/jamf
[[ $(sysctl -n machdep.cpu.features kern.hv_vmm_present) =~ ((^|[^[:alnum:]])VMM([^[:alnum:]]|$)|^.*1$) ]] && VM=true || VM=false

# FUNCTIONS ———————————————————————————————————————————————————————————————————————————

function exitWith() {
  echo -e "${2}"
  exit ${1}
}

function validateComputerName() {
  local COMPUTER_NAME="${1}"
  if [[ "${COMPUTER_NAME}" =~ ^"${PREFIX}"[[:digit:]]{"${DIGITS_NO}"}$ ]]; then
    return 0
  elif $TAG_VIRTUAL_MACHINES && [[ "${COMPUTER_NAME}" =~ ^"${PREFIX}"[[:digit:]]{"${DIGITS_NO}"}"${VM_SUFFIX}"$ ]]; then
    return 0
  else
    return 1
  fi
}

function addLeadingZeros() {
  local DIGITS=${1}
  local DIGITS_LENGTH=${#1}
  for (( i=0; i<$((DIGITS_NO-DIGITS_LENGTH)); i++ )); do
    DIGITS="0${DIGITS}"
  done
  echo "${DIGITS}"
}

function setComputerName() {
  local COMPUTER_NAME="${1}"
  echo "Changing computer name to \"${COMPUTER_NAME}\"."
  if [ -x "${JAMF}" ]; then
    "${JAMF}" setComputerName -name "${COMPUTER_NAME}"
  else
    scutil --set ComputerName "${COMPUTER_NAME}"
    scutil --set LocalHostName "${COMPUTER_NAME// /-}"
    scutil --set HostName "${COMPUTER_NAME// /-}"
  fi
}

# Skip if already correct
function shouldSetNames() {
  local TARGET="${1// /-}"
  local CUR_COMP="$(scutil --get ComputerName 2>/dev/null || echo "")"
  local CUR_LHOST="$(scutil --get LocalHostName 2>/dev/null || echo "")"
  local CUR_HOST="$(scutil --get HostName 2>/dev/null || echo "")"

  if [[ "${CUR_COMP}" == "${TARGET}" && "${CUR_LHOST}" == "${TARGET}" && "${CUR_HOST}" == "${TARGET}" ]]; then
    echo "All names already correctly set to \"${TARGET}\" — nothing to do."
    return 1
  fi
  return 0
}

# Enforce HostName persistently
function enforceHostName() {
  local DESIRED_HOST="${1// /-}"
  local CUR_HOST="$(scutil --get HostName 2>/dev/null || echo "")"

  if [[ "${CUR_HOST}" == "${DESIRED_HOST}" ]]; then
    echo "HostName already set to \"${DESIRED_HOST}\"."
    return 0
  fi

  echo "Enforcing HostName = \"${DESIRED_HOST}\"."

  # Remove stale HostName entry from preferences
  /usr/libexec/PlistBuddy -c "Delete :System:HostName" /Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null || true

  # Set via scutil and hostname
  scutil --set HostName "${DESIRED_HOST}" 2>/dev/null || true
  hostname "${DESIRED_HOST}" 2>/dev/null || true

  # Flush caches
  dscacheutil -flushcache 2>/dev/null || true
  killall -HUP mDNSResponder 2>/dev/null || true
  sleep 1

  CUR_HOST="$(scutil --get HostName 2>/dev/null || echo "")"
  if [[ "${CUR_HOST}" == "${DESIRED_HOST}" ]]; then
    echo "HostName successfully set to \"${DESIRED_HOST}\"."
    return 0
  fi

  echo "HostName may not have persisted correctly (non-fatal)."
  return 0
}

# MAIN SCRIPT ————————————————————————————————————————————————————————————————————————

COMPUTER_NAME="$(scutil --get ComputerName 2>/dev/null || echo "")"

# Generate name from Jamf Computer ID if invalid
if ! validateComputerName "${COMPUTER_NAME}"; then
  echo "Computer name \"${COMPUTER_NAME}\" is not valid — generating new name from Jamf ID."

  JAMF_ID="$(${JAMF} recon 2>/dev/null | awk -F'<|>' '/<computer_id>/{print $3}')"

  # Validate Jamf ID
  if [[ -z "${JAMF_ID}" || ! "${JAMF_ID}" =~ ^[0-9]+$ ]]; then
    exitWith 1 "ERROR: Unable to obtain valid Jamf Computer ID!"
  fi

  DIGITS="$(addLeadingZeros ${JAMF_ID})"

  COMPUTER_NAME="${PREFIX}${DIGITS}"
  $VM && $TAG_VIRTUAL_MACHINES && COMPUTER_NAME="${COMPUTER_NAME}${VM_SUFFIX}"

  if ! validateComputerName "${COMPUTER_NAME}"; then
    exitWith 2 "ERROR: Failed to validate generated computer name \"${COMPUTER_NAME}\"!"
  fi
else
  echo "Current computer name \"${COMPUTER_NAME}\" successfully validated."
fi

# Skip if all names already correct
DESIRED_NAME="${COMPUTER_NAME// /-}"
if ! shouldSetNames "${DESIRED_NAME}"; then
  echo "No changes required — exiting successfully."
  "${JAMF}" recon &> /dev/null
  exit 0
fi

# Update Asset Tag (optional)
if $UPDATE_ASSET_TAG && ! $VM; then
  if ! "${JAMF}" recon -assetTag "${COMPUTER_NAME}" &> /dev/null; then
    echo "Could not update Asset Tag (non-fatal)."
  fi
else
  "${JAMF}" recon &> /dev/null
fi

# Apply names
setComputerName "${COMPUTER_NAME}"

# Enforce HostName persistently
enforceHostName "${DESIRED_NAME}"

# Final inventory update
"${JAMF}" recon &> /dev/null

echo "Completed successfully — ComputerName, LocalHostName, and HostName set to \"${COMPUTER_NAME}\"."
exit 0
