 # Explanation for each script in this repo.

 # Naming+ 
This script handles standardized naming of devices in the JAMF management environment. 
After the initial naming has been applied, there are several functions that go over the HostName and LocalHostName parameters. 
Those are vital for machine visibility within DNS and Firewalls. 
If those are not correctly set to match the ComputerName parameter, the devies will appear as just " Macbook pro " in any network monitoring tools. 
In terms of naming convention as outlined in the script, this is the naming convention that has been adopted:
Tripple letter abbreviation for the company that owns the device, followed by the location of the device ( country of city ), type of device and a tripple digit numbering convention.

 # Lansweeper_install
Installing LansweeperAgent or LSAgent on MacBooks without having to upload the new package into the JAMF cloud package manager for every update.
Every time the script runs, it firstly checks if rosetta is present as a prerequisite, if not it's installed, afterwards the latest Lansweeper package is downloaded directly from the vendor website. 
Afterwards the install image is mounted under a newly created tmp directory.
Following the installtion the image is unmounted and removed from the system to conserve space.
Personally recommend to run this script every 5-6 months to keep all version of the Agent up to date.
Set to "Recurring check in" -> "Once per computer" and when an update is needed simply Flush the logs.

 # Remove_root
Simple script that removes the root priviliges from the primary logged in user on a JAMF managed MacBook.
Script is configured to keep root access for a number of accounts such as a helpdesk account or breakglass account to be able to restore the MacBook or SSH into said MacBook for remote intervention.

 # Restore_root
The exact opposite of the previous script.
Used to restore root access to the primary user on a JAMF managed MacBook.

 # Disable_AirDop
Disables the AirDrop on Macbooks. Kills Finder to force immediate effect. 

 # SSH_enable
Enables SSH for a specified admin user, preferrably a LAPS enabled user. 
Intended to be used in specific edge cases where user is remote and their work shouldn't be disturbed, hence why this is not pushing for tools like JAMF remote assist.
Enables SSH globally on the Macbook, but restricts it only to the specific admin user.

 # Restrict_login
Restricts access to the Macbook to all users apart from ones specified in the script. 

 # Restore_access
Restores access for the primary user, does not modify anything for specified system accounts. 
 # Extension_attributes
A combination of different extension attributes that I implemented for better tracking and sorting of devices 
 # JetBrainsApps_ChangeOwnership
Temproray fix to resolve issue where primary user can't upgrade their JetBrains apps ( can work for IntelliJ, PhpStorm, Pycharm etc.... )
Ownership is removed after 1-2 version upgrades.
