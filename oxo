#!/bin/bash

source ./oxo_logic.sh

# ########################################
# BASIC SANITY / COMPATIBILITY CHECKS
# ########################################

if [[ ${BASH_VERSINFO[0]} -lt 4 || ${BASH_VERSINFO[1]} -lt 4 ]]
then printf "%s\n" "WARNING Bash version should be 4.4+. Things may break with this version (${BASH_VERSION})."
fi

# ########################################
# LET THE GAME BEGIN!!!
# ########################################

reset_board
clear
printf "\nLoading game "; animate_loading_symbol; printf "THE GAME IS AFOOT!\n\n"

select game_mode in "Two Player" "Computer Opponent" "Quit"
do
    case ${REPLY} in
        1) printf "%s chosen\n" "${game_mode}"
           computer_opponent=${FALSE}
           break # selection acceptable; pass control to next statement
           ;;
        2) printf "%s chosen\n" "${game_mode}"
           computer_opponent=${TRUE}
           break # selection acceptable; pass control to next statement
           ;;
        3) printf "\nQuitting\n"
           exit 0
           ;;
        *) printf "Invalid choice.\n"
           ;;
    esac
done

sleep 1
game_loop ${computer_opponent}
