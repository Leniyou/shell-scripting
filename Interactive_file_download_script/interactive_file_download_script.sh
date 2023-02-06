#!/bin/bash
#
# -- Interactive file download script -- #
# Someone lazy wants a script to download files from HTTP URLs and
# do some stuff with the downloaded file:
#
# -The script should read the HTTP URL parameter, and should only 
#  recieve 1 parameter. If it reads more than one the script should 
#  exit with a message.
# -The script should prompt the user where the downloaded file 
#  should be stored.
# -The script should prompt the user what file name the downloaded
#  file should have.
# -The script should prompt the user wheter he wants to: 
#  read (if .txt), modify (if .txt) or execute (if .sh or .bash) the 
#  downloaded file.
# -The script should prompt the user if we wants to download a new 
#  file or exit the program.
# --

# -- These variables are for letter formatting -- #
ITALIC='\033[3m'                      # Italic
BOLD_RED='\033[1;31m'                 # Bold Red
RED='\033[0;31m'                      # Red
GREEN='\033[0;32m'                    # Green
BOLD_GREEN='\033[1;32m'   		        # Bold Red
BOLD_WHITE='\033[1;37m'       		    # White
UNDERLINE_WHITE='\033[4;37m'       	  # Underline White
NO_FORMAT='\033[0m' 			            # No Color or format
# -- Array for allowed URL extensions file -- #
EXTENSIONS=(txt TXT sh SH bash BASH)
ERROR_LOG=""
RECOMM_LOG=""

#######################################
# Description:
#   Function to error catching
#   Redirects output to STDERR
# Globals:
#   None
# Locals:
#   ERROR
#   RECOMM
# Arguments:
#   Error message to be printed
#   A brief recommendation to avoid the error
# Outputs:
#   output will printed on terminal:
#   [2023-02-02 10:28:43]:
#   - message error -
#   - recommendation - 
#######################################
function err() {
  local ERROR="$1"

  local RECOMM="$2"
  echo -e "
    [$(date +'%F %H:%M:%S')]:
    Error: 
      ${ERROR}
    Recommendation:
      ${RECOMM}
    Exit status: 1
  " >&2 
}

#######################################
# Description:
#   Function to validate if DIR has 
#   slashes / or // at the end, with 
#   this we avoid something like:
#   /home/user/FILE_NAME
#   instead of
#   /home/userFILENAME
# Globals:
#   None
# Locals:
#   None
# Arguments:
#   Directory selected by user
# Outputs:
#   A valid directory with proper 
#   slash at the end
#######################################
function slash_on_dir() {
  # -- 
  # This is just to validate that DIR variable 
  # has the slash at the end / 
  # --
  if [[ "${DIR: -1}" != "/" ]];
  then
    # Add slash / to the end of DIR var
    DIR="${DIR}/"
  elif [[ "${DIR: -2}" == "//" ]];
  then
    # Remove double // from the end of DIR var
    DIR="${DIR::-1}"
  fi
  return 1
}

# -- 
# To ask the user to type HTTP URL where he wants 
# to download files from
# --
while true; do
  # -- 
  # User input is store in URL() array 
  # to know how many inputs have been typed 
  # --
  echo -e "\nType the URL where you want to download files from."
  read -r -a URL -p "Please make sure to type only 1 URL: "
  # -- 
  # The script should read the HTTP URL parameter, 
  # and should only recieve 1 parameter
  # --
  if [ "${#URL[@]}" -gt 1 ]; then
    ERROR_LOG="You have just typed ${BOLD_RED}more than 1 URL${NO_FORMAT}."
    RECOMM_LOG="Please make sure to type ${BOLD_GREEN}only 1 URL${NO_FORMAT}."
    # -- Printing errors using function err() -- #
    err "${ERROR_LOG}" "${RECOMM_LOG}"
    exit 1
  fi
  # -- 
  # To verify if URL is valid 
  # If 404 is returned then page doesn't exist
  # --
  if curl --head --silent "${URL[0]}" | head -n 1 | grep -q 404; then
    ERROR_LOG="The page you have typed ${BOLD_RED}returns 404 error${NO_FORMAT},"
    RECOMM_LOG="please make sure to correct any typing errors or type ${BOLD_GREEN}only 1 URL${NO_FORMAT}"
    # -- Printing errors using function err() -- #
    err "${ERROR_LOG}" "${RECOMM_LOG}"
    exit 1
  fi
  # -- 
  # This part of the script is to validate if given URL has a valid extension.
  # We use a for loop to compare every index in EXTENSION[@] array against
  # the last characters after the last dot of the typed URL with this "${URL[0]##*.}"
  # For example, is this url is typed: https://filesamples.com/samples/code/sh/sample3.sh
  # this var ${URL[0]##*.} will be equal to "sh"
  # --
  COUNT=0
  for EXT in "${EXTENSIONS[@]}"; do
    # --
    # If URL has a valid file extension then it will end for loop
    # and go to the next validation 
    # --
    if [[ "${URL[0]##*.}" == "${EXT}" ]]; then break
    else
      # -- 
      # With this counter, we make sure every index in EXTENSION[@] array is compared
      # if a valid extension file is not found in the typed URL an error will be throw
      # and script will end with exit status 1
      # --
      COUNT=$(( COUNT+1 ))
      if [[ $COUNT -eq ${#EXTENSIONS[@]} ]]; then
        ERROR_LOG="The page you have typed does not contain a valid extension file."
        RECOMM_LOG="
          For this script to work you should provide an URL ending with
          extensions: txt or sh, i.e. ${ITALIC}https://example.com/text.txt ${NO_FORMAT}
        "
        # -- Printing errors using function err() -- #
        err "${ERROR_LOG}" "${RECOMM_LOG}"
        exit 1
      fi
    fi
  done
  # -- 
  # The script should prompt the user where the 
  # downloaded file should be stored
  # --
  while true; do
    echo ""
    read -r -p "Type the full path where you want to store downloaded file: " DIR
    # -- 
    # Script will check if it is a valid directory and 
    # if user has READING permissions in it 
    # --
    if [[ -d ${DIR} ]] && [[ -r ${DIR} ]]; then          
      slash_on_dir "${DIR}" || break
    else
      ERROR_LOG="
        ${ITALIC}${DIR}${NO_FORMAT} is ${RED}not a valid directory${NO_FORMAT}
        Or you don't have ${RED}READ permissions${NO_FORMAT} in this directory.
      "
      RECOMM_LOG="You should specified a new directory"
      # -- Printing errors using function err() -- #
      err "${ERROR_LOG}" "${RECOMM_LOG}"
      # -- break this while loop if it is a valid directory and user has READ permissions -- #
      exit 1
    fi
  done
  echo -e "
    Your file name will be saved in:
    ${ITALIC}${DIR}${NO_FORMAT}
  "
  # --
  # The script should prompt the user what file name 
  # the downloaded file should have
  # --
  while true; do
    echo ""
    read -r -p "Type the name you want for downloaded file: " USER_FILENAME
    # -- To check if user type a valid file name -- #
    if ! [[ $USER_FILENAME =~ ^[a-zA-Z]+$ ]];
    then
      # -- Printing errors using function err() -- #
      ERROR_LOG="The file name ${ITALIC}${USER_FILENAME}${NO_FORMAT} you typed contains ${RED}invalid characters${NO_FORMAT}."
      RECOMM_LOG="Only a-z or A-Z characters are allowed"
      err "${ERROR_LOG}" "${RECOMM_LOG}"
    else 
      # -- break this while loop if it is a valid file name -- #
      break
    fi
  done
  echo -e "\nDownloading..."
  # -- To download the file -- #
  curl -O --output-dir "${DIR}" "${URL[0]}"
  # -- Downloaded file name variable -- #
  DONWLOADED_FILE_NAME=$(basename "${URL[0]}")
  # -- Downloaded file extension var -- #
  DOWNLOADED_FILE_EXT="${URL[0]##*.}"
  # -- Downloaded file full path -- #
  DOWNLOADED_FILE_FULL_PATH="${DIR}${DONWLOADED_FILE_NAME}"
  # -- User full file name -- #
  USER_FILENAME="${USER_FILENAME}.${DOWNLOADED_FILE_EXT}"
  # --
  # The script should prompt the user wheter he wants to:
  # read (if .txt), modify (if .txt)
  # --
  if [ "${DOWNLOADED_FILE_EXT}" == "txt" ] || [ "${DOWNLOADED_FILE_EXT}" == "TXT" ]; then
    # -- Downloaded file will have the name that user wants --#
    mv "${DOWNLOADED_FILE_FULL_PATH}" "${DIR}${USER_FILENAME}"
    echo -e "
      Your downloaded file is a: ${UNDERLINE_WHITE}txt file${NO_FORMAT}.
      Do you want to read the file or open it using text editor:
    "
    while true; do
      echo -e "
        Type [R] to ${BOLD_WHITE}read${NO_FORMAT} the file in terminal.
        Type [O] to ${BOLD_WHITE}open${NO_FORMAT} the file with a text editor.
      "
      read -r -p "Your choice: " ANSWER
      case "${ANSWER}" in
        [Rr] )
          echo ""
          cat "${DIR}${USER_FILENAME}"
          break
          ;;
        [Oo] )
          nano "${DIR}${USER_FILENAME}"
          break
          ;;
        * )
          echo -e "\nPlease type [R] to read the file in terminal or [O] to open with a text editor."
          ;;
      esac
    done
  # --
  # The script should prompt the user wheter he wants to: 
  # execute (if .sh or .bash) the downloaded file
  # --
  elif [[ "${DOWNLOADED_FILE_EXT}" == "sh" ]] || [[ "${DOWNLOADED_FILE_EXT}" == "SH" ]] || [[ "${DOWNLOADED_FILE_EXT}" == "bash" ]] || [[ "${DOWNLOADED_FILE_EXT}" == "BASH" ]]; then
    # -- Downloaded file will have the name that user wants --#
    mv "${DOWNLOADED_FILE_FULL_PATH}" "${DIR}${USER_FILENAME}"
    echo -e "
      Your downloaded file is a: ${UNDERLINE_WHITE}sh file${NO_FORMAT}.
      Do you want to execute your bash file?
    "
    while true; do
      echo -e "
        Type [X] to ${GREEN}execute${NO_FORMAT} the file.
        Type [C] to ${RED}cancel${NO_FORMAT}
      "
      read -r -p "Your choice: " ANSWER
      case "${ANSWER}" in
        [Xx] )
          echo -e "\nSetting execution permissions..."
          chmod +x "${DIR}${USER_FILENAME}"
          echo -e "Running script ${USER_FILENAME}"
          sh "${DIR}${USER_FILENAME}"
          break
          ;;
        [Cc] )
          break
          ;;
        * )
          echo -e "\nPlease type [X] to execute script or [C] to cancel."
          ;;
      esac
    done
  fi
  # -- 
  # The script should prompt the user if we wants 
  # to download a new file or exit the program 
  # --
  while true; do
    echo -e "
      Do you want to download another file or exit the program?
      Type [D] to download another file
      Type [E] to exit the program.
    "
    read -r -p "Your choice: " ANSWER
    case "${ANSWER}" in
      [Dd] )
        break # Go to download a file again
        ;;
      [Ee] )
        exit 1 # Exit program
        ;;
      * )
        echo "Please type [D] to download a file again or [E] to exit the program."
        ;;
    esac
  done
done
