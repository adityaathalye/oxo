**To play**

- Clone, cd into the root dir, and run the "main" script: `$ ./oxo`
- Your machine should have Bash 4+, preferably Bash 4.4+ (latest stable)
- Be kind to the "Computer player". It is randumb :D

**To code-read**

- Board design and setup is at the beginning of `oxo_logic.sh`

- The scoring logic is based on pattern matches against a regularly-formatted board. See:
    - The linchpin function `fit_board_to_square_grid`
    - The commentary in the `# SCORING LOGIC` section
    - The scoring functions, particularly `__all_crosses`, `__all_noughts`, `__player_wins_grid`, `crosses_win`, `noughts_win`, and `its_a_draw`

- I like to write [Functional Programming style Bash](https://www.evalapply.org/tags/bash/).

- Follow the commit history to trace how the game logic gradually emerged.

**But why?!?**

For unabashed mirth and merriment, of course. Why else?
