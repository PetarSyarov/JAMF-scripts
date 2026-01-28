# Get HostName
hostName=$(scutil --get HostName 2>/dev/null)

# If hostname is empty, set a fallback
if [ -z "$hostName" ]; then
    hostName="(No HostName Set)"
fi

# Output in JAMF EA format
echo "<result>$hostName</result>"
