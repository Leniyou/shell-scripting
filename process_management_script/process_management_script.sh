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
DATE=$(date +'%F')				          # Variable DATE for log file name. e.g.: log-2022-09-30

### These two var can be edited as user wish ###
LOG_DIR="${FULL_PATH}/logs"			    # The log file path should be configured using a variable
TARGET_SERVICE="httpd.service"			# The target service should be configured using a variable 

## To check if the log directory is not created ##
if [[ ! -d $LOG_DIR ]];		
then
  if ! mkdir "$LOG_DIR";
  then
    # If there is an error creating directory script will exit status 1
    
    # Logs for debugging printed on terminal
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Error: Unable to create log directory %s\n" "$LOG_DIR"
    printf "Recommendation: Please check if you have proper permissions on the selected folder %s\n" "$FULL_PATH"
    printf "Exit status: 1\n"

    # Exit script
    exit 1

  else
    # Logs for debugging printed on terminal
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Message: log dir %s\n" "$LOG_DIR"
    printf "Created successfully in folder %s\n" "$FULL_PATH"
    printf "Exit status: 0\n"
  fi
fi

## Now script will create debug.log file ##
# for logging information about commands ran by the script
if [[ ! -f "$LOG_DIR"/debug.log ]];
then
  # If debug.log file is not created already
  # Then create it
  if ! touch "$LOG_DIR"/debug.log;
  then
    # Logs for debugging printed on terminal
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Error: Unable to create file %s\n" "debug.log"
    printf "Recommendation: Please check if you have proper permissions on the selected folder %s\n" "$LOG_DIR"
    printf "Exit status: 1\n"

    # Exit script
    exit 1   

  else
    # Logs for debugging printed on terminal
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Message: Log file debug.log\n"
    printf "Created successfully in %s\n" "$LOG_DIR"
    printf "Exit status: 0\n"

  fi
fi

## Then, script will create log-date file ##
# for logging information about selected target service
if [[ ! -f "$LOG_DIR"/log-$DATE ]]
then
  # If log-date file is not created already
  # Then create it
  if ! touch "$LOG_DIR"/log-"$DATE";
  then
    # Logs for debugging printed on terminal
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Error: Unable to create file %s\n" "log-${DATE}"
    printf "Recommendation: Please check if you have proper permissions on the selected folder %s\n" "$LOG_DIR"
    printf "Exit status: 1\n"

    # Exit script
    exit 1   

  else
    # Logs for debugging printed on terminal
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Message: Log file %s\n" "log-${DATE}"
    printf "Created successfully in %s\n" "$LOG_DIR"
    printf "Exit status: 0\n"

  fi
fi

## Logs for debugging saved to debug.log file ##
(
  printf "\nDate: %s\n" "$(date)"
  printf "Username: %s\n" "$USER"
  printf "Message:\n"
  printf "  The %s\n" "${TARGET_SERVICE}"
  printf "  has been selected as the target service.\n"
  printf "  Running systemctl list-unit-files | grep -q ${TARGET_SERVICE} %s\n"
  printf "  to check if the service is enabled or installed on this workstation\n"
  printf "...\n"
) >> "$LOG_DIR"/debug.log

## Script now will check if selected service is enabled or installed on this machine ##
if ! systemctl list-unit-files | grep -q "${TARGET_SERVICE}"
then
  # If selected service is not installed or enabled 
  echo "The selected service ${TARGET_SERVICE} is not installed or it is not enabled on this workstation, further information can be found in ${LOG_DIR}/debug.log file"
  
  # Logs for debugging saved in debug.log file
  (
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Error: Target service is not installed or enabled on this workstation\n"
    printf "Message:\n"
    printf "  systemctl list-unit-files | grep -q ${TARGET_SERVICE} %s\n"
    printf "  returned code 1, it means that the ${TARGET_SERVICE} %s\n"
    printf "  is not installed or is not enabled on this workstation.\n"
    printf "Recommendation:"
    printf "  Please spell check the service name you just typed or verify \n"
    printf "  the list of installed services running the next command: systemctl --all --type service\n"
    printf "Exit status: 1\n"
  ) >> "$LOG_DIR"/debug.log
  
  # Exit script
  exit 1

else
  # If selected service is installed or enabled
  (
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Message:\n"
    printf "  systemctl list-unit-files | grep -q ${TARGET_SERVICE} %s\n"
    printf "  returned code 0, it means that the ${TARGET_SERVICE} %s\n"
    printf "  is installed/enabled on this workstation.\n"
    printf "  Running systemctl show -p SubState --value ${TARGET_SERVICE} %s\n"
    printf "  to check if ${TARGET_SERVICE} is Up/Started. %s\n"
    printf "...\n"
  ) >> "$LOG_DIR"/debug.log

  # Now script will check if service is UP/Running
  STATUS=$(systemctl show -p SubState --value "${TARGET_SERVICE}")
  if [[ $STATUS != "running" ]]	
  then
    # If service is not running
    (
      printf "\nDate: %s\n" "$(date)"
      printf "Username: %s\n" "$USER"
      printf "Message: The ${TARGET_SERVICE} is Stopped/Inactive (dead) %s\n"
      printf "Exit status: 0\n"
    ) >> "$LOG_DIR"/debug.log
  
  else
    # If service is running then
    (
      printf "\nDate: %s\n" "$(date)"
      printf "Username: %s\n" "$USER"
      printf "Message: The ${TARGET_SERVICE} is Runinng/Active %s\n"
      printf "Exit status: 0\n"
    ) >> "$LOG_DIR"/debug.log

  fi

  # To start logging target service status
  ACTIVE_STATUS=$(systemctl status $TARGET_SERVICE | grep "Active")
  MAIN_PID=$(systemctl status $TARGET_SERVICE | grep "Main PID")
  LOGS=$(systemctl status --no-pager -l $TARGET_SERVICE | grep "systemd")

  # Logs for debugging saved in debug.log file
  (
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Message:\n"
    printf "  Starting gather status information about the %s${TARGET_SERVICE}\n"
    printf "  Running: systemctl status %s$TARGET_SERVICE | grep 'Active'\n"
    printf "    to get service status\n"
    printf "  Running: systemctl status %s$TARGET_SERVICE | grep 'Main PID'\n"
    printf "    to get service main process ID\n"
    printf "  Running: systemctl status --no-pager -l %s$TARGET_SERVICE | grep 'systemd'\n"
    printf "    to get service aditional information\n"
    printf "Exit status: 0\n"
  ) >> "$LOG_DIR"/debug.log

  # Logs for logging saved in log-date file
  # Logging information about the selected service
  printf "\nDate: %s\n" "$(date)"
  printf "Username: %s\n" "$USER"
  printf "Service name: %s\n" "$TARGET_SERVICE"
  printf "Active status: %s\n" "$ACTIVE_STATUS"
  printf "Main Process ID: %s\n" "$MAIN_PID"
  printf "Logs:\n"
  printf "%s\n" "$LOGS"
  printf "\n"

  ## To add this script as a cronjob on crontab
  # Add SHELL to crontab
  (crontab -l; echo "SHELL=/bin/bash") | awk '!x[$0]++' | crontab -

  # Add PATH to crontab
  (crontab -l; echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin") | awk '!x[$0]++' | crontab -

  # Add this script to crontab
  (crontab -l; echo "# To monitor target service $TARGET_SERVICE") | crontab -
  (crontab -l; echo "*/5 * * * * $FULL_PATH/$SCRIPT_NAME >> $LOG_DIR/log-$DATE 2>&1") | awk '!x[$0]++' | crontab -

  # Logs for debugging saved in debug.log file
  (
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "$USER"
    printf "Message:\n"
    printf "  Adding this script %s./$SCRIPT_NAME as a cronjob\n"
    printf "  To run every 5 minutes and gather information about the %s$TARGET_SERVICE\n"
    printf "Exit status: 0\n"
  ) >> "$LOG_DIR"/debug.log

fi
exit 0
