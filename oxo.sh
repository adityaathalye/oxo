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
# BOARD DESIGN
# ########################################

# All oxo boards are squares, and the board state is an array of:
# empty  = - (hyphen)
# cross  = X (upper case x)
# nought = O (upper case o)
declare -a board_state
declare -r square_side=3
declare -r board_size=$(( ${square_side} * ${square_side} ))

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
    local num_grid_columns=$(( ${square_side} * 2 ))

    for val in ${board_state[*]}; do fit_val_to_square_grid ${val} ; done \
        | fmt -w ${num_grid_columns} -
}

function transpose_board {
    local board=$(cat ${@})

    for i in $(seq ${square_side})
    do printf "$board" |
            cut -d ' ' -f ${i} |
            paste -d ' ' -s
    done
}

# We display based on the square grid
function display_oxo_board {
    local row_labels='\n\n\n\ta\n\tb\n\tc'
    local col_labels='\n\t1 2 3\n\n'

    paste <(printf ${row_labels}) \
          <(cat <(printf "$col_labels") \
                <(fit_board_to_square_grid) \
                <(printf "\n"))
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
    grep -E "^X[[:space:]]X[[:space:]]X[[:space:]]?$" > /dev/null
}

function __all_noughts {
    grep -E "^O[[:space:]]O[[:space:]]O[[:space:]]?$" > /dev/null
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
}

function crosses_win {
    1>&2 echo "FIXME: I am a stub."; exit 0;
}

function noughts_win {
    1>&2 echo "FIXME: I am a stub."; exit 0;
}
