MATCHING CARD GAME

This is a memory matching game implemented in MIPS assembly for the MARS simulator. The game features a 4×4 grid (16 cards) with 8 matching pairs of different colors. The player must flip cards to find all matching pairs with the fewest moves possible.

Bitmap Display Settings:
Unit Width in Pixels: 1 px
Unit Height in Pixels: 1 px
Display Width in Pixels: 512 px
Display Height in Pixels: 512 px
Base address for display: 0x10010000 (static data)

Controls:
The game uses the keyboard for input. Each card is mapped to a key like this:

1  2  3  4

q  w  e  r

a  s  d  f

z  x  c  v

Press a key to flip the corresponding card.

Find two matching cards to keep them face-up.

The game ends when all 8 pairs are found.

Difficulty Levels:
You can choose between 3 difficulty levels at the beginning:

1 (Easy): Cards stay visible longer (800ms delay).

2 (Medium): Moderate visibility time (200ms delay).

3 (Hard): Cards flip quickly (50ms delay).

Scoring:
Each pair of selections (2 cards) counts as 1 move.

The best score (lowest moves) is saved between games.

Game Rules:
If two flipped cards match, they stay open.

If they don’t match, they flip back after a delay.

You cannot flip an already-matched card.

The game ends when all 8 pairs are found.

You can restart a new game when the current game ends by entering 'y' from the keyboard.

You can exit the game after the current game ends by entering 'n' from the keyboard.
