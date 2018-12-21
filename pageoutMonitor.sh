#!/bin/bash
  # This is a re-write of a script to check for pageouts on a machine and only report back to Jamf Pro once per week if the memory usage pageout situation has changed. This is to avoid calling recon every time the machine runs the script which would destroy the database on the server.
  # If this is run as a Jamf Script and not kicked off by a Launch Agent it will log the standard output and up-to-date pageout information will be available in the policy logs. You can also choose to have this policy run even if the JPS is not available through a policy, though the log will not make it back to the JPS.


  #Specifies the location of the log file to write. This location can be changed to a location not accessable by the user if desired.
logfile="/var/log/pageoutMonitor.log"

  #Specifies the location of the file that will be read by the Jamf Pro EA.
last_page_out_file="/var/log/last_page_out.log"

  #Pulls the last time the system was booted, omitting irrelivent information, line break, and extra spaces.
lastboot=$(last boot | awk '{print $4,$5,$6}' | tr -d "\n" | sed 's/  //')

  #Human readable date and time (24 hour time) for first line of each log entry.
humandate=$(date +"%A %m-%d-%Y %R:%S")

  #Date command formatted to match the format the JPS is looking for in Extension Attributes.
jamfdate=$(date +"%Y-%m-%d %T")

  #This pulls the number of pageouts since the last reboot.
pageouts=$(vm_stat | grep "Pageouts" | awk '{print substr($2, 1, length($2)-1)}')


logRotate ()
#This function will rotate the log file when it gets to 1MB and will save one rotation.

{

if [[ $(find ${logfile} -type f -size +1M) ]]; then
  printf "Log File is over 1MB, rotating."
  mv "${logfile}" "${logfile}"-rotated
  printf "Log file reached 1MB and was rotated on ${humandate}. Old log has been renamed to ${logfile}-rotated and will be kept until the next rotation.\n\n" > "${logfile}"

else
  printf "Log file is under 1MB, no rotation needed."
fi
}


pageoutCheck ()
{

  #This function checks for current pageouts and logs them. If a pageout is found the date will be written to the last_page_out_file to be read by an Extension Attribute in the JPS. It will fail with an error if it cannot complete. If the script is run from a Jamf Pro policy the policy should show a failure on the JPS.

if [[ "${pageouts}" -eq "0" ]]; then
  printf "${humandate} No Pageouts for current check. Last reboot was ${lastboot}." | tee /dev/tty >> "${logfile}"


elif [[ "${pageouts}" -gt "0" ]]; then
  printf "\n${humandate} - Current Pageout total since last reboot is ${pageouts}. Last reboot was ${lastboot}." | tee /dev/tty >> "${logfile}"
  printf "<result>${jamfdate}</result>" > ${last_page_out_file}

else
  printf "\n${humandate} Failure to calculate pageouts. Last reboot was ${lastboot}." | tee /dev/tty >> "${logfile}"
  exit 1
fi

}

# Omit log trimming if you would like by commenting it out in this section. Only do this if you are using another method to rotate/trim your logs!
logRotate
pageoutCheck
