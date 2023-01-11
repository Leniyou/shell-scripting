# Shell Scripting - Test
This project is a base test to check your shells scripting capabilities.

## Overview
This test will cover the most basic toolings we use in the CLI for UNIX-like based OS systems. The idea is to validate your understanding on shell scripting as well as your creativity to resolve common issues.
The test will have multiple independent requirements, each should be resolved by an independent shell script although you can share code between them, if possible.

## Tests

### Process management script
One of our systems has a service that exits randomly. We know this is a common issues but the maintainers of the service stated they won't resolve this issue any time soon since it is only affecting some users (edge case) and workarounds can be implemented outside the source code of the service. Thus, we shall implement a workaround for us.
The DevOps manager has requested you to design a script that will check if the process is up and perform some tasks if it's not. The specific requirements are:

- Exists automatically if an error is found.
- The script should be place as a cronjob for the root user.
- The script should log wether the service is up, down, or started if it was down.
- The log file path should be configured using a variable.
- Log useful comments and data at each step.
- The target service should be configured using a variable (so if we cant to change the targe process, we can do it by simply changing the name of the variable).


### Lookup script
We have a need that we want to cover when reading log files from various services. Sometimes, there is not easy way to look up for an specific error in a set of log files. This can slow down troubleshooting processes. The requirement would be to:

The script should read parameters.
- We should be able to decide if we are going to read a single file, multiple files or a directory and the file inside of it, recursively.
- We should be able to input what we want our script to search for, we should be able to add multiple search values.
- We should be able to decide if we want our script to print the results of its search in the terminal, or log them into a results.log file in the same path where the script is executed.


### Interactive file download script
Someone lazy wants a script to download files from HTTP URLs and do some stuff with the downloaded file.

- The script should read the HTTP URL parameter, and should only recieve 1 parameter. If it reads more than one the script should exit with a message.
- The script should prompt the user where the downloaded file should be stored.
- The script should prompt th euser what file name the downloaded file should have.
- The script should prompt the user wheter he wants to: read (if .txt), modify (if .txt) or execute (if .sh or .bash) the downloaded file.
- The script should primpt the user if we wants to dowanload a new file or exit the program.

## Evaluation criterias

- Extra mile
- Creativity
- Functionality
- Meets requirements
- Documentation
- Ease to use
- Readibility
- Maintenability
