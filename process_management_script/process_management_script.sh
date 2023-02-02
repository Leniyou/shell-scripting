#!/bin/bash
#
# ### Process management script ###
# One of our systems has a service that exits randomly.
# We know this is a common issue but the maintainers of 
# the service stated they wont resolve this issue any 
# time soon since it is only affecting some users (edge
# case) and workarounds can be implemented outside the
# source code of the service. Thus, we shall implement a
# workaround for us.
# 
# The DevOps manager has requested you to design a script 
# that will check if the process is up and perform some 
# task if it s not. The specific requirements are:
# 
# - Exists automatically if an error is found.
# - The script should be place as a cronjob for the root user.
# - The script should log whether the service is up, down, or 
# started if it was down.
# - The log file path should be configured using a variable.
# - Log useful comments and data at each step.
# - The target service should be configured using a variable 
# (so if we want to change the target process, we can do it by
# simply changing the name of the variable)
#

### Let's set some global variables ###
SCRIPT_NAME=$(basename "$0")	      # Script name 
USER=$(whoami)					            # Getting the user who is running the script
FULL_PATH=$(pwd)				            # Getting full path where the script is

### These two var can be edited as user will ###
# The log file path should be configured using a variable
LOG_DIR="${FULL_PATH}/logs"			    

# The target service should be configured using a variable
# if you change the target service, please make sure to add
# .service at the end in order to this script to work
TARGET_SERVICE="httpd.service"			

# Variable for log file name. e.g.: httpd.service-2022-09-30.log
SERVICE_LOG_FILE="${TARGET_SERVICE}"-$(date +'%F').log

## To create log directory and debug.log file ##
# -p option is to override it is already created
mkdir -p "${LOG_DIR}" && touch "${LOG_DIR}"/debug.log

if [[ -d "${LOG_DIR}" ]]
then
  # Go into the log directory just created
  # if cannot be access then exit
  cd "${LOG_DIR}" || exit
  # Logs for debugging stored in debug.log file
  (
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "${USER}"
    printf "Message: \n"
    printf "  Log directory created successfully\n"
    printf "  %s\n" "${LOG_DIR}"
  ) >> debug.log
else
  # Logs for debugging stored in debug.log file
  (
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "${USER}"
    printf "Error: \n" 
    printf "  Unable to create log directory %s\n ${LOG_DIR}"
    printf "Recommendation: \n"
    printf "  Please check if you have proper permissions on the selected folder %s\n ${FULL_PATH}"
    printf "Exit status: 1\n"
  ) >> debug.log

  # If there is an error creating directory script will exit with status 1
  exit 1
fi

## Then, script will create httpd.service-2022-09-30.log file ##
# for logging information about selected target service
## To create service log file ##
if touch "${SERVICE_LOG_FILE}";
then
  # Logs for debugging stored in debug.log file
  (
    printf "\n"
    printf "  Log file %s\n" "${LOG_FILE}" 
    printf "  created successfully in the selected folder: \n"
    printf "  %s" "${LOG_DIR}"
    printf "\n"
  ) >> debug.log
else
  # Logs for debugging stored in debug.log file
  (
    printf "\n"
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "${USER}"
    printf "Error: \n"
    printf "  Unable to create file %s\n" "${LOG_FILE}"
    printf "Recommendation: \n"
    printf "  Please check if you have proper permissions in the selected folder \n"
    printf " %s" "${LOG_DIR}"
    printf "\n"
    printf "Exit status: 1\n"
  ) >> debug.log
  # If there is an error creating log file script will exit with status 1
  exit 1
fi

## Logs for debugging stored to debug.log file ##
(
  printf "\nDate: %s\n" "$(date)"
  printf "Username: %s\n" "${USER}"
  printf "Message:\n"
  printf "  ${TARGET_SERVICE} has been selected as the target service. %s\n"
  printf "Running: \n"
  printf "  systemctl list-unit-files | grep -q %s" "${TARGET_SERVICE}"
  printf "  to check if the service is enabled or installed on this workstation.\n"
) >> debug.log

## Script now will check if selected service is enabled or installed on this machine ##
if ! systemctl list-unit-files | grep -q "${TARGET_SERVICE}"
then
  # If selected service is not installed or enabled 
  echo "The selected service ${TARGET_SERVICE} is not installed or enabled on this workstation, further information can be found in ${LOG_DIR}/debug.log file"
  
  # Logs for debugging saved in debug.log file
  (
    printf "Error: Target service is not installed or enabled on this workstation\n"
    printf "Message:\n"
    printf "  systemctl list-unit-files | grep -q %s\n ${TARGET_SERVICE} returned code 1,"
    printf "  it means that the %s\n ${TARGET_SERVICE} is not installed or is not enabled on this workstation.\n"
    printf "Recommendation:"
    printf "  Please spell check the service name you just typed or verify \n"
    printf "  the list of installed services running the next command: systemctl --all --type service\n"
    printf "Exit status: 1\n"
  ) >> debug.log
  
  # Exit script
  exit 1

else
  # If selected service is installed or enabled
  (
    printf "  Service is enabled/installed on this workstation.\n"
    printf "Running: \n"
    printf "  systemctl show -p SubState --value %s ${TARGET_SERVICE} to check if service is Up/Started. \n"
  ) >> debug.log

  # Now script will check if service is UP/Running
  STATUS=$(systemctl show -p SubState --value "${TARGET_SERVICE}")
  if [[ "${STATUS}" != "running" ]]	
  then
    # If service is not running
    (
      printf "  The %s${TARGET_SERVICE} is Stopped/Inactive (dead)\n"
    ) >> debug.log
  
  else
    # If service is running
    (
      printf "  The %s ${TARGET_SERVICE} is Runinng/Active\n"
    ) >> debug.log
  fi
fi # // end if service is installed

## To start logging target service status ##
ACTIVE_STATUS=$(systemctl status "${TARGET_SERVICE}" | grep "Active")
MAIN_PID=$(systemctl status "${TARGET_SERVICE}" | grep "Main PID")
LOGS=$(systemctl status --no-pager -l "${TARGET_SERVICE}" | grep "systemd")

# Logs for debugging saved in debug.log file
(
  printf "\n"
  printf "Message:\n"
  printf "  Starting gather status information about the %s ${TARGET_SERVICE} \n"
  printf "Running: \n"
  printf "  systemctl status %s ${TARGET_SERVICE} | grep 'Active' to get service status \n"
  printf "  systemctl status %s ${TARGET_SERVICE} | grep 'Main PID' to get service main process ID \n"
  printf "  systemctl status --no-pager -l %s ${TARGET_SERVICE} | grep 'systemd' to get service additional information \n"
) >> debug.log

# Logs for logging saved in service log file
# Logging information about the selected service
printf "\nDate: %s\n" "$(date)"
printf "Username: %s\n" "${USER}"
printf "Service name: %s\n" "${TARGET_SERVICE}"
printf "Active status: %s\n" "${ACTIVE_STATUS}"
printf "Main Process ID: %s\n" "${MAIN_PID}"
printf "Logs:\n"
printf "%s\n" "${LOGS}"

## To add this script as a cronjob on crontab ##
# awk '!x[$0]++' parameter removes duplicate lines from text input without pre-sorting,
# everytime the script is added to crontab, it will be added as a new line, this parameter
# avoid to duplicate that entry in the cronjob file.

# Add SHELL to crontab
(crontab -l; echo "SHELL=/bin/bash") | awk '!x[$0]++' | crontab -

# Add PATH to crontab
(crontab -l; echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin") | awk '!x[$0]++' | crontab -

# Add this script to crontab
(crontab -l; echo "# To monitor target service ${TARGET_SERVICE}") | crontab -
(crontab -l; echo "*/5 * * * * $FULL_PATH/$SCRIPT_NAME >> ${LOG_DIR}/${SERVICE_LOG_FILE} 2>&1") | awk '!x[$0]++' | crontab -

# Logs for debugging saved in debug.log file
(
  printf "\nDate: %s\n" "$(date)"
  printf "Username: %s\n" "${USER}"
  printf "Message:\n"
  printf "  Adding this script %s ./${SCRIPT_NAME} as a cronjob \n"
  printf "  To run every 5 minutes and gather information about the %s ${TARGET_SERVICE}\n"
  printf "Exit status: 0\n"
) >> debug.log
