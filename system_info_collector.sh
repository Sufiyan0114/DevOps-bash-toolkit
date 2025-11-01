#!/usr/bin/env bash

# Author: Shaikh Sufiyan
# Title: Script to collect basic server information 
# Description:  A Bash script designed with security best practices for fast execution and proper error handling 
# Version: 1.0

# -x for execution trace
set -eou pipefail 

exception() {
  local exit=$?
  if [[ ${exit} -ne 0 ]]; then 
    echo "Script exited with code: ${exit}" >&2
  fi  
}

# non-zero exit code
trap exception ERR
# exit script if it returns a non zero exit code 
trap exception EXIT

sys_monitor() {

  local memory swap disk cpu 
  # collecting info from Memory and swap memory (if swap is enabled) and
  # cpu percentage with disk usage
  memory=$(free -m | awk '/Mem:/ {
      printf "Memory information:\n\t"
      printf "- Total memory:     %s MB\n\t", $2
      printf "- Used memory:      %s MB\n\t", $3
      printf "- Free memory:      %s MB\n\t", $4
      printf "- Share/cache:      %s MB\n\t", $5
      printf "- Available memory: %s MB\n\t", $6
    }
  ')

  swap=$(free -m | awk '/Swap:/ {
      printf "Swap Memory information:\n\t"
      printf "- Total swap memory: %s MB\n\t", $2
      printf "- Used swap memory:  %s MB\n\t", $3
      printf "- Free swap memory:  %s MB\n\t", $4
    }
  ')

   cpu=$(top -bn1 | grep "Cpu(s)" | awk '{
      printf "Cpu(s) percentage: \n\t"
      printf "CPU Usage: %.1f%%\n\t", 100 - $8
    }
  ')
  
  disk=$(df -h | grep -E '^/dev/' | awk '{
       printf "Disk Information: \n\t"
       printf "Disk name: %s \n\t", $1
       printf "Disk size: %s \n\t", $2
       printf "Disk used: %s \n\t", $3
       printf "Disk available: %s \n\t", $4
    }
  ')
 
  echo -e "${memory}\n" "${swap}\n" "${cpu}\n" "${disk}\n" 
}

net_info() {
   #  collecting network information of a server
  local hostname ip_addr active_interface
  hostname=$(hostname -f 2>/dev/null || echo $HOSTNAME)
  ip_addr=$(hostname -I | awk '{print $1}')
  active_interface=$(
    # using a 'loop' to display one or more interfaces
    local n=1
    while read -r iface status addresses; do
        printf "Interface #%d:\n" "$n" 
        printf "\tName       : %s\n" "$iface"
        printf "\tStatus     : %s\n" "$status" 
        printf "\tAddresses  : %s\n\n" "$addresses" 
        n=$((n+1))
    done < <(ip -br addr show | grep -v "DOWN") # grep -v "DOWN" to avoid down interfaces
  )
  echo -e "${hostname}\n" "${ip_addr}\n" "${active_interface}"   
}

sys_info() {
 #always use 'local' inside functions
 local os_name os_version kernel usrs currentusr
  os_name=$(grep '^NAME=' /etc/os-release | awk -F'"' '/^NAME=/ {print $2}')
  os_version=$(grep '^VERSION=' /etc/os-release | awk -F'"' '/^VERSION=/ {print $2}')

 kernel=$(uname -r)
 usrs=$(who | wc -l)
 currentusr=${USER}
    echo -e "Operating System:"
    echo -e "\tName          : $os_name"
    echo -e "\tVersion       : $os_version"
    echo -e "Kernel          : $kernel"
    echo -e "Logged-in Users : $usrs"
    echo -e "Current User    : $currentusr"
}

read -p "Please enter full path for save report [default path: ${HOME}/system-monitoring]: " usrpath

# config directories
readonly dir="${usrpath:-${HOME}/system-monitoring}"
readonly current_date=$(date +"%Y-%m-%d")
readonly r="${dir}/report-${current_date}.txt"
readonly tempf="${dir}"/temporary_file

# secure permission
# execute(1), read(4), write(2)
# special bit (like setgid, sticky bit)
readonly file_perm="0600" # only owner can read and write, no permissions for group and others 
readonly dir_perm="0700" #only owner can execute, read and write, no permissions for group and others

# check if directory exits or not, if not create it
if [[ ! -d ${dir} ]]; then
    if ! mkdir -p "${dir}" 2>/dev/null; then
      echo "Exit! failed to create directory:${dir}"
      exit 1
    fi 
    # restrictive permissions 
    chmod "${dir_perm}" "${dir}" || {
      echo "directory permission error"
      exit 1
    }

fi   
# check ownership, if root user run this script it become owner of this directory,
# and others cannot access this directory, script will fail.
#but if a normal user runs this script other can access via same group permissions
if [[ $(stat -c %U "${dir}") != "${USER}" ]]; then
    echo "current user not owned this directory: ${dir}" >&2
    exit 1
fi

# prevent functions to override
readonly -f sys_monitor
readonly -f sys_info
readonly -f net_info
{
cat <<EOF
Date=$(date)
User=${USER}

EOF

sys_monitor
net_info
sys_info

} > "${tempf}" 

# check if the file exits and is not empty 
if [[ -s "${tempf}" ]]; then
   echo "Report created"
else
  echo "error while saving report in a temporary file"
  rm -f "${tempf}"
  exit 1
fi  

chmod "${file_perm}" "${tempf}"
mv -f "${tempf}" "${r}"
echo "saved report with restricted permissions"
echo "path: " $r

