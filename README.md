# chess-game-in-python

Infos
----

This is a chess game, implemented using pygame.
This game is implemented in Python, but a part of the logic is also implemented in cython, because it run faster



How to run this code :
---------------

You should run this code with  `python -O -m echec` .
The `-O`is important, because I use a lot of `if __debug__:` in my code, so without, it will run slower, and will print a lot of useless debug information

You can decide if the game will use multiprocessing by using the `--multi` option. If you pass -1, it will use the default behaviour (as many processes as cpu cores).
If you pass 0, it will not use multiprocessing. If you pass an another integer n, it will use n process.