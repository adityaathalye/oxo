#!/usr/bin/env bash

# ########################################
# Traditional Noughts and Crosses
#
# - 3x3 board with 2 players
# - player 1 is human
# - player 2 can be human or computer
# - Any full diagonal or horizontal wins
# - First player starts with x always
#
# ########################################


# ########################################
# GLOBALS and UTILS
# ########################################

declare -r square_side=3
declare -r board_size=$(( ${square_side} * ${square_side} ))

declare -r TRUE=0
declare -r FALSE=1

function to_indices {
    local array_size=${1}
    printf "%s " $(seq 0 $(( ${array_size} - 1)))
}

if which spd-say > /dev/null
then voice_prompter='spd-say -e'
else voice_prompter='tee /dev/null'
fi && declare -r voice_prompter

function prompt {
    cat <<<"${@}" | $voice_prompter
}

# ########################################
# BOARD DESIGN
#
# All oxo boards are squares, and the board state is an array of:
# empty  = - (hyphen)
# cross  = X (upper case x)
# nought = O (upper case o)
#
# ########################################

declare -a board_state
declare -a positions=($(to_indices ${board_size}))

# We expect players to visually locate board positions on the game board,
# and mark the desired positions by Row-Column pair <character><integer>,
# such as a1, a3, b2, c1.
declare -a col_labels=($(seq ${square_side}))
declare -a row_labels=($(head -n ${square_side} <(printf "%s\n" {a..z})))
declare -a pos_labels=($(for r in ${row_labels[*]}
                         do for c in ${col_labels[*]}
                            do printf "%s%s " ${r} ${c}
                            done
                         done))

# Given player input, we need to reverse-lookup the corresponding index
# position in the array that stores the board's state.
declare -A pos_lookup_table &&
    for pos in ${positions[*]}
    do pos_lookup_key="${pos_labels[$pos]}"
       pos_lookup_val="${positions[$pos]}"
       pos_lookup_table[${pos_lookup_key}]=${pos_lookup_val}
    done &&
    unset array_idx pos_lookup_key pos_lookup_val # don't pollute global vars


# Pre-calculate indices for diagonal positions stored in the board state array.
# We will need to check state of diagonals for scoring purposes.
declare -a diagonal_left &&
    for i in $(to_indices ${square_side})
    do diagonal_left[${i}]=$(( (${square_side} * ${i}) + ${i} ))
    done &&
    declare -r diagonal_left


declare -a diagonal_right &&
    for i in $(to_indices ${square_side})
    do diagonal_right[${i}]=$(( (${square_side} * (${i} + 1 )) - (${i} + 1) ))
    done &&
    declare -r diagonal_right


# ########################################
# BOARD STATE AND DISPLAY MANIPULATION UTILITIES
# ########################################


function set_pos_to_val {
    local pos=${1}
    local val=${2}

    board_state[${pos}]=${val}
}

function reset_board {
    for i in $(to_indices ${board_size});
    do set_pos_to_val ${i} "-";
    done
}

function fit_val_to_square_grid {
    printf "%s%s" ${1} ' '
}

function fit_board_to_square_grid {
    for pos in $(to_indices ${board_size})
    do if [[ $(( ($pos + 1) % $square_side )) == 0 ]]
       then printf "%s \n" $(fit_val_to_square_grid ${board_state[${pos}]})
       else fit_val_to_square_grid ${board_state[${pos}]}
       fi
    done
}

function transpose_board {
    local board=$(cat ${@})

    __transpose_col() { cut -d ' ' -f ${1} | paste -d ' ' -s; }

    for col_num in $(seq ${square_side})
    do printf "%s \n" "$(printf "%s" "${board}" | __transpose_col ${col_num})"
    done
}

# We display based on the square grid
function display_oxo_board {
    printf "\n"
    printf "\t\t%s\n\n" "$(printf "%s " ${col_labels[*]})"
    paste <(printf "\t%s\n" ${row_labels[*]}) \
          <(fit_board_to_square_grid)
    printf "\n"
}


# ##################################################
# RANDOM Player support
# ##################################################

function __get_random_pos {
    printf "$(( ${RANDOM} % ${1} ))"
}

function __get_labels_for_empty_pos {
    for pos in $(to_indices ${board_size})
    do if [[ ${board_state[${pos}]} == "-" ]]
       then printf "%s " ${pos_labels[${pos}]}
       fi
    done
}

function get_label_for_random_empty_pos {
    local labels_for_empty_pos=($(__get_labels_for_empty_pos))
    local num_empty_pos=${#labels_for_empty_pos[*]}

    local empty_pos_labels_rand_idx=$(__get_random_pos ${num_empty_pos})

    # lookup and emit label for randomly picked empty position, such that
    # which we can pass it into regular gameplay, as computer's choice
    printf "%s" ${labels_for_empty_pos[${empty_pos_labels_rand_idx}]}
}

# ########################################
# SCORING LOGIC
#
# Base it on a regular, well-formatted, grid layout of the game state,
# so we can have some fun exploiting the text processing power of bash.
#
# We have three victory scenarios that we can test as follows.
#
# Row Victory:
#
# - A player wins a game if the pattern of _any row_ is "X X X " or
#   "O O O " in our scheme of things. This is simply a strict grep that
#   succeeds (exit code 0) against our grid view:
#
#       grep -E "^X[[:space:]]X[[:space:]]X[[:space:]]$"
#
# Column Victory:
#
# - If we transpose the board (columns -> rows), then we can reuse the
#   same grid-based grep-check to see if a player has won a column.
#
# Diagonal Victory:
#
# - And finally, if we extract diagonal items from the game state array
#   into a grid-formatted row (say items 1,5,9), then we can again use
#   the exact same grep test.
#
# ########################################
function __all_crosses {
    local all_Xs_pattern="$(printf "^(X[[:space:]]){%s}$" ${square_side})"
    grep -E "${all_Xs_pattern}" > /dev/null
}

function __all_noughts {
    local all_Os_pattern="$(printf "^(O[[:space:]]){%s}$" ${square_side})"
    grep -E "${all_Os_pattern}" > /dev/null
}

function __player_move_available {
    fit_board_to_square_grid | grep '-' > /dev/null
}

function __player_wins_grid_row {
    local player_win_func=${1}

    fit_board_to_square_grid | $player_win_func
}

function __player_wins_grid_col {
    local player_win_func=${1}

    fit_board_to_square_grid | transpose_board | $player_win_func
}

function __extract_this_diagonal {
    local diagonal=${1}

    for board_pos in ${diagonal}
    do fit_val_to_square_grid ${board_state[${board_pos}]}
    done
}

function __player_wins_grid_left_diagonal {
    local player_win_func=${1}

    __extract_this_diagonal "${diagonal_left[*]}" | $player_win_func
}

function __player_wins_grid_right_diagonal {
    local player_win_func=${1}

    __extract_this_diagonal "${diagonal_right[*]}" | $player_win_func
}

function __player_wins_grid {
    local player_win_func=${1}

    if __player_wins_grid_row $player_win_func \
            || __player_wins_grid_col $player_win_func \
            || __player_wins_grid_left_diagonal $player_win_func \
            || __player_wins_grid_right_diagonal $player_win_func
    then true
    else false
    fi
}

function crosses_win {
    __player_wins_grid __all_crosses
}

function noughts_win {
    __player_wins_grid __all_noughts
}

function its_a_draw {
    if crosses_win \
            || noughts_win \
            || __player_move_available
    then false
    else true
    fi
}

# ########################################
# PLAYER ACTIONS
#
# - The only thing a player can do is point to the position they
#   want filled with their assigned symbol X or O.
#
# - Only an empty position may be overwritten with legal X/O values.
#
# - Once an X or an O is written to a position, it may never be overwritten.
#
# ########################################

function pos_is_empty {
    local position="${1}"
    [[ ${board_state[${position}]} == '-' ]]
}

function set_pos_to_X {
    local position="${1}"
    if pos_is_empty ${position}
    then set_pos_to_val ${position} 'X'
    else false
    fi
}

function set_pos_to_O {
    local position="${1}"
    if pos_is_empty ${position}
    then set_pos_to_val ${position} 'O'
    else false
    fi
}

# ########################################
# GAME LOOP
#
# - On each move, check if noughts won, or crosses won
#
# ########################################

function animate_loading_symbol {
    local loop_count=${1:-1}
    local char_sequence=('.' 'o' 'O' 'X' 'x' '.')
    local char_times_to_print=3
    local sleep_sec="0.075"

    for _ in $(seq ${loop_count})
    do for c in ${char_sequence[*]}
       do for _ in $(seq ${char_times_to_print})
          do printf "%s" "${c}"
             sleep ${sleep_sec}
          done
          for _ in $(seq ${char_times_to_print})
          do printf "\b"
          done
       done
    done
}

function game_loop {
    local computer_opponent=${1:-${FALSE}} # init game for 2 player by default
    local game_is_afoot=${TRUE} # the game is always afoot!
    local player_X_turn=${TRUE} # X always plays first when the game begins
    local player_O_turn=${FALSE}
    local player_choice player_prompt # define variables for use below

    function __display_header {
        cat <<EOF
xoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxo

THE GAME IS AFOOT!

    Choose position (e.g. a1 or b3 or c2)  |  (Q)uit

xoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxo
EOF
    }

    function __display_player_prompt {
        if [[ ${player_X_turn} == ${TRUE} ]]
        then prompt "Player X's choice: "
        else prompt "Player O's choice: "
        fi
    }

    function __toggle_player {
        if [[ ${player_X_turn} == ${TRUE} ]]
        then player_O_turn=${TRUE}
             player_X_turn=${FALSE}
        else player_X_turn=${TRUE}
             player_O_turn=${FALSE}
        fi
    }

    while [[ ${game_is_afoot} == ${TRUE} ]] ; do

        # ##################################################
        # Repaint display
        # ##################################################
        clear
        __display_header
        display_oxo_board

        # ##################################################
        # Loop only while the game can still legally go on
        # ##################################################

        if noughts_win
        then player_choice="Q"  # Hook into "quit" case, handled below
             prompt "$(printf "\n%s\n" "GAME OVER... NOUGHTS WON!")"
        elif crosses_win
        then player_choice="Q"  # Hook into "quit" case, handled below
             prompt "$(printf "\n%s\n" "GAME OVER... CROSSES WON!")"
        elif its_a_draw
        then player_choice="Q"  # Hook into "quit" case, handled below
             prompt "$(printf "\n%s\n" "GAME OVER... IT'S A DRAW!")"
        elif [[ ${computer_opponent} == ${TRUE} && ${player_O_turn} == ${TRUE} ]]
        then                    # Get the computer to make its move
            player_choice="$(get_label_for_random_empty_pos)"
            __display_player_prompt
            printf "Computer is thinking... "
            animate_loading_symbol
            prompt "Computer chose ${player_choice}"
            sleep 2
        else                    # Accept player input, handled below
            read -p "$(__display_player_prompt)" player_choice
        fi

        # ##################################################
        # Handle player choice
        # ##################################################

        case "${player_choice}" in
            q|Q )
                # ##################################################
                # Terminate the game and cleanup any runtime stuff
                # ##################################################
                prompt "$(printf "\n%s\n\n" "Thank you for playing; bye bye!")"
                game_is_afoot=${FALSE}
                ;;

            [${row_labels[0]}-${row_labels[-1]}][${col_labels[0]}-${col_labels[-1]}] )
                # ##################################################
                # Safe-set the matched position for the current player
                # ##################################################
                #
                # NOTE: Bash does NOT perform quote removal for patterns, so trying
                # to generate a pattern as follows does NOT work as hoped:
                #
                #      $(printf "%s|" ${pos_labels[*]} | sed -E 's;\|$;;') ) list ;;
                #
                #      # produces  a1|a2|a3|b1|b2|b3|c1|c2|c3  which _looks_ like a
                #      # pattern, but is effectively a single string that DOES NOT
                #      # get further stripped into a case match _pattern_.
                #

                [[ ${player_X_turn} == ${TRUE} ]] \
                    && set_pos_to_X ${pos_lookup_table[${player_choice}]} \
                    && __toggle_player # cause toggle IFF position is set by player successfully

                [[ ${player_O_turn} == ${TRUE} ]] \
                    && set_pos_to_O ${pos_lookup_table[${player_choice}]} \
                    && __toggle_player # cause toggle IFF position is set by player successfully
                ;;

            * ) prompt "BAD CHOICE. Please retry. "
                sleep 1
                ;;
        esac
    done
}
