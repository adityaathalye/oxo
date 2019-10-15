#!/bin/bash

source "./oxo.sh"

function set_board_to_values {
    local __values=${1}

    for i in $(seq ${board_size})
    do set_pos_to_val ${i} "$(printf "$__values" | cut -d ' ' -f ${i})"
    done
}

victory_X_row="O X O X X X X X O"
victory_O_row="O X O O O O X X O"

victory_X_col="X X O X X O X X O"
victory_O_col="O O X O O X O O X"

victory_left_diagonal_Xs="X X O O X O X O X"
victory_right_diagonal_Os="X X O X O X O X X"

set_board_to_values "$victory_X_row";
if __player_wins_grid_row __all_crosses
then echo "Player won Row Xs!"
fi

set_board_to_values "$victory_O_row";
if __player_wins_grid_row __all_noughts
then echo "Player won Row Os!"
fi

set_board_to_values "$victory_X_col";
if __player_wins_grid_col __all_crosses
then echo "Player won Col Xs!"
fi

set_board_to_values "$victory_O_col";
if __player_wins_grid_col __all_noughts
then echo "Player won Col Os!"
fi

set_board_to_values "$victory_left_diagonal_Xs";
if __player_wins_grid_left_diagonal __all_crosses
then echo "Player won Left Diagonal Xs!"
fi

set_board_to_values "$victory_right_diagonal_Os";
if __player_wins_grid_right_diagonal __all_noughts
then echo "Player won Right Diagonal Os!"
fi

set_board_to_values "$victory_left_diagonal_Xs";
if crosses_win
then echo "Crosses won!"
fi

set_board_to_values "$victory_right_diagonal_Os";
if noughts_win
then echo "Noughts won!"
fi
