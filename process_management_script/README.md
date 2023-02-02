# Shell Scripting - Test 1

This project is a base test to check your shells scripting capabilities.

## Table of content

- Process management script
  - Overview
  - Requirements
  - How it works (Documentation)
    - Variables
    - Files
    - Explanation
- Issues found
- Helpful links

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

The main goal of this script is to "monitoring" the status of a selected process/service and store useful information into a log file. This script should be configure as a cronjob in order to continuous "monitoring" the service. The script should also tell if the service is up, down or restarted.

To run this script you have to give it executable permissions first. You can do that by running this command in a terminal:

```sh
chmod +x ./process_management_script.sh
./process_management_script.sh
```

#### Variables

| Variable | Content |Description |
| -------- | -------- | ----------- |
| SCRIPT_NAME | `$(basename "$0")` | It is used to specify the script name when adding it to the cron job |
| USER | `$(whoami)` | Store the name of the user running the script in the log file |
| FULL_PATH | `$(pwd)` | Get the full directory path where the script is being executed |
| LOG_DIR | `"${FULL_PATH}/logs"` | Contains the directory path where log files are stored. It can be change in order to place log files in other directory |
| TARGET_SERVICE | `"httpd.service"` | This var is used to select the service we want to monitoring. We simply specified the service name by changing the content of this variable |
| SERVICE_LOG_FILE | `"${TARGET_SERVICE}-$(date +'%F').log"` | Variable for service log filename. e.g.: If the httpd.service is selected as the target service then the filename will be somethig like: `httpd.service-2022-09-30.log`. We add *$(date)* to the filename in order to make easier filtering logs. |
| ACTIVE_STATUS | `$(systemctl status "${TARGET_SERVICE}"| grep "Active")` | To get the current status (running or stopped) of the selected target service |
| MAIN_PID | `$(systemctl status "${TARGET_SERVICE}" | grep "Main PID")` | To get the main process ID of the selected target service |
| LOGS | `$(systemctl status --no-pager -l "${TARGET_SERVICE}" | grep "systemd")` | To get logs from the selected target service |

#### Files

| File | Description |
| ---- | ----------- |
| debug.log | This file is used to store log information about the tasks that have been ran by the script itself, for example, when log files and directory are created. This file is in *LOG_DIR* directory |
| *service_name-date.log* | This file is used to store information about selected target service. This file is in *LOG_DIR* directory |

#### Explanation

Let's see a working example of how this script works. We suppose the user wants to monitor the status of the HTTPD service:

1. User edits variable `$TARGET_SERVICE` and type the service name **httpd.service**. Save the changes.

    ```sh
    TARGET_SERVICE="httpd.service"
    ```

2. Then, user runs the script:

    ```sh
    ./process_management_script.sh
    ```

3. Script will create *LOG_DIR* directory.

    ```sh
    ## To create log directory and debug.log file ##
    # -p option is to override it is already created
    mkdir -p "${LOG_DIR}" && touch "${LOG_DIR}/debug.log"
    if [[ -d "${LOG_DIR}" ]];
    then
      ...
    else
      ...
    fi
    ```

4. If log directory is created without any errors, then *debug.log* file will be created in order to start logging usefull information about the tasks ran by the script. If there is any error while creating the log directory, perphaps permission denied errors, it will be printed on terminal and script will exit with code 1.

5. Script will create *service_name-date.log* file. If there is any error while creating the log service file, further information can be found in debug.log file. In this case the name of the file will be something like: `httpd.service-2023-02-01.log` as it takes the same name of selected target service. If there is any error while creating this file it will be printed on terminal and script will exit with code 1.

    ```sh
    ## Then, script will create httpd.service-2022-09-30.log file ##
    # for logging information about selected target service
    if touch "${SERVICE_LOG_FILE}";
    then
      ...
    else
      ...
    fi
    ```

6. Now it's time to check if the selected target service exists, I mean, if it is installed or enabled, in the workstation running the script. In order to do that we run this command:

    ```sh
    systemctl list-unit-files | grep -q "${TARGET_SERVICE}"
    ```

    If the command above returns 1, it means that the service is not installed/enabled in the workstation or could be typing error, e.g. you could have typed *http* instead of *http**d***, the script will suggest the user to run `systemctl --all --type service` to get a full list of installed services. Further information about this error could be found in *debug.log* file. Script will exit with code 1.

7. If selected target service is installed on the machine, then script will check if it is running or stopped:

    ```sh
    systemctl show -p SubState --value "${TARGET_SERVICE}"
    ```

    This command will return `"running"` if the service is active/running or `"dead"` if it is disable/dead. In both cases further information will be added to *debug.log* file.

8. Now the script will start getting logs from vars *ACTIVE_STATUS*, *MAIN_PID* and *LOGS* it will print those logs on terminal and add them to **service_name-date.log** service log file.

    ```sh
    # Logs for logging saved in service log file
    # Logging information about the selected service
    printf "\nDate: %s\n" "$(date)"
    printf "Username: %s\n" "${USER}"
    printf "Service name: %s\n" "${TARGET_SERVICE}"
    printf "Active status: %s\n" "${ACTIVE_STATUS}"
    printf "Main Process ID: %s\n" "${MAIN_PID}"
    printf "Logs:\n"
    printf "%s\n" "${LOGS}"
    ```

9. The last step is to add this script to user crontab file. The script will be set to run every 5 minutes:

    ```sh
    ## To add this script as a cronjob on crontab ##
    # awk '!x[$0]++' parameter removes duplicate lines from text input without pre-sorting,
    # everytime the script is added to crontab, it will be added as a new line, this parameter avoid to duplicate that entry in the cronjob file.
    
    # Add SHELL to crontab
    (crontab -l; echo "SHELL=/bin/bash") | awk '!x[$0]++' | crontab -
    
    # Add PATH to crontab
    (crontab -l; echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin") | awk '!x[$0]++' | crontab -
    
    # Add this script to crontab to run every 5 minutes
    (crontab -l; echo "# To monitor target service ${TARGET_SERVICE}") | crontab -
    (crontab -l; echo "*/5 * * * * $FULL_PATH/$SCRIPT_NAME >> ${LOG_DIR}/${SERVICE_LOG_FILE} 2>&1") | awk '!x[$0]++' | crontab -
    ```

    The main part of this command is explained as follow:
    | Part | What it does |
    | ---- | ------------ |
    | `*/5 * * * *` | It is for specifing the time cronjob will call the script, in this case are just 5 minutes |
    | `$FULL_PATH/$SCRIPT_NAME` | It is the full path of the script, e.g. */dir/dir/dir/script.sh*|
    | `>> ${LOG_DIR}/${SERVICE_LOG_FILE} 2>&1` | Whatever output that is going to be printed on terminal by the script it will be redirect to the service log file **service_name-date.log** |
    | `awk '!x[$0]++'` | As the crontab will be calling this script every 5 minutes a new line will be added to the crontab file, getting duplicated entries. This parameter will avoid to add duplicated entries in the crontab file |

10. You just have to open your service log file **service_name-date.log** to get information about the selected target service.

## Issues found

I faced two initial issues. I was having trouble in how to get information about the selected service and how to know if the service was installed or not. I read many ways to get process information on Linux system (ps, pgrep, top, htop command) until I found *systemctl command* that has almost everything I need to acomplish the requirements.

The other trouble was the cronjob. I could not make to work because I was not configuring the output correctly:

```sh
(crontab -l; echo "*/5 * * * * full_path_of_the_script/script_name >> log_directory/service_name-date.log 2>&1") | awk '!x[$0]++' | crontab -
```

All information about the selected service was supposed to be store directly to **service_name-date.log** file using echo, but none of this information was printed on terminal. Then cronjob was not adding logs to the file because it has nothing to add as the output was never printed on terminal. The problem was the missing part `2>&1` to redirect the script output to service log file.

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
