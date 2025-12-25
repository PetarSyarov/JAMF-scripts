# JAMF-scripts

 # Naming+ 
This script handles standardized naming of devices in the JAMF management environment. 
After the initial naming has been applied, there are several functions that go over the HostName and LocalHostName parameters. 
Those are vital for machine visibility within DNS and Firewalls. 
If those are not correctly set to match the ComputerName parameter, the devies will appear as just " Macbook pro " in any network monitoring tools. 
In terms of naming convention as outlined in the script, this is the naming convention that has been adopted:
Tripple letter abbreviation for the company that owns the device, followed by the location of the device ( country of city ), type of device and a tripple digit numbering convention.

 #
