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
declare -r board_size=$(( square_side * square_side ))

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
    printf "%s " ${1};
}

function fit_board_to_square_grid {
    local num_grid_columns=$(( ${square_side} * 2 ))

    for val in ${board_state[*]}; do fit_val_to_square_grid ${val} ; done \
        | fmt -w ${num_grid_columns} -
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
