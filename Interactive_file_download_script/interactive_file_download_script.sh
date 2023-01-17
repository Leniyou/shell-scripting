#!/bin/bash
#
### Interactive file download script ###
#
# Someone lazy wants a script to download files from HTTP URLs and do some stuff with the downloaded file.
#
# - The script should read the HTTP URL parameter, and should only recieve 1 parameter.
# If it reads more than one the script should exit with a message.
# - The script should prompt the user where the downloaded file should be stored.
# - The script should prompt the user what file name the downloaded file should have.
# - The script should prompt the user wheter he wants to: read (if .txt), modify (if .txt) or execute (if .sh or .bash) the downloaded file.
# - The script should prompt the user if we wants to download a new file or exit the program.

## These variables are for letter formatting
ITALIC='\033[3m'                      # Italic
BOLD_RED='\033[1;31m'                 # Bold Red
RED='\033[0;31m'                      # Red
GREEN='\033[0;32m'                    # Green
BOLD_GREEN='\033[1;32m'   		        # Bold Red
BOLD_WHITE='\033[1;37m'       		    # White
UNDERLINE_WHITE='\033[4;37m'       	  # Underline White
NO_FORMAT='\033[0m' 			            # No Color or format

## Array for allowed URL extensions file
EXTENSIONS=(txt TXT sh SH bash BASH)

### To ask the user to type HTTP URL where he wants to download files from ###
while true;
do

  ## User input is store in URL() array to know how many inputs have been typed
  echo -e "\nType the URL where you want to download files from."
  read -r -a URL -p "Please make sure to type only 1 URL: "

  ## The script should read the HTTP URL parameter, and should only recieve 1 parameter
  if [[ "${#URL[@]}" -gt 1 ]];
  then
    echo -e "\nYou have just typed ${BOLD_RED}more than 1 URL${NO_FORMAT}, please make sure to type ${BOLD_GREEN}only 1 URL${NO_FORMAT}."
    echo -e "\nExit status 1"
    exit 1
  fi

  ## To verify if URL is valid 
  ## If 404 is returned then page doesn't exist
  if curl --head --silent "${URL[0]}" | head -n 1 | grep -q 404;
  then
    echo -e "\nThe page you have typed ${BOLD_RED}returns 404 error${NO_FORMAT}, please make sure to correct any typing errors or type ${BOLD_GREEN}only 1 URL${NO_FORMAT}."
    echo -e "\nExit status 1"
    exit 1
  else

    ## To verify if URL has a file with a valid file extension
    ## This script works with txt and sh/bash extension
    COUNT=0
    for EXT in "${EXTENSIONS[@]}";
    do
      if [[ "${URL[0]##*.}" == "${EXT}" ]];
      then
        # If URL has a valid file extension then we go to other block of code
        break
      
      else
        COUNT=$(( COUNT+1 ))
        if [[ ${COUNT} -eq "${#EXTENSIONS[@]}" ]]
        then
          echo -e "\nThe page you have typed does not contain a valid extension file."
          echo -e "For this script to work you should provide an URL ending with"
          echo -e "extensions: txt or sh, i.e. ${ITALIC}https://example.com/text.txt ${NO_FORMAT}"
          echo -e "\nExit status 1"
          exit 1
        fi
      fi
    done
    
    ### The script should prompt the user where the downloaded file should be stored ###
    while true;
    do
      echo ""
      read -r -p "Type the full path where you want to store downloaded file: " DIR
    
      # If it is a valid directory
      if [[ -d ${DIR} ]];
      then
    
        ## Script will check if user has READING permissions
        if [[ -r ${DIR} ]];
        then
          
          ## This is just to validate that DIR variable has the slash at the end /
          if [[ "${DIR: -1}" != "/" ]];
          then
            # Add slash / to the end of DIR var
            DIR="${DIR}/"

          elif [[ "${DIR: -2}" == "//" ]];
          then
            # Remove double // from the end of DIR var
            DIR="${DIR::-1}"
          fi

          echo -e "Your file name will be saved in: "
          echo -e "${ITALIC}${DIR}${NO_FORMAT}"
          echo -e ""

          ## The script should prompt the user what file name the downloaded file should have
          while true;
          do
            echo ""
            read -r -p "Type the name you want for downloaded file: " USER_FILENAME

            ## To check if user type a valid file name
            if ! [[ $USER_FILENAME =~ ^[a-zA-Z]+$ ]];
            then
              echo -e "\nThe file name ${ITALIC}${USER_FILENAME}${NO_FORMAT} you typed contains ${RED}invalid characters${NO_FORMAT}."
              echo -e "Only a-z or A-Z characters are allowed" >&2 # write to stderr
            else
              break
            fi
          done
          
          # To download the file
          curl -O --output-dir "${DIR}" "${URL[0]}"

          # Downloaded file name var
          DONWLOADED_FILE_NAME=$(basename "${URL[0]}")

          # Downloaded file extension var
          DOWNLOADED_FILE_EXT="${URL[0]##*.}"
          
          # Downloaded file full path
          DOWNLOADED_FILE_FULL_PATH="${DIR}""${DONWLOADED_FILE_NAME}"

          # User full file name
          USER_FILENAME="${USER_FILENAME}"."${DOWNLOADED_FILE_EXT}"

          # User full path
          USER_FULL_PATH="${DIR}""${USER_FILENAME}"

          ## The script should prompt the user wheter he wants to: read (if .txt), modify (if .txt)
          if [ "${DOWNLOADED_FILE_EXT}" == "txt" ] || [ "${DOWNLOADED_FILE_EXT}" == "TXT" ];
          then
            # To change the filename that user wants
            mv "${DOWNLOADED_FILE_FULL_PATH}" "${USER_FULL_PATH}"

            echo -e "\nYour downloaded file is a: ${UNDERLINE_WHITE}txt file${NO_FORMAT}."
            echo -e "Do you want to read the file or open it using text editor:"

            while true;
            do
              echo -e "Type [R] to ${BOLD_WHITE}read${NO_FORMAT} the file in terminal."
              echo -e "Type [O] to ${BOLD_WHITE}open${NO_FORMAT} the file with a text editor."
              read -r -p "Your choice: " ANSWER

              case "${ANSWER}"
              in
                [Rr] )
                  echo ""
                  cat "${DIR}""${USER_FILENAME}"
                  
                  break
                  ;;

                [Oo] )
                  nano "${DIR}""${USER_FILENAME}"

                  break
                  ;;
                
                * )
                  echo -e "\nPlease type [R] to read the file in terminal or [O] to open with a text editor."
                  
                  ;;
              esac

            done # //end while loop

            break # //end while loop that asks for directory

          ## The script should prompt the user wheter he wants to: execute (if .sh or .bash) the downloaded file
          elif [[ "${DOWNLOADED_FILE_EXT}" == "sh" ]];
          then
            # To change the filename that user wants
            mv "${DOWNLOADED_FILE_FULL_PATH}" "${USER_FULL_PATH}"

            echo -e "\nYour downloaded file is a: ${UNDERLINE_WHITE}sh file${NO_FORMAT}."
            echo -e "Do you want to execute your bash file?"

            while true;
            do
              echo -e "Type [X] to ${GREEN}execute${NO_FORMAT} the file"
              echo -e "Type [C] to ${RED}cancel${NO_FORMAT} "
              read -r -p "Your choice: " ANSWER

              case "${ANSWER}"
              in
                [Xx] )
                  echo -e "\nSetting execution permissions..."
                  chmod +x "${USER_FULL_PATH}"

                  echo -e "Running script ${USER_FILENAME}"
                  sh "${USER_FULL_PATH}"

                  break
                  ;;

                [Cc] )

                  break
                  ;;
                
                * )
                  echo -e "\nPlease type [X] to execute script or [C] to cancel."
                  
                  ;;

              esac

            done # //end while loop

            break # //end while loop that asks for directory

          fi # //end if script should prompt
          

        else
          
          # If user has NO READING permissions
          echo -e "\n${BOLD_RED}ERROR:${NO_FORMAT}"
          echo -e "You don't have ${RED}READ permissions${NO_FORMAT} in this directory ${ITALIC}${DIR}${NO_FORMAT}"
          echo -e "You should specified a new directory \n"

          break

        fi # //end if user has READ permissions

      else

        # If it is not a valid directory, an error will be printed in terminal
        echo -e "${ITALIC}${DIR}${NO_FORMAT} is ${RED}not a directory${NO_FORMAT}\n"

      fi # //is a valid directory,

    done # // The script should prompt the user where the downloaded file
  fi

  ### The script should prompt the user if we wants to download a new file or exit the program ###
  while true;
  do
    echo -e "\n"
    echo -e "Do you want to download another file or exit the program."
    echo -e "Type [D] to download another file"
    echo -e "Type [E] to exit the program."
    read -r -p "Your choice: " ANSWER

    case "${ANSWER}"
    in
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

  done # //end while loop to exit program

done # //end while loop
exit 0
