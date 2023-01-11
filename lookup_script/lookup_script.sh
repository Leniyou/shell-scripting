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

# 1 - pedirle al usuario que seleccione un directory
# 2 - hacer ls para presentar todos los archivos en el directorio seleccionado
# 3 - pedirle al usuario que especifique el o los nombres de los archivos que 
# quiere leer o la carpeta
# 4 - pedirle los parametros de busqueda
# 5 - want to print results or save them on file result.log

## Setting some vars ##
CURRENT_DIR=$(pwd)			# Active directory for running script
DATE=`date +'%F'`			# Variable DATE for results file name. Ex: result-2022-09-30.log

## Those variables are for letter formatting
ITALIC='\033[3m'			# Italic
BOLD_RED='\033[1;31m'   		# Bold Red
RED='\033[0;31m'			# Red
BOLD_GREEN='\033[1;32m'   		# Bold Red
GREEN='\[033[0;32m\]'			# Green
BOLD_WHITE='\033[1;37m'       		# White
UNDERLINE_WHITE='\033[4;37m'       	# Underline White
NO_FORMAT='\033[0m' 			# No Color or format

echo -e "\n ##### Lookup Script ##### \n"
echo -e "# This script is used for searching words on a single file,"
echo -e "# multiple files or an entire directory. Just type the words"
echo -e "# you want to search for and this script will do the rest.\n"
echo -e "You are here now: "
echo -e "${ITALIC}$CURRENT_DIR${NO_FORMAT}\n"

## Function for search words in a single file ##
search_in_file () {
  local FILE=$1
  local WORDS=("${WORDS_TO_SEARCH[@]}")	# we receive the parameters from array 
  touch $ACTIVE_DIR/result.tmp		# Creating a temporal file
  echo -e "\n$(date)" >> $ACTIVE_DIR/result.tmp
   
  for w in "${WORDS[@]}";
  do
    local STATUS=$(grep "${w}" $ACTIVE_DIR/${FILE} -q)
    if [[ $STATUS -eq 0 ]]
    then
      echo -e "\nRow(s) in ${ACTIVE_DIR}/${FILE} file that matches search criteria: '${w}'" >> $ACTIVE_DIR/result.tmp
      cat $ACTIVE_DIR/${FILE} | grep -i "${w}" >> $ACTIVE_DIR/result.tmp	# Save the found results
    else
      echo -e "No matches search criteria for words '${w}'\n" >> $ACTIVE_DIR/result.tmp
    fi
  done # //end for
}

## Function for searching words in multiple files ##
search_in_files () {
  local FILES=("${FILES[@]}")	
  local WORDS=("${WORDS_TO_SEARCH[@]}")	# we receive the parameters from array 
  touch $ACTIVE_DIR/result.tmp		# Creating a temporal file
  echo -e "\n$(date)" >> $ACTIVE_DIR/result.tmp
  
  for f in "${FILES[@]}";
  do
    for w in "${WORDS[@]}";
    do
      local STATUS=$(grep "${w}" $ACTIVE_DIR/${f} -q)
      if [[ $STATUS -eq 0 ]]
      then
        echo -e "\nRow(s) in ${ACTIVE_DIR}/${f} file that matches search criteria: '${w}'" >> $ACTIVE_DIR/result.tmp
        cat $ACTIVE_DIR/${f} | grep -i "${w}" >> $ACTIVE_DIR/result.tmp	# Save the found results
      else
        echo -e "No matches search criteria for words '${w}'\n" >> $ACTIVE_DIR/result.tmp
      fi
    done # //end for words
  done # //end for files
}

## Function for searching words inside directory ##
search_in_directory () {	
  local WORDS=("${WORDS_TO_SEARCH[@]}")	# we receive the parameters from array 
  touch $ACTIVE_DIR/result.tmp		# Creating a temporal file
  echo -e "\n$(date)" >> $ACTIVE_DIR/result.tmp
 
  ## to list all files in active directory ##
  for f in $ACTIVE_DIR/*
  do
    for w in "${WORDS[@]}";
    do
      if ! [[ -d ${f} ]]
      then
        if ! [[ ${f} == "$ACTIVE_DIR/result.tmp" ]]
        then
          echo "echo ${f}"
          local STATUS=$(grep -i "${w}" ${f} -q)
          if [[ $STATUS -eq 0 ]]
          then
            echo -e "\nRow(s) in ${f} file that matches search criteria: '${w}'" >> $ACTIVE_DIR/result.tmp
            cat ${f} | grep -i "${w}" >> $ACTIVE_DIR/result.tmp	# Save the found results
          else
            echo -e "No matches search criteria for words '${w}'\n" >> $ACTIVE_DIR/result.tmp
          fi # //end if STATUS
        fi  
      fi # //end if result.tmp
    done # //end for WORDS
  done # //end for FILE

}
## Function for validating READ permissions
validate_read_permissions () {
  if [[ -d ${ACTIVE_DIR} ]]		# Now we want to be sure if it is a directory
  then
    if ! [[ -r ${ACTIVE_DIR} ]]		# We check if current user has READING permissions
    then				# in the active directory
      echo -e "\n${BOLD_RED}ERROR:${NO_FORMAT}"
      echo -e "You don't have ${RED}READ permissions${NO_FORMAT} in this directory ${ITALIC}$ACTIVE_DIR${NO_FORMAT} "
      echo -e "You could try running this script using root permissions like: \n"
      echo -e "sudo ./main_script.sh \n"
    else
      return 1
    fi
  else
    echo -e "${ITALIC}$ACTIVE_DIR${NO_FORMAT} is ${RED}not a directory${NO_FORMAT}\n"
  fi
}

## Function for validating if file exists
validate_if_file_exists () {
  local NAME_OF_FILES=("${FILES[@]}")	# we receive the parameters from array
  local COUNTER
  
  for f in "${NAME_OF_FILES[@]}";
  do
   if ! [[ -e $ACTIVE_DIR/${f} ]]
   then
     echo -e "\n${BOLD_RED}ERROR:${NO_FORMAT}"
     echo -e "\nThe file name ${RED}${f}${NO_FORMAT} you just typed does not exist in this directory."
     echo -e "Please double check the file name and remember to include its"
     echo -e "extension, for example: ${ITALIC}log.txt${NO_FORMAT}"
   else
     COUNTER=$COUNTER+1
     if [[ ${COUNTER} -eq ${#NAME_OF_FILES[@]} ]]
     then
       return 1
     fi
   fi
  done
  
  echo -e "\nThis is a list of files within this directory:\n"
  ls -l $ACTIVE_DIR | grep '^-'	# to list only regular files on directory
}

## To stay on current directory or to choose another one ##
while true;				# We give the user the option to select active directory
do					# the directory where this script is placed.
  read -p "Do you want to use this directory or select another one? type [Y]/[N]: " DIRECTORY
  case "$DIRECTORY" 
  in
    [YyYESYesyes]* )			# To match all coincidences of YES
      ACTIVE_DIR=$CURRENT_DIR		# If choosing the active directory to run the script
      validate_read_permissions ${ACTIVE_DIR}
      
      break
      ;;
    [NnNONono]* )			# To match all coincidences of NO
      while true;			# This while loop is for validating new directory READ permissions 
      do				# Until user select a valid directory
        read -p "Please type the full directory path you want to use instead: " DIR
        ACTIVE_DIR=$DIR			# If choosing another directory to run the script
        validate_read_permissions ${ACTIVE_DIR} || break
      done # //end while
      break
      ;;
    * ) 
      echo "Please type Y for 'YES' or N for 'NO'"
      ;;
  esac
done # //end while that asks for working directory

# - We should be able to decide if we are going to read a single file, multiple
# files or a directory and the file inside of it, recursively.
while true;				
do					
  echo -e "\nYou can search information from a file,"
  echo -e "multiple files or a directory"
  echo -e "recursively within this directory:"
  echo -e "${ITALIC} $ACTIVE_DIR ${NO_FORMAT}\n"
  echo -e "Please type [${UNDERLINE_WHITE}1${NO_FORMAT}] for a ${BOLD_WHITE}single file:${NO_FORMAT}"
  echo -e "Please type [${UNDERLINE_WHITE}2${NO_FORMAT}] for ${BOLD_WHITE}multiple files:${NO_FORMAT}"
  echo -e "Please type [${UNDERLINE_WHITE}3${NO_FORMAT}] for a ${BOLD_WHITE}directory:${NO_FORMAT}" 
  read -p "Your answer: " ANSWER
  case "$ANSWER" 
  in
    [1] )				# To read info from a single file
      echo -e "\nThis directory:"
      echo -e "${ITALIC}$ACTIVE_DIR${NO_FORMAT}"
      echo -e "contains the following files:\n"
      ls -l $ACTIVE_DIR | grep '^-'	# to list only regular files on directory
      
      while true;
      do
        echo -e "\nPlease type the full file name you want to search information"
    	echo -e "from, that includes its extension, for example: ${ITALIC}log.txt${NO_FORMAT}"
    	read -p "Full file name: " FILE
    	    
    	if ! [[ -e $ACTIVE_DIR/${FILE} ]]		# To validate if file exists
    	then
    	  echo -e "\n${BOLD_RED}ERROR:${NO_FORMAT}"
    	  echo -e "\nThe file name ${RED}${FILE}${NO_FORMAT} you just typed does not exist in this directory."
    	  echo -e "Please double check the file name and remember to include its"
    	  echo -e "extension, for example: ${ITALIC}log.txt${NO_FORMAT}"
    	  echo -e "\nThis is a list of files within this directory:\n"
     	  ls -l $ACTIVE_DIR | grep '^-'	# to list only regular files on directory
    	else			
    	  break			# If file exists then when we break the while loop
    	fi
      done
      
      ## Now we ask the user for the words he wants to search ##
      echo -e "\nPlease type the word(s) you want to search for within"
      echo -e "the file $ACTIVE_DIR/${FILE}"
      read -a WORDS_TO_SEARCH -p "Word(s) to search: "
      search_in_file ${FILE} ${WORDS_TO_SEARCH[@]}
      
      break # break while and go to next while loop
      ;;
    [2] )				# To read info from multiple files
      echo -e "\nThis directory:"
      echo -e "${ITALIC}$ACTIVE_DIR${NO_FORMAT}"
      echo -e "contains the following files:\n"
      ls -l $ACTIVE_DIR | grep '^-'	# to list only regular files on directory
      
      while true;
      do
        echo -e "\nPlease type the full file names you want to read information"
    	echo -e "from, that includes its extension, for example:${ITALIC} log.txt debug.txt ${NO_FORMAT}"
    	read -a FILES -p "Full file names: "
    	
    	## to validate if all file exists
    	validate_if_file_exists ${ACTIVE_DIR} ${FILES[@]} || break
      
      done # //end while that asks for file names
      
      ## Now we ask the user for the words he wants to search ##
      echo -e "\nPlease type the word(s) you want to search for within"
      echo -e "the files $ACTIVE_DIR/${FILE} "
      read -a WORDS_TO_SEARCH -p "Word(s) to search: "
      search_in_files ${FILES[@]} ${WORDS_TO_SEARCH[@]}

      break # break while and go to next while loop
      ;;
    [3] )			# To read info from a directory recursively
      echo -e "\nYou are in this directory:"
      echo -e "${ITALIC}$ACTIVE_DIR${NO_FORMAT}"      
      echo -e "\nPlease type the word(s) you want to search for"
      echo -e "recursively in $ACTIVE_DIR/${FILE} "
      read -a WORDS_TO_SEARCH -p "Word(s) to search: "
      search_in_directory ${WORDS_TO_SEARCH[@]}
      
      break # break while and go to next while loop
      ;;
    * ) 
      echo "Please type select an option [1] [2] or [3]"
      ;;
  esac
done # //end while that asks for files

# We give the user the option to print results or save them to a file
# the directory where this script is placed.
while true;				
do
  echo -e "\nDo you want to print results on terminal using cat command or save them to a log file?"
  read -p "Type [C] to cat/print on terminal or [S] to save in a log file: " CHOOSE
  case "$CHOOSE"
  in
    [CcCAT]* )		# Printing results on terminal
      echo -e "\nShowing results in terminal \n"
      cat $ACTIVE_DIR/result.tmp
      rm $ACTIVE_DIR/result.tmp
      
      break
      ;;
    [SsSAVE]* )		# Save results to a file
      touch $CURRENT_DIR/result-$DATE.log
      echo -e "\n Log file $CURRENT_DIR/${BOLD_GREEN}result-$DATE.log${NO_FORMAT} created\n"
      cat $ACTIVE_DIR/result.tmp >> $CURRENT_DIR/result-$DATE.log
      rm $ACTIVE_DIR/result.tmp
      
      break
      ;;
    * )
    echo -e "\nType [C] to cat/print on terminal or [S] to save in a log file"
    
    ;;
  esac
done # //end while that asks for printing or saving file
echo -e "\nExiting... Thank you! :D"
exit 0
