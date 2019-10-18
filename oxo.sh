#!/bin/bash

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
# GLOBALS
# ########################################

declare -r TRUE=0
declare -r FALSE=1


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
declare -r square_side=3
declare -r board_size=$(( ${square_side} * ${square_side} ))

# Note: these array assignments create zero-indexed arrays
declare -a positions=($(seq $board_size))
declare -a col_labels=($(seq ${square_side}))
declare -a row_labels=($(head -n ${square_side} <(printf "%s\n" {a..z})))
declare -a pos_labels=($(for r in ${row_labels[*]}
                         do for c in ${col_labels[*]}
                            do printf "%s%s " ${r} ${c}
                            done
                         done))

declare -A pos_lookup_table &&
    for pos in ${positions[*]}
    do array_idx=$(( $pos -1 ))
       pos_lookup_key="${pos_labels[$array_idx]}"
       pos_lookup_val="${positions[$array_idx]}"
       pos_lookup_table[${pos_lookup_key}]=${pos_lookup_val}
    done &&
    unset array_idx pos_lookup_key pos_lookup_val # don't pollute global vars

declare -a diagonal_left &&
    for i in $(seq ${square_side})
    do diagonal_left[${i}]=$(( (${square_side} * (${i} - 1)) + ${i} ))
    done &&
    declare -r diagonal_left

declare -a diagonal_right &&
    for i in $(seq ${square_side})
    do diagonal_right[${i}]=$(( (${square_side} * ${i}) - (${i} - 1) ))
    done &&
    declare -r diagonal_right


function set_pos_to_val {
    local pos=${1}
    local val=${2}

    board_state[${pos}]=${val}
}

function reset_board {
    for i in $(seq ${board_size});
    do set_pos_to_val ${i} "-";
    done
}

function fit_val_to_square_grid {
    printf "%s%s" ${1} ' '
}

function fit_board_to_square_grid {
    for pos in $(seq ${board_size});
    do if [[ $(( $pos % $square_side )) == 0 ]]
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
#
# ########################################

function animate_loading_symbol {
    local loop_count=${1:-2}
    local char_sequence=('.' 'o' 'O' 'X' 'x' '.')
    local char_times_to_print=3
    local sleep_sec="0.1"

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
    local game_is_afoot=${TRUE} # the game is always afoot!
    local player_X_turn=${TRUE} # X always plays first when the game begins
    local player_O_turn=${FALSE}

    while [[ ${game_is_afoot} == ${TRUE} ]] ; do
        # Clean slate
        sleep 1
        clear

        cat <<EOF
======================================================================

THE GAME IS AFOOT!

    Please choose: Position (e.g. a1 or b3 or c2)  |  (Q)uit

======================================================================

EOF

        display_oxo_board

        read -p "Your choice: " player_choice

        printf "\n"

        case "${player_choice}" in
            q|Q )
                # Terminate the game
                printf "%s\n\n" "Thank you for playing; bye bye!"
                game_is_afoot=${FALSE}
                ;;
            [${row_labels[0]}-${row_labels[-1]}][${col_labels[0]}-${col_labels[-1]}] )
                # NOTE: Bash does NOT perform quote removal for patterns, so trying
                # to generate a pattern as follows does NOT work as hoped:
                #
                #      $(printf "%s|" ${pos_labels[*]} | sed -E 's;\|$;;') ) list ;;
                #
                #      # produces  a1|a2|a3|b1|b2|b3|c1|c2|c3  which _looks_ like a
                #      # pattern, but is effectively a single string that DOES NOT
                #      # get further stripped into a case match _pattern_.
                #
                printf "choice %s, position is %s\n" "${player_choice}" "${pos_lookup_table[${player_choice}]}"
                ;;
            * ) printf "\nBAD CHOICE. Please retry.\n\n" ;;
        esac
    done
}

reset_board
game_loop
