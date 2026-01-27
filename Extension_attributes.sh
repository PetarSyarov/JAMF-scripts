# Get LocalHostName
localhostName=$(scutil --get LocalHostName 2>/dev/null)

# If localhostname is empty, set a fallback
if [ -z "$localhostName" ]; then
    localhostName="(No LocalHostName Set)"
fi

# Output in JAMF EA format
echo "<result>$localhostName</result>"



-----------------------------------------------------------------------------------------------------------------------



# Get HostName
hostName=$(scutil --get HostName 2>/dev/null)

# If hostname is empty, set a fallback
if [ -z "$hostName" ]; then
    hostName="(No HostName Set)"
fi

# Output in JAMF EA format
echo "<result>$hostName</result>"


-----------------------------------------------------------------------------------------------------------------------

#!/bin/bash

# --- Hostname (Office fallback only) ---
host="$(scutil --get LocalHostName 2>/dev/null)"
[[ -z "$host" ]] && host="$(hostname -s 2>/dev/null)"
[[ -z "$host" ]] && host="UnknownHost"

# --- Try to detect VPN IPv4 via utun interfaces ---
vpn_ip=""

# Fast path: ipconfig (preferred)
for iface in $(ifconfig | awk '/^utun[0-9]+:/{print $1}' | sed 's/://'); do
  ip=$(ipconfig getifaddr "$iface" 2>/dev/null)
  if [[ -n "$ip" ]]; then
    vpn_ip="$ip"
    break
  fi
done

# Fallback: parse ifconfig directly (covers GP edge cases)
if [[ -z "$vpn_ip" ]]; then
  vpn_ip=$(ifconfig 2>/dev/null | awk '
    $1 ~ /^utun[0-9]+:$/ {in_utun=1; next}
    in_utun && $1=="inet" {print $2; exit}
    in_utun && $1 ~ /^[a-z0-9]/ && $1 !~ /^(inet|inet6|nd6|options|status)$/ {in_utun=0}
  ')
fi

# --- Output ---
if [[ -n "$vpn_ip" ]]; then
  echo "<result>$vpn_ip</result>"
else
  echo "<result>${host} (Office)</result>"
fi

