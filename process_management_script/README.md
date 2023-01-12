
# Shell Scripting - Test

This project is a base test to check your shells scripting capabilities.

## Table of content

-  Process management script
    - Overview
    - Requirements
    - How it works (Documentation)
        - Global variables
        - Functions
        - Explanation
- Issues found
- Helpful Links

## Process management script

### Overview

One of our systems has a service that exits randomly. We know this is a common issues but the maintainers of the service stated they won't resolve this issue any time soon since it is only affecting some users (edge case) and workarounds can be implemented outside the source code of the service. Thus, we shall implement a workaround for us.

### Requirements

The DevOps manager has requested you to design a script that will check if the process is up and perform some tasks if it's not. The specific requirements are:
- Exists automatically if an error is found.
- The script should be place as a cronjob for the root user.
- The script should log whether the service is up, down, or started if it was down.
- The log file path should be configured using a variable.
- Log useful comments and data at each step.
- The target service should be configured using a variable (so if we cant to change the targe process, we can do it by simply changing the name of the variable).

### How it works (Documentation)

The main goal of this script is to "monitoring" the status of a selected process/service and store useful information to a log file. This script should be configure as a cronjob in order to continuous "monitoring" the service. The script should also tell if the service is up, down or restarted.

To run this script you have to give it executable permissions first. You can do that by running this command in a terminal:
```sh
$ chmod +x ./process_management_script.sh
$ ./process_management_script.sh
```
Script variables and functions are explained below:

#### Global variables

| Variable | Description |
| -------- | ----------- |
| SCRIPT_NAME | It is used to for specify the script name when adding the cron job |
| USER | Store the name of the user running the script in the log file |
| FULL_PATH | Get the full directory path where the script is being executed |
| DATE | Store the date for log file name. Ex: log-2022-09-30 |
| LOG_DIR | Contains the directory path where log files are stored. It can be change in order to place log files in other directory |
| TARGET_SERVICE | This var is used to select the service we want to monitoring. We simply specified the service name by changing the content of this variable |

#### Functions

| Function | Description |
| --------- | ----------- |
| check_if_service_exists | Function to validate if the selected service is enabled or installed in the workstation |
| check_if_service_is_running | This function checks if the selected service is running or stopped |
| create_logs_directory | Function to create the directory to store log files |
| validate_logs_directory | Function to validate if logs directory was created successfully |
| create_log_files | Funtion to create two log files. *debug.log* is for storing information about the script operation, any execution error can be found here. *log-date* is used to store information about the target service |
| validate_log_file | Function to validate if log file were created successfully  |
| logging | Function to store information in *log-date* file |
| create_cronjob | Function to add this script as a cronjob on crontab |

### Explanation

Let's see a working example of how this script works. We suppose the user wants to monitor the status of the HTTPD service:
1. User edits variable `$TARGET_SERVICE` and type the service name **httpd.service**. Save the changes.
    ```sh
    $TARGET_SERVICE="httpd.service"
    ```
2. User runs the script:
    ```sh
    $ ./process_management_script.sh
    ```
3. Script will create *LOG_DIR* directory using **create_logs_directory** function if it was not created yet and validate if it was created successfully using **validate_logs_directory** function. If there was an error, for example, permission errors, this function will terminate the script execution with an exit status 1 and will print an error in terminal.
4. If *LOG_DIR* is created correctly then the script will create *debug.log* file to save logs about the tasks that have been completed by the script itself, for example, when log files and directory are created. Logs are stored using this format:

    > Log created on: Wed Jan 11 06:39:32 PM AST 2023
    > Username: user name
    > Message: Command mkdir /home/username/scritps/logs executed successfully
    > Exit status: 0

5. It will also create *log-date* (log- and the date when file is created, e.g., _log-2023-11-01_) file that is going to store information about target service. Both files (*debug.log* and *log-date*) are created using **create_log_files** function and validated using **validate_log_files** function. If files could not be created due to permission denied error, this function will terminate the script execution with an exit status 1 and will print an error in terminal. Logs in this file are saved as follow:

    > Log generated on: Wed Jan 11 06:39:32 PM AST 2023
    > Username: user name
    > Service name: httpd.service
    > Active status: Active: inactive (dead)
    > Main Process ID:
    > Logs: Loaded: loaded (/usr/lig/systemd/system/httpd.service; disabled; preset: disabled)

6. Now the script will check if the target service exists (is enabled or installed) on actual the workstation using **check_if_service_exists** function, to do so, script will run this command:
    ```sh
    $ systemctl list-unit-files | grep -q httpd.service
    ```
    This command will return 0 if the selected service is installed or return 1 if it is not installed or enabled. if 1 is returned **check_if_service_exists** function it will stop script exectution with an exit status 1. In both cases, a log message will be printed in terminal indicating the service status and further information will be added to *debug.log* file.
    
7. If 0 is returned then the service is installed. Now script will check if service is running with the **check_if_service_is_running** function running the command:
    ```sh
    $ systemctl show -p SubState --value httpd.service
    ```
    This command will return `"running"` if the service is active/running or `"dead"` if it is disable/dead. In both cases further information will be added to *debug.log* file and it will call for **logging** function.
8. The script will use **logging** function to save information about the selected service status. It will use these local variables to get the information:
    ```sh
    local ACTIVE_STATUS=$(systemctl status httpd.service | grep "Active")
    local MAIN_PID=$(systemctl status httpd.service | grep "Main PID")
    local LOGS=$(systemctl status --no-pager -l httpd.service | grep "systemd")
    ```
    Then, the information obtained by these variables are printed on terminal and added to *log-date* file using the cronjob process.

9. It is time to add this script as a cronjob in current user crontab in order to "monitoring" the selected service. Script will call **create_cronjob** function and will create a cronjob that will run every 5 minutes with the following parameters:
    ```sh
    (crontab -l; echo "SHELL=/bin/bash") | awk '!x[$0]++' | crontab -
    (crontab -l; echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin") | awk '!x[$0]++' | crontab -
    (crontab -l; echo "# To monitor target service httpd.service") | crontab -
    (crontab -l; echo "*/5 * * * * path_of_the_script/script_name >> log_directory/log-date 2>&1") | awk '!x[$0]++' | crontab -
    ```
    Script will add variables *SHELL* and *PATH* to crontab. *SHELL* is the environment and must be defined. When the SHELL line is omitted, /bin/sh is the default shell. *PATH* will tell where the binaries that are executed in the script are. *awk '!x[$0]++'* this directive is used to remove all duplicates from the crontab without sorting it, this prevent to add a new repeated line everytime the script is added to the cronjob.
    
    Every change in the selected service status will be stored in *log-date* file every five minutes.
    
This is a complete explanation of how this script works.

## Issues found

I faced two initial issues. I was having trouble in how to get information about the selected service and how to know if the service was installed or not. I read many ways to get process information on Linux system (ps, pgrep, top, htop command) until I found *systemctl command* that has almost everything I need to acomplish the requirements.

The other trouble was the cronjob. I could not make to work because I was not configuring the output correctly:
```sh
(crontab -l; echo "*/5 * * * * path_of_the_script/script_name >> log_directory/log-date 2>&1") | awk '!x[$0]++' | crontab -
```
All information about the selected service was store directly to *log-date* file using echo, but none of this information was printed on terminal. Cronjob was not adding logs to the file because it has nothing to add as the output was never printed on terminal.

## Helpful links

[codefather.tech](https://codefather.tech/blog/exit-bash-script) - Exit a Bash Script: Exit 0 and Exit 1 Explained

[fedingo.com](https://fedingo.com/how-to-log-shell-script-output-to-file) - How to Log Shell Script Output to File

[cyberciti.biz](https://www.cyberciti.biz/faq/systemd-systemctl-view-status-of-a-service-on-linux) - How to view status of a service on Linux using systemctl

[redhat.com](https://www.redhat.com/sysadmin/systemd-commands) - 10 handy systemd commands: A reference

[redhat.com](https://www.redhat.com/sysadmin/error-handling-bash-scripting) - Error handling in Bash scripts

[baeldung.com](https://www.baeldung.com/linux/create-crontab-script) - How to Create a crontab Through a Script

[linuxhint.com](https://linuxhint.com/bash_append_line_to_file/) - How to append a line to a file in bash

[digitalocean.com](https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units) - How To Use Systemctl to Manage Systemd Services and Units

[2daygeek.com](https://www.2daygeek.com/linux-bash-script-auto-restart-services-when-down/) - Bash script to automatically start a services when it goes down on Linux

[tecmint.com](https://www.tecmint.com/echo-command-in-linux/) - 15 Practical Examples of ‘echo’ command in Linux
