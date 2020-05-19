#!/usr/bin/env bash

source ./oxo_logic.sh

# ########################################
# BASIC SANITY / COMPATIBILITY CHECKS
# ########################################

pause_for_keypress() {
    # Neat answer at https://unix.stackexchange.com/a/134554
    read -n1 -rsp "$(prompt "Press any key to continue: ")"
}

if [[ ${BASH_VERSINFO[0]} -lt 4 || ${BASH_VERSINFO[1]} -lt 4 ]]
then prompt "$(printf "%s\n" "WARNING: Bash version should be 4.4+. Things may break with this version (${BASH_VERSION}).")"
     pause_for_keypress
fi

if [[ ${is_voice_active} == ${FALSE} ]]
then prompt "$(printf "%s\n" "WARNING: Speech synthesis program not found. Voice prompts are inactive.")"
     pause_for_keypress
fi

# ########################################
# LET THE GAME BEGIN!!!
# ########################################

reset_board
clear
prompt "Welcome to Noughts and Crosses!"
printf "\nLoading game "; animate_loading_symbol 2;
prompt "THE GAME... IS AFOOT!"
prompt "$(printf "\n%s\n" "Pick a number, to choose game mode: ")"

select game_mode in "Two Player" "Computer Opponent" "Quit"
do
    case ${REPLY} in
        1) prompt "$(printf "%s chosen\n" "${game_mode}")"
           computer_opponent=${FALSE}
           break # selection acceptable; pass control to next statement
           ;;
        2) prompt "$(printf "%s chosen...\n" "${game_mode}")"
           computer_opponent=${TRUE}
           prompt "$(printf "\n%s\n" "You, are player \"X\".")"
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
