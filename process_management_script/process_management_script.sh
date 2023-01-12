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
## Let's set some global variables ##
SCRIPT_NAME="process_management_script.sh"		# Script name 
USER=$(whoami)				# Getting the user who is running the script
FULL_PATH=$(pwd)			# Getting full path where the script is being executed
DATE=`date +'%F'`			# Variable DATE for log file name. Ex: log-2022-09-30
## These two var can be edited as we wish ##
LOG_DIR="${FULL_PATH}/logs"		# The log file path should be configured using a variable
TARGET_SERVICE="httpd.service"		# The target service should be configured using a variable 

## Function to create LOG DIRECTORY ##
create_logs_directory () {

  ## Function to create LOG FILES ##
  create_log_files () {
  
    ## Function to validate if LOG FILES were created correctly ##
    validate_log_file () {
      local FILE=$1
      if [[ $? -ne 0 ]]			# Validate if file was created correctly
      then
        # Logs for debugging
        printf "Log created on: $(date)\nUsername: $USER\nMessage: Unable to create $FILE file\nPlease check if you have proper permissions on the selected folder $LOG_DIR\nExit status: 1\n\n"
        exit 1
      else
        # Logs for debugging
        printf "Log created on: $(date)\nUsername: $USER\nMessage: $FILE file was created successfully with touch command in the selected folder $LOG_DIR\nExit status: 0\n\n" >> $LOG_DIR/debug.log
      fi
    } # //end function validate_log_file
  
    #  We are going to create two log files
    #  - debug.log => to store logs regarding the functionality of this self script
    #  - log-date => to store logs related to the target service
    if [[ ! -f $LOG_DIR/debug.log ]]
    then
      touch $LOG_DIR/debug.log		# Creating debug.log file
      validate_log_file debug.log	# Validate if file was created correctly
    fi
    if [[ ! -f $LOG_DIR/log-$DATE ]]
    then
      touch $LOG_DIR/log-$DATE		# Creating log file
      validate_log_file log-$DATE	# Validate if file was created correctly
    fi
  } # //end function create_log_files
  
  ## Function to validate if LOG DIRECTORY was created correctly ##
  validate_logs_directory () {
    if [[ $? -ne 0 ]]			# Validate if the log directory was created
    then
      # Logs for debugging
      printf "\nLog created on: $(date)\nUsername: $USER\nMessage: Unable to create directory $LOG_DIR\nPlease check if you have proper permissions on the selected folder $FULL_PATH\nExit status: 1\n\n"
      exit 1
    else
      # Logs for debugging
      printf "Log created on: $(date)\nUsername: $USER\nMessage: Command mkdir $LOG_DIR executed successfully\nExit status: 0\n\n" >> $LOG_DIR/debug.log
    fi
  } # //end function validate_log_directory
  
  if [[ ! -d $LOG_DIR ]]		# We check if the directory is not created
  then
    mkdir $LOG_DIR			# Creating the Logs directory
    validate_logs_directory $?		# Validating if an error occurred
  fi
  create_log_files			# We call this function to create log files
} # //end function create_log_directory

create_logs_directory			# We call this function to create log directory

## This function check if the selected service exists on the host machine ##
check_if_service_exists () {

  ## Function to log data in LOG FILE ##
  logging () {
    # Logging information about the target service
    local ACTIVE_STATUS=$(systemctl status $TARGET_SERVICE | grep "Active")
    local MAIN_PID=$(systemctl status $TARGET_SERVICE | grep "Main PID")
    local LOGS=$(systemctl status --no-pager -l $TARGET_SERVICE | grep "systemd")
    # Logs for logging 
    printf "Log generated on: $(date)\nUsername: $USER\nService name: $TARGET_SERVICE\nActive status: $ACTIVE_STATUS\nMain Process ID: $MAIN_PID\nLogs: $LOGS\n\n"
    # Logs for debugging
    printf "Log created on: $(date)\nUsername: $USER\nMessage: Creating status logs for the $TARGET_SERVICE in log-$DATE file\nExit status: 0\n\n" >> $LOG_DIR/debug.log
  } # //end function logging
  
  ## This function checks if the selected service is running or stopped ##
  check_if_service_is_running () {
    # Logs for debugging
    printf "Log created on: $(date)\nUsername: $USER\nMessage: Running systemctl show -p SubState --value $1 to check if the target service is running\n" >> $LOG_DIR/debug.log
    local STATUS=$(systemctl show -p SubState --value "$1")	# This variable is used to check if the service is running
    if [[ $STATUS == "running" ]]				# Returned value should be "running"
    then
      # Logs for debugging
      printf "Message: The $1 is Runinng/Active\nExit status: 0\n\n" >> $LOG_DIR/debug.log
    else
      # # Logs for debugging
      printf "Message: The $1 is Stopped/Inactive (dead)\nExit status: 0\n\n" >> $LOG_DIR/debug.log
    fi
    
    logging				# We call this function to star loggind data to LOG FILE
  } # //end function check_if_service_running
  
  # Logs for debugging
  printf "Log created on: $(date)\nUsername: $USER\nMessage: The $1 has been selected as the target service\n" >> $LOG_DIR/debug.log
  printf "Message: Running systemctl list-unit-files | grep -q $1 to check if the service exists\n" >> $LOG_DIR/debug.log
  
  systemctl list-unit-files | grep -q "$1"	
  if  [[ $? -eq 0 ]]				# equal to 0 means the service exists
  then
    # Logs for debugging
    printf "Message: The $1 exists on this workstation\nExit status: 0\n\n" >> $LOG_DIR/debug.log
    check_if_service_is_running $1		# If the service exists now we will check if it is running
  else
    echo "The selected service $1 does not exist or it is not enabled on this workstation, further information can be found on $LOG_DIR/debug.log file"
    # Logs for debugging
    printf "Message: The $1 does not exist or it is not enabled on this workstation\n" >> $LOG_DIR/debug.log
    printf "Message: Please spell check the service name you just typed or verify the list of installed services running the next command: systemctl --all --type service\n" >> $LOG_DIR/debug.log
    printf "Exit status: 1\n\n" >> $LOG_DIR/debug.log
    exit 1
  fi
} # //end function check_if_service_exists

check_if_service_exists $TARGET_SERVICE		# We call this function to check if service exists

## Function to add this script as a cronjob on crontab
create_cronjob () {
  
  (crontab -l; echo "SHELL=/bin/bash") | awk '!x[$0]++' | crontab -			# Add SHELL to crontab
  (crontab -l; echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin") | awk '!x[$0]++' | crontab -	# Add PATH to crontab
  # Add this script to crontab
  (crontab -l; echo "# To monitor target service $TARGET_SERVICE") | crontab -
  (crontab -l; echo "*/5 * * * * $FULL_PATH/$SCRIPT_NAME >> $LOG_DIR/log-$DATE 2>&1") | awk '!x[$0]++' | crontab -
  
  # Logs for debugging
  printf "Log created on: $(date)\nUsername: $USER\nMessage: Adding the script ./job.sh as a cron job\nExit status: 0\n\n" >> $LOG_DIR/debug.log
} # //end function create_cronjob

create_cronjob					# We call this function to add this script as a cronjob on crontab
exit 0
