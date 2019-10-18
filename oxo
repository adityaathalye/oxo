#!/bin/bash

source ./oxo.sh

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
printf "\nLoading game "; animate_loading_symbol; printf "THE GAME IS AFOOT!"
sleep 1
game_loop
