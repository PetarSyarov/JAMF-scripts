launchctl unload /Library/LaunchAgents/com.paloaltonetworks.gp.pangp* 2>/dev/null

launchctl unload /Library/LaunchDaemons/com.paloaltonetworks.gp.pangp* 2>/dev/null

sudo rm -rf /Applications/GlobalProtect.app

sudo rm -rf /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*

sudo rm -rf /Library/LaunchDaemons/com.paloaltonetworks.gp.pangp*

sudo rm -rf /Library/Extensions/PANGP.kext

sudo rm -rf /Library/Preferences/com.paloaltonetworks.*

sudo rm -rf /Library/Logs/PaloAltoNetworks

sudo rm -rf /Library/Application\ Support/PaloAltoNetworks

sudo rm -rf /private/var/db/receipts/com.paloaltonetworks.*

sudo rm -rf ~/Library/Preferences/com.paloaltonetworks.*