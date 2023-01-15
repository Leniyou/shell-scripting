#!/bin/bash
#
### Lookup script ###
#
# We have a need that we want to cover when reading log files from various 
# services. Sometimes, there is not easy way to look up for a specific error in 
# a set of log files. This can slow down troubleshooting processes. The 
# requirement would be to:
#
# - The script should read parameters.
# - We should be able to decide if we are going to read a single file, multiple
# files or a directory and the file inside of it, recursively.
# - We should be able to input what we want our script to search for, we should 
# be able to add multiple search values.
# - We should be able to decide if we want our script to print the results of 
# its search in the terminal, or log them into a result.log file in the same
# path where the script is executed.

## Setting some vars ##
CURRENT_DIR=$(pwd)                    # Actual directory where the script is placed
DATE=$(date +'%F')			              # To add date to "results" file name. Ex: results-2022-01-12.log
RESULTS=()				                    # Array to save matches keyword found in files
KEYWORDS=()				                    # Array for storing words to search
NUMBER_OF_ROWS=""			                # Number of row found that matches keywords in file
SELECTED_DIR=""                       # Directory that has been selected by user and different from "current dir"
FULL_PATH=""                          # Var that includes full path and file name

## These variables are for letter formatting
ITALIC='\033[3m'                      # Italic
BOLD_RED='\033[1;31m'                 # Bold Red
RED='\033[0;31m'                      # Red
BOLD_GREEN='\033[1;32m'   		        # Bold Red
BOLD_WHITE='\033[1;37m'       		    # White
UNDERLINE_WHITE='\033[4;37m'       	  # Underline White
NO_FORMAT='\033[0m' 			            # No Color or format

## Printing some information on terminal
echo -e "\n ##### Lookup Script ##### \n"
echo -e "# This script is used for searching words on a single file,"
echo -e "# multiple files or an entire directory. Just type the words"
echo -e "# you want to search for and this script will do the rest.\n"
echo -e "You are here now: "
echo -e "${ITALIC}$CURRENT_DIR${NO_FORMAT}\n"

## Function to save the matches found in the files with the keywords to a RESULTS() array ##
save_to_array () {
  
  # Add date to the beginning of array, just for informative purpose
  RESULTS+=("Created on date: " "$(date)")

  RESULTS+=("${NUMBER_OF_ROWS} Row(s) found in ${FULL_PATH} that matches keyword '${KEY}': ")
  RESULTS+=("$(grep -i "${KEY}" "${FULL_PATH}")")
  RESULTS+=("-------")
  RESULTS+=("")

}

### Function to search for keywords in a single file ###
search_in_file () {

  # Var that includes full path and file name
  FULL_PATH="${SELECTED_DIR}"/"${FILE}"
  
  ## Keywords to search are received through KEYWORDS() array
  for KEY in "${KEYWORDS[@]}";
  do

    ## To search for words (case insensitive) that matches "keyword" in selected file
    if grep -i "${KEY}" "${FULL_PATH}";	
    then
      
      # If there are any matches found
      # To count number of row found in file
      NUMBER_OF_ROWS=$(grep -ic "${KEY}" "${FULL_PATH}")
      
      # To save the matches found in file with the keywords to a RESULTS() array
      save_to_array "${NUMBER_OF_ROWS}" "${FULL_PATH}" "${KEY}"
    else
      
      # If there are no matches found
      echo -e "\nNo matches keywords $RED'${KEY}'$NO_FORMAT found in file ${FULL_PATH}"

      # To add info to RESULT() array
      RESULTS+=("Created on date: " "$(date)")
      RESULTS+=("No matches keywords $RED'${KEY}'$NO_FORMAT found in file ${FULL_PATH}")
      RESULTS+=("-------")
      RESULTS+=("")
    fi # //end if

  done # //end for KEY
  
}

### Function to search for keywords in multiple files ###
search_in_files () {

  ## A list of files is received through FILES() array
  for FILE in "${FILES[@]}";
  do
  
    # Var that includes full path and file name
    FULL_PATH="${SELECTED_DIR}"/"${FILE}"

    ## Keywords to search are received through KEYWORDS() array
    for KEY in "${KEYWORDS[@]}";
    do

      ## To search for words (case insensitive) that matches "keyword" in selected file
      if grep -i "${KEY}" "${FULL_PATH}";
      then
        
        # If there are any matches found
        # To count number of row found in file
        NUMBER_OF_ROWS=$(grep -ic "${KEY}" "${FULL_PATH}")

        # To save the matches found in file with the keywords to a RESULTS() array
        save_to_array "${NUMBER_OF_ROWS}" "${FULL_PATH}" "${KEY}"
      else

        # If there are no matches found
        echo -e "\nNo matches keywords $RED'${KEY}'$NO_FORMAT found in file ${FULL_PATH}"

        # To add info to RESULTS() array
        RESULTS+=("Created on date: " "$(date)")
        RESULTS+=("No matches keywords $RED'${KEY}'$NO_FORMAT found in file ${FULL_PATH}")
        RESULTS+=("-------")
        RESULTS+=("")
      fi # //end if

    done # //end for KEY

  done # //end for FILE
  
}

### Function to search for keywords in every directory file recursively ###
search_in_directory () {	
  
  # To search for files recursively in selected directory
  # Files found will be save to FILES_IN_DIR()
  local FILES_IN_DIR=()

  ## IFS= read -r -d $'\0' will include file names with whitespaces
  while IFS= read -r -d $'\0'; 
  do
    FILES_IN_DIR+=("$REPLY")
  done < <(find "${SELECTED_DIR}" -not -path '*/\.*' -type f ! \( -iname "*.jpg" -or -iname "*.jpeg" -or -iname "*.png" -or -iname "*.zip" -or -iname "*.tar.gz" \) -print0)
  
  ## A list of files found recursevily in FILES_IN_DIR() array
  for FILE in "${FILES_IN_DIR[@]}";
  do

    ## Keywords to search are received through KEYWORDS() array
    for KEY in "${KEYWORDS[@]}";
    do

      ## To search for words (case insensitive) that matches "keyword" in selected file
      if grep -i "${KEY}" "${FILE}";
      then

        # If there are any matches found
        # To count number of row found in file
        NUMBER_OF_ROWS=$(grep -ic "${KEY}" "${FILE}")
        
        # To add info to RESULTS() array
        RESULTS+=("Created on date: " "$(date)")			# Add date to the beginning of array, just for informative purpose
        RESULTS+=("${NUMBER_OF_ROWS} Row(s) found in ${FILE} that matches keyword '${KEY}': ")
        RESULTS+=("$(grep --color=always -i "${KEY}" "${FILE}")")
        RESULTS+=("-------")
        RESULTS+=("")
      else
        
        # If there are no matches found
        echo -e "\nNo matches keywords $RED'${KEY}'$NO_FORMAT found in file ${FILE}"

        # To add info to array RESULTS
        RESULTS+=("Created on date: " "$(date)")
        RESULTS+=("No matches keywords $RED'${KEY}'$NO_FORMAT found in file ${FILE}")
        RESULTS+=("-------")
        RESULTS+=("")
      fi # //end if

    done # //end for KEY

  done # //end for FILE

}

### Function to validate if user has READ permissions in selected directory ###
validate_read_permissions () {
  
  ## First, let's see if it is a valid directory
  if [[ -d ${SELECTED_DIR} ]];
  then
   
    # If it is a valid directory

    ## Second, let's check if user has READING permissions
    if ! [[ -r ${SELECTED_DIR} ]];
    then
      
      # If user has NO READING permissions
      echo -e "\n${BOLD_RED}ERROR:${NO_FORMAT}"
      echo -e "You don't have ${RED}READ permissions${NO_FORMAT} in this directory ${ITALIC}$SELECTED_DIR${NO_FORMAT}"
      echo -e "You could try running this script using root permissions like: \n"
      echo -e "sudo ./main_script.sh \n"

    else
      # If user has permission, function exits with status 1
      return 1
    fi

  else

    # If it is not a valid directory, an error will be printed in terminal
    echo -e "${ITALIC}$SELECTED_DIR${NO_FORMAT} is ${RED}not a directory${NO_FORMAT}\n"
  fi

}

### Function to validate if file exists ###
validate_if_file_exists () {
  
  # Var to count array iteration
  local COUNT
  
  ## A list of files is received through FILES() array
  for FILENAME in "${FILES[@]}";
  do
    # Var that includes full path and file name
    FULL_PATH="${SELECTED_DIR}"/"${FILENAME}"

    ## Every file is tested to see if it present in directory
    if ! [[ -e "${FULL_PATH}" ]];
    then

      # If file doesn't exist in directory, an error will be printed in terminal
      echo -e "\n${BOLD_RED}ERROR:${NO_FORMAT}"
      echo -e "\nThe file name ${RED}${FILENAME}${NO_FORMAT} you just typed does not exist in this directory."
      echo -e "Please double check the file name and remember to include its"
      echo -e "extension, for example: ${ITALIC}log.txt${NO_FORMAT}"
    else

      # File exists in directory
      # We add 1 iteration to COUNT var
      COUNT=$((COUNT+1))

      ## If COUNT var is equal to array number of elements
      if [[ "${COUNT}" -eq ${#FILES[@]} ]];
      then

        # Function exits with status 1
        return 1
      fi

    fi # //end if exists in directory

  done # //end for
  
  # To list files on selected directory
  echo -e "\nThis is a list of files within this directory:\n"
  ls -l "${SELECTED_DIR}"	
}

## To stay on current directory (the directory where the script is placed) 
## or to choose another one (the directory where the script will be executed)
## while to select directory
while true;
do
  read -rp "Do you want to use this directory or select another one? type [Y] / [N]: " DIRECTORY
  case "$DIRECTORY" 
  in
    [YyYESYesyes] )

      # The selected directory will be the same where the script is being executed
      SELECTED_DIR=${CURRENT_DIR}	
      
      # To validate if current user has read permission on selected directory
      validate_read_permissions "${SELECTED_DIR}"
      
      break
      ;;

    [NnNONono] )
      
      # This while loop is to validate that user has READ permissions in selected new directory
      # Loop will go on until user select a valid directory
      while true;			 
      do				
        read -rp "Please type the full directory path you want to use instead: " DIR
        SELECTED_DIR=$DIR

        # If user has READ permission then this loop will break
        validate_read_permissions "${SELECTED_DIR}" || break
      done # //end while

      break
      ;;

    * ) 
      echo "Please type [${UNDERLINE_WHITE}Y${NO_FORMAT}] for 'YES' or [${UNDERLINE_WHITE}N${NO_FORMAT}] for 'NO': "
      ;;
  esac
done # //end while to select directory

## We should be able to decide if we are going to read:
## - a single file, 
## - multiple files 
## - a directory and the file inside of it, recursively.
## while to select files
while true;				
do
  echo -e "\nSelected directory:"
  echo -e "${ITALIC} $SELECTED_DIR ${NO_FORMAT}\n"	
  
  echo -e "Please type [${UNDERLINE_WHITE}1${NO_FORMAT}] to search for keywords in a ${BOLD_WHITE}single file:${NO_FORMAT}"
  echo -e "Please type [${UNDERLINE_WHITE}2${NO_FORMAT}] to search for keywords in ${BOLD_WHITE}multiple files:${NO_FORMAT}"
  echo -e "Please type [${UNDERLINE_WHITE}3${NO_FORMAT}] to search for keywords in all files in this ${BOLD_WHITE}directory:${NO_FORMAT}" 
  read -rp "Your answer: " ANSWER
  case "$ANSWER"
  in
    ## To search for keywords in a single file
    [1] )

      echo -e "\nShowing files in directory:"
      echo -e "${ITALIC}$SELECTED_DIR${NO_FORMAT}\n"
      ls -l "$SELECTED_DIR" # to list only regular files on directory
      
      while true;
      do
        echo -e "\nPlease type the full file name you want to search information"
    	  echo -e "from, that includes its extension, for example: ${ITALIC}log.txt${NO_FORMAT}"
    	  read -rp "Full file name: " FILE
    	  
        # To validate if file exists
    	  if ! [[ -e "$SELECTED_DIR"/"${FILE}" ]];
    	  then
    	    echo -e "\n${BOLD_RED}ERROR:${NO_FORMAT}"
    	    echo -e "\nThe file name ${RED}${FILE}${NO_FORMAT} you just typed does not exist in this directory."
    	    echo -e "Please double check the file name and remember to include its"
    	    echo -e "extension, for example: ${ITALIC}log.txt${NO_FORMAT}"
    	    echo -e "\nThis is a list of files within this directory:\n"
     	    ls -l "$SELECTED_DIR"	# to list only regular files on directory
    	  else
    	    break			# If file exists then when we break the while loop
    	  fi

      done # //end while loop
      
      ## Now we ask the user for the words he wants to search ##
      echo -e "\nPlease type the word(s) you want to search for within"
      echo -e "the file $SELECTED_DIR/${FILE}"
      read -r -a KEYWORDS -p "Word(s) to search: "
      search_in_file "${FILE}" "${KEYWORDS[@]}"
      
      break # break while and go to next while loop
      ;;
    
    ## To search for keywords in multiple files

    [2] )				# To read info from multiple files
      
      echo -e "\nThis directory:"
      echo -e "${ITALIC}$SELECTED_DIR${NO_FORMAT}"
      echo -e "contains the following files:\n"
      ls -l "$SELECTED_DIR"	# to list only regular files on directory
      
      while true;
      do
        echo -e "\nPlease type the full file names you want to read information"
    	  echo -e "from, that includes its extension, for example:${ITALIC} log.txt debug.txt ${NO_FORMAT}"
    	  read -ra FILES -p "Full file names: "
    	
    	  ## To validate if all file exists
    	  validate_if_file_exists "${SELECTED_DIR}" "${FILES[@]}" || break

      done # //end while that asks for file names
      
      ## Now we ask the user for the words he wants to search ##
      echo -e "\nPlease type the word(s) you want to search for within"
      echo -e "the files in $SELECTED_DIR"
      read -ra KEYWORDS -p "Word(s) to search: "
      search_in_files "${FILES[@]}" "${KEYWORDS[@]}"

      break # break while and go to next while loop
      ;;

    [3] )			# To read info from a directory recursively
      
      echo -e "\nYou are in this directory:"
      echo -e "${ITALIC}$SELECTED_DIR${NO_FORMAT}"      
      echo -e "\nPlease type the word(s) you want to search for"
      echo -e "recursively in $SELECTED_DIR/${FILE} "
      read -ra KEYWORDS -p "Word(s) to search: "
      search_in_directory "${KEYWORDS[@]}"
      
      break # break while and go to next while loop
      ;;

    * )

      echo "Please type select an option [1] [2] or [3]"
      ;;
  esac

done 

## We give the user the option to print results or save them to a file
## in the directory where this script is placed.
## while to print o save to a file
while true;				
do
  echo -e "\nDo you want to print results on terminal or save them to a log file?"
  read -rp "Type [P] to print on terminal or [S] to save in a log file: " CHOOSE
  case "$CHOOSE"
  in
    # To Print results on terminal
    [Pp] )

      echo -e "\nShowing results in terminal \n"
      
      ## Loop for printing results on terminal 
      ## printing RESULTS array
      for r in "${RESULTS[@]}";
      do
        echo -e "${r}"
      done
      
      break
      ;;
    
    # To save results in result.log file
    [Ss] )		
      
      #To create result.log file
      touch "$CURRENT_DIR"/result-"$DATE".log
      echo -e "\n Log file $CURRENT_DIR/${BOLD_GREEN}result-$DATE.log${NO_FORMAT} created\n"

      for r in "${RESULTS[@]}"
      do
        echo "${r}" >> "$CURRENT_DIR"/result-"$DATE".log
      done
      
      break
      ;;

    * )
    echo -e "\nType [P] to print result on terminal or [S] to save in a log file"
    
    ;;
  esac
done # //end while to print o save to a file
echo "Exiting... Thank you!"
exit 0
