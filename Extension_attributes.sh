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



