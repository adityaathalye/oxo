#!/usr/bin/env bash

source ./oxo_logic.sh

# ########################################
# BASIC SANITY / COMPATIBILITY CHECKS
# ########################################

if [[ ${BASH_VERSINFO[0]} -lt 4 || ${BASH_VERSINFO[1]} -lt 4 ]]
then printf "%s\n" "WARNING Bash version should be 4.4+. Things may break with this version (${BASH_VERSION})."
fi

if ! which spd-say > /dev/null
then printf "%s\n" "WARNING Voice prompt will not work because spd-say is not available."
fi

# ########################################
# LET THE GAME BEGIN!!!
# ########################################

reset_board
clear
prompt "Welcome to Noughts and Crosses!"
printf "\nLoading game "; animate_loading_symbol 2;
prompt "THE GAME... IS AFOOT!"
prompt "$(printf "\n%s\n" "Choose game mode: ")"

select game_mode in "Two Player" "Computer Opponent" "Quit"
do
    case ${REPLY} in
        1) prompt "$(printf "%s chosen\n" "${game_mode}")"
           computer_opponent=${FALSE}
           break # selection acceptable; pass control to next statement
           ;;
        2) prompt "$(printf "%s chosen...\n" "${game_mode}")"
           computer_opponent=${TRUE}
           prompt "$(printf "\n%s\n" "You, are player X.")"
           sleep 3
           break # selection acceptable; pass control to next statement
           ;;
        3) prompt "$(printf "\n%s\n" "Quitting.")"
           exit 0
           ;;
        *) prompt "$(printf "\n%s\n" "Invalid choice.")"
           ;;
    esac
done

sleep 1
game_loop ${computer_opponent}
