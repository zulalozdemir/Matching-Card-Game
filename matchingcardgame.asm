.data
bitmap_base:    .word 0x10010000   # Base address of the bitmap display

# Colors
color_dodgerblue:    .word 0xFF1E90FF   # Color for the back of the cards
color_blue:               .word 0x000000FF   # Blue
color_green:             .word 0x0000FF00   # Green
color_yellow:            .word 0x00FFFF00   # Yellow
color_white:              .word 0x00FFFFFF   # White
color_beige:              .word 0xFFFBF3C1   # Beige
color_mint:                .word 0xFF64E2B7   # Mint
color_pink:                .word 0xFFDC8BE0   # Pink
color_orange:           .word 0xFFFF6600   # Orange

# Color mapping: 2 cards per color (16 cards)
card_colors:    .word 0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7    # They get shuffled
colors_array:   .word 0x00FF0000, 0x000000FF, 0x0000FF00, 0x00FFFF00, 0xFFFBF3C1, 0xFF64E2B7, 0xFFDC8BE0, 0xFFFF6600  # Red, blue, green, yellow, beige, mint, pink, orange

# Game state variables
first_card:     .word -1       # Index of first selected card (-1 if none)
first_color:    .word -1       # Color of first selected card
matched_cards:  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  # 1 if card is matched and stays open
open_cards:     .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  # 1 if card is currently open (temporary array)
pairs_found:    .word 0        # Number of pairs found (game ends when this reaches 8)

# Score system variables
moves_counter:  .word 0        # Move counter (counts each pair of moves as 1)
best_score:     .word 999      # Best score (minimum number of moves)

# Display messages
msg_match:      .asciiz "\nMatch found!"
msg_no_match:   .asciiz "\nNo match found, cards closing..."
msg_select:     .asciiz "\nUse keyboard to select cards:\n1 2 3 4\nq w e r\na s d f\nz x c v"
msg_already:    .asciiz "\nThis card is already open!"
msg_win:        .asciiz "\nCongratulations! You found all matches!"
msg_moves:      .asciiz "\nTotal moves: "
msg_best:       .asciiz "\nYour best score: "
msg_diff:       .asciiz "\nSelect difficulty level: 1 (Easy), 2 (Medium), 3 (Hard): "
difficulty:     .word 1        # Default is easy
restart_msg:    .asciiz "\nDo you want to play again? (y/n): "
invalid_input_msg: .asciiz "\nInvalid input. Enter y or n."
invalid_diff_msg: .asciiz "\nInvalid difficulty level! Please press 1, 2 or 3: "
selected_diff_msg: .asciiz "\nSelected difficulty level: "

.text
.globl main
main:
    # Select difficulty level
    jal ask_difficulty

    # Shuffle the cards
    jal shuffle_cards
    
    # Reset move counter
    la $t0, moves_counter
    sw $zero, 0($t0)         # moves = 0
    
    # Load bitmap base address
    la $t0, bitmap_base
    lw $t2, 0($t0)          # $t2 = base address of bitmap

    # Settings (for 4x4 layout)
    li $s0, 4               # rows
    li $s1, 4               # cols 
    li $s2, 80              # card height
    li $s3, 60              # card width
    li $s4, 30              # spacing
    li $s5, 40              # start row
    li $s6, 90              # start col

    # ==== DRAW ALL 16 CARDS WITH BLUE (BACK FACES OF THE CARDS) ====
    jal draw_all_cards

    # Show instructions
    la $a0, msg_select
    li $v0, 4
    syscall

    # ==== GAME LOOP ====
game_loop:
    # Check if all pairs have been found
    la $t0, pairs_found
    lw $t1, 0($t0)
    li $t0, 8               # pairs_found 8 (16 cards = 8 pairs)
    beq $t1, $t0, game_win  # If pairs_found == 8 (end the game)

    # ==== WAIT FOR KEYBOARD INPUT ====
wait_key:
    li $t9, 0xFFFF0000       # Keyboard control register
    li $t8, 0xFFFF0004       # Keyboard data register
wait_loop:
    lw $t7, 0($t9)           # Check if key is ready
    beqz $t7, wait_loop      # If not ready, keep waiting
    lw $t6, 0($t8)           # Read char (ASCII)

    # First row: Keys 1, 2, 3, 4 (indices 0, 1, 2, 3)
    li $t7, '1'
    beq $t6, $t7, key_1
    li $t7, '2'
    beq $t6, $t7, key_2
    li $t7, '3'
    beq $t6, $t7, key_3
    li $t7, '4'
    beq $t6, $t7, key_4
    
    # Second row: Keys q, w, e, r (indices 4, 5, 6, 7)
    li $t7, 'q'
    beq $t6, $t7, key_q
    li $t7, 'w'
    beq $t6, $t7, key_w
    li $t7, 'e'
    beq $t6, $t7, key_e
    li $t7, 'r'
    beq $t6, $t7, key_r
    
    # Third row: Keys a, s, d, f (indices 8, 9, 10, 11)
    li $t7, 'a'
    beq $t6, $t7, key_a
    li $t7, 's'
    beq $t6, $t7, key_s
    li $t7, 'd'
    beq $t6, $t7, key_d
    li $t7, 'f'
    beq $t6, $t7, key_f
    
    # Fourth row: Keys z, x, c, v (indices 12, 13, 14, 15)
    li $t7, 'z'
    beq $t6, $t7, key_z
    li $t7, 'x'
    beq $t6, $t7, key_x
    li $t7, 'c'
    beq $t6, $t7, key_c
    li $t7, 'v'
    beq $t6, $t7, key_v
    
    # Invalid key, wait for a new key
    j wait_key

# Key handler routines - map keyboard keys to card indices
key_1:
    li $t0, 0
    j valid_key
key_2:
    li $t0, 1
    j valid_key
key_3:
    li $t0, 2
    j valid_key
key_4:
    li $t0, 3
    j valid_key
key_q:
    li $t0, 4
    j valid_key
key_w:
    li $t0, 5
    j valid_key
key_e:
    li $t0, 6
    j valid_key
key_r:
    li $t0, 7
    j valid_key
key_a:
    li $t0, 8
    j valid_key
key_s:
    li $t0, 9
    j valid_key
key_d:
    li $t0, 10
    j valid_key
key_f:
    li $t0, 11
    j valid_key
key_z:
    li $t0, 12
    j valid_key
key_x:
    li $t0, 13
    j valid_key
key_c:
    li $t0, 14
    j valid_key
key_v:
    li $t0, 15
    j valid_key
    
valid_key:
    move $t9, $t0            # Save index for later

    # ==== CHECK IF CARD IS ALREADY MATCHED ====
    la $t0, matched_cards
    sll $t7, $t9, 2          # card_index * 4 (word offset)
    add $t0, $t0, $t7
    lw $t7, 0($t0)           # Load matched status
    bnez $t7, wait_key       # If already matched ignore and wait for the next input

    # ==== CHECK IF CARD IS ALREADY OPEN ====
    la $t0, open_cards
    sll $t7, $t9, 2          # card_index * 4
    add $t0, $t0, $t7
    lw $t7, 0($t0)           # Load open status
    # If already open notify the user and wait for the next input
    bnez $t7, already_open   
    # ==== MARK CARD AS OPEN ====
    la $t0, open_cards
    sll $t7, $t9, 2          # card_index * 4
    add $t0, $t0, $t7
    li $t7, 1
    sw $t7, 0($t0)           # Mark as open

    # ==== FIND COLOR ====
    la $t0, card_colors
    sll $t6, $t9, 2          # Word offset
    add $t0, $t0, $t6
    lw $t1, 0($t0)           # $t1 = color index (0-7)

    la $t0, colors_array
    sll $t1, $t1, 2          # Color index * 4
    add $t0, $t0, $t1
    lw $t4, 0($t0)           # $t4 = actual color

    move $t6, $t9            # Restore card index

    # ==== CALCULATE CARD POSITION ====
    divu $t6, $s1            # Divide by number of columns
    mflo $t3                 # row = index / 4
    mfhi $t5                 # col = index % 4

    # Calculate top row
    mul $t6, $t3, $s2        # row * card_height
    mul $t7, $t3, $s4        # row * spacing
    add $t6, $t6, $t7
    add $t6, $t6, $s5        # $t6 = top row position

    # Calculate left column
    mul $t7, $t5, $s3        # col * card_width
    mul $t8, $t5, $s4        # col * spacing
    add $t7, $t7, $t8
    add $t7, $t7, $s6        # $t7 = left col position

    # Draw the card with its color
    move $a0, $t6            # Top position
    move $a1, $t7            # Left position
    move $a2, $t4            # Real color
    jal draw_card

    # ==== CHECK IF THIS IS FIRST OR SECOND CARD ====
    la $t0, first_card
    lw $t1, 0($t0)           # Load first card index
    
    li $t7, -1
    beq $t1, $t7, first_selection  # If first_card == -1, this is first selection

    # ==== PROCESS SECOND CARD ====
    # Get first card's color
    la $t0, first_color
    lw $t5, 0($t0)           # $t5 = first card color
    
    # Get current card's color
    la $t0, card_colors
    sll $t6, $t9, 2          # Word offset
    add $t0, $t0, $t6
    lw $t6, 0($t0)           # $t6 = current card color index
    
    # Increment move counter (counts when second card is selected)
    la $t0, moves_counter
    lw $t1, 0($t0)
    addi $t1, $t1, 1         # Increment moves
    sw $t1, 0($t0)           # Store updated moves counter
    
    # Check if colors match
    bne $t5, $t6, no_match   # If colors don't match, go to no_match
    
    # ==== MATCH FOUND ====
    # Play match sound (happy tone)
    li $a0, 72               # pitch
    li $a1, 300              # duration
    li $a2, 112              # instrument (bell)
    li $a3, 127              # volume
    li $v0, 31
    syscall
    
    li $a0, 76               # higher pitch
    li $a1, 300
    li $v0, 31
    syscall

    # Mark both cards as matched
    la $t0, matched_cards
    la $t1, first_card
    lw $t1, 0($t1)           # $t1 = first card index
    sll $t2, $t1, 2          # first_card * 4
    add $t0, $t0, $t2
    li $t2, 1
    sw $t2, 0($t0)           # Mark first card as matched
    
    la $t0, matched_cards
    sll $t2, $t9, 2          # current_card * 4
    add $t0, $t0, $t2
    li $t2, 1
    sw $t2, 0($t0)           # Mark current card as matched
    
    # Increment pairs found counter
    la $t0, pairs_found
    lw $t1, 0($t0)
    addi $t1, $t1, 1
    sw $t1, 0($t0)
    
    # Show match message
    la $a0, msg_match
    li $v0, 4
    syscall
    
    # Reset first card
    la $t0, first_card
    li $t1, -1
    sw $t1, 0($t0)

    # Reset open cards
    jal reset_open_cards

    # Reload bitmap base address, $t2 = base address of bitmap
    la $t0, bitmap_base
    lw $t2, 0($t0)          

    j game_loop
    
no_match:
    # Show no match message
    la $a0, msg_no_match
    li $v0, 4
    syscall
    
    # Get difficulty level
    la $t0, difficulty
    lw $t1, 0($t0)

    # Set delay based on difficulty level:
    # Easy (1)   => 800 ms
    # Medium (2) => 200 ms
    # Hard (3)   => 50 ms

    li $t2, 1
    beq $t1, $t2, delay_easy

    li $t2, 2
    beq $t1, $t2, delay_medium

    # Default to hard
    li $a0, 50
    j do_delay

delay_easy:
    li $a0, 800
    j do_delay

delay_medium:
    li $a0, 200
   

do_delay:
    li $v0, 32     # Sleep syscall
    syscall

    
    # Reset first card
    la $t0, first_card
    li $t1, -1
    sw $t1, 0($t0)
    
    # Close unmatched cards
    jal close_unmatched_cards
    
    j game_loop              # Return to game loop
    
first_selection:
    # Save this card as first selection
    la $t0, first_card
    sw $t9, 0($t0)           # Save current card index
    
    # Save color
    la $t0, card_colors
    sll $t1, $t9, 2          # Word offset
    add $t0, $t0, $t1
    lw $t1, 0($t0)           # $t1 = color index
    
    la $t0, first_color
    sw $t1, 0($t0)           # Save color index
    
    j game_loop              # Return to game loop

already_open:
    # Show card already open message
    la $a0, msg_already
    li $v0, 4
    syscall
    
    j wait_key               # Allow next selection

game_win:
# Playing victory fanfare for win(three ascending notes)
    li $a0, 72               # pitch
    li $a1, 500              # duration
    li $a2, 112              # instrument (bell)
    li $a3, 127              # volume
    li $v0, 31
    syscall
    
    li $a0, 76               # higher pitch
    li $a1, 500
    li $v0, 31
    syscall
    
    li $a0, 79               # even higher pitch
    li $a1, 1000
    li $v0, 31
    syscall
    
    # Show winning message
    la $a0, msg_win
    li $v0, 4
    syscall

    # Show move count
    la $a0, msg_moves
    li $v0, 4
    syscall

    la $t0, moves_counter
    lw $a0, 0($t0)
    li $v0, 1
    syscall

    # Check and update best score
    la $t0, moves_counter
    lw $t1, 0($t0)
    la $t2, best_score
    lw $t3, 0($t2)
    bge $t1, $t3, skip_best_update
    sw $t1, 0($t2)

skip_best_update:
    # Show best score
    la $a0, msg_best
    li $v0, 4
    syscall

    la $t0, best_score
    lw $a0, 0($t0)
    li $v0, 1
    syscall

    # Ask if player wants to play again
ask_restart:
    la $a0, restart_msg
    li $v0, 4
    syscall

wait_restart_key:
    li $t9, 0xFFFF0000       # Keyboard control
    li $t8, 0xFFFF0004       # Keyboard data
wait_restart_loop:
    lw $t7, 0($t9)
    beqz $t7, wait_restart_loop
    lw $t6, 0($t8)

    # If user enters ‘y’ restart the game
    li $t7, 'y'
    beq $t6, $t7, restart_game
    
   #If user enters ‘n’ exit the game
    li $t7, 'n'
    beq $t6, $t7, exit_game

    # Invalid input
    la $a0, invalid_input_msg
    li $v0, 4
    syscall
    j ask_restart

restart_game:
    # Select difficulty level again for new game
    jal ask_difficulty

    # Reset state except best_score
    la $t0, first_card
    li $t1, -1
    sw $t1, 0($t0)

    la $t0, first_color
    li $t1, -1
    sw $t1, 0($t0)

    la $t0, moves_counter
    sw $zero, 0($t0)

    la $t0, pairs_found
    sw $zero, 0($t0)

    # Reset matched_cards and open_cards arrays
    la $t0, matched_cards
    li $t1, 16               # Total number of cards
    li $t2, 0                # Counter
reset_match_loop:
    sw $zero, 0($t0)       # Reset to 0
    addi $t0, $t0, 4         # Move to next element
    addi $t2, $t2, 1         # Increment counter
    blt $t2, $t1, reset_match_loop

    la $t0, open_cards
    li $t2, 0                # Reset counter
reset_open_loop:
    sw $zero, 0($t0)         # Reset to 0
    addi $t0, $t0, 4         # Move to next element
    addi $t2, $t2, 1         # Increment counter
    blt $t2, $t1, reset_open_loop

    # Shuffle cards again
    jal shuffle_cards

    # Redraw cards
    # Load bitmap base address, $t2 = base address of bitmap
    la $t0, bitmap_base
    lw $t2, 0($t0)        
    jal draw_all_cards

    # Print instructions again
    la $a0, msg_select
    li $v0, 4
    syscall

    j game_loop

exit_game:
    li $v0, 10               # Exit program
    syscall

# ======= DIFFICULTY LEVEL SELECTION =======
ask_difficulty:
    # Show difficulty level message
    la $a0, msg_diff
    li $v0, 4
    syscall

    # Wait for user input through MMIO
    li $t9, 0xFFFF0000       # Keyboard control
    li $t8, 0xFFFF0004       # Keyboard data
wait_diff_key:
    lw $t7, 0($t9)           # Check if key is ready
    beqz $t7, wait_diff_key
    lw $t6, 0($t8)           # Read char (ASCII)
    
    # Check difficulty level
    li $t0, '1'              # '1' character (Easy)
    beq $t6, $t0, diff_easy
    li $t0, '2'              # '2' character (Medium)
    beq $t6, $t0, diff_medium
    li $t0, '3'              # '3' character (Hard)
    beq $t6, $t0, diff_hard
    
    # Invalid input, wait again
    la $a0, invalid_diff_msg
    li $v0, 4
    syscall
    j wait_diff_key
    
diff_easy:
    li $t0, 1                # Easy level
    j set_difficulty
    
diff_medium:
    li $t0, 2                # Medium level
    j set_difficulty
    
diff_hard:
    li $t0, 3                # Hard level
    
set_difficulty:
    # Save selected difficulty level
    la $t1, difficulty
    sw $t0, 0($t1)
    
    # Display selected difficulty level
    la $a0, selected_diff_msg
    li $v0, 4
    syscall
    
    move $a0, $t0
    li $v0, 1
    syscall
    
    # New line 
    li $a0, '\n'
    li $v0, 11
    syscall
    
    jr $ra

# ======= RESET OPEN CARDS =======
reset_open_cards:
    # Reset open_cards array (keeping matched ones open)
    la $t0, open_cards
    li $t1, 0                # Counter
    li $t3, 16              # Maximum number of cards
reset_loop:
    bge $t1, $t3, reset_done
    
    # Calculate address of open_cards[i]
    sll $t2, $t1, 2          # i * 4
    add $t2, $t0, $t2        # Address of open_cards[i]
    
    # Set to 0
    sw $zero, 0($t2)
    
    addi $t1, $t1, 1
    j reset_loop
    
reset_done:
    jr $ra

# ======= CLOSE UNMATCHED CARDS =======
close_unmatched_cards:
    # Create stack frame 
    addi $sp, $sp, -4        # Push $ra
    sw   $ra, 0($sp)

    # Reset open_cards array 
    jal  reset_open_cards 

    #Reload bitmap base address
    la   $t0, bitmap_base    # Recalculate
    lw   $t2, 0($t0)         # $t2 = bitmap base (used by draw_card)

    # Close stack frame
    lw   $ra, 0($sp)         # Pop $ra
    addi $sp, $sp, 4

    # Redraw cards
    j    draw_all_cards      # Returns directly to caller when draw_all_cards finishes

# ======= DRAW ALL CARDS =======
draw_all_cards:
    addi $sp, $sp, -4
    sw $ra, 0($sp)           # Save return address
    
    li $t3, 0                # Card index
draw_all_loop:
    # Check if card is matched
    la $t0, matched_cards
    sll $t1, $t3, 2          # card_index * 4
    add $t0, $t0, $t1
    lw $t4, 0($t0)           # $t4 = matched status
    
    # Check if card is open
    la $t0, open_cards
    sll $t1, $t3, 2          # card_index * 4
    add $t0, $t0, $t1
    lw $t5, 0($t0)           # $t5 = open status
    
    # Determine card color
    la $t0, color_dodgerblue
    lw $t1, 0($t0)           # $t1 = dodgerblue (default - back of the cards)
    
    # If matched or open, show real color
    or $t6, $t4, $t5         # Either matched or open
    beqz $t6, use_default_color
    
    # Get real color
    la $t0, card_colors
    sll $t6, $t3, 2          # card_index * 4
    add $t0, $t0, $t6
    lw $t6, 0($t0)           # $t6 = color index
    
    la $t0, colors_array
    sll $t6, $t6, 2          # color_index * 4
    add $t0, $t0, $t6
    lw $t1, 0($t0)           # $t1 = real color
    
use_default_color:
    # Calculate card position
    divu $t7, $t3, $s1       # Divide by number of columns
    mflo $t8                 # row = index / cols
    mfhi $t9                 # col = index % cols
    
    # Calculate top row
    mul $t6, $t8, $s2        # row * card_height
    mul $t7, $t8, $s4        # row * spacing
    add $t6, $t6, $t7
    add $t6, $t6, $s5        # $t6 = top row position
    
    # Calculate left column
    mul $t7, $t9, $s3        # col * card_width
    mul $t8, $t9, $s4        # col * spacing
    add $t7, $t7, $t8
    add $t7, $t7, $s6        # $t7 = left col position
    
    # Draw the card
    move $a0, $t6            # Top position
    move $a1, $t7            # Left position
    move $a2, $t1            # Color
    jal draw_card
    
    addi $t3, $t3, 1         # Next card
    li $t0, 16
    blt $t3, $t0, draw_all_loop
    
    lw $ra, 0($sp)           # Restore return address
    addi $sp, $sp, 4
    jr $ra

# ======= SHUFFLE CARDS (Fisher-Yates algorithm) =======
shuffle_cards:
    # Initialize random number generator
    li $v0, 30               # Syscall for system time
    syscall
    move $a1, $a0            # Use time as seed
    li $a0, 1                # ID for random number generator
    li $v0, 40               # Syscall for seed random number generator
    syscall

    # Shuffle card_colors array (16 elements)
    li $t0, 15               # i = n-1 (15)
shuffle_loop:
    blt $t0, 1, shuffle_done # While i >= 1
    
    # Generate random number between 0 and i
    move $a1, $t0            # Upper bound is i
    li $v0, 42               # Syscall for random int range
    syscall                  # a0 now has random number (0 <= r <= i)
    
    # Calculate addresses
    la $t1, card_colors      # Base address
    sll $t2, $t0, 2          # i * 4
    add $t2, $t1, $t2        # Address of card_colors[i]
    sll $t3, $a0, 2          # j * 4
    add $t3, $t1, $t3        # Address of card_colors[j]
    
    # Swap card_colors[i] and card_colors[j]
    lw $t4, 0($t2)           # temp = card_colors[i]
    lw $t5, 0($t3)           # Load card_colors[j]
    sw $t5, 0($t2)           # card_colors[i] = card_colors[j]
    sw $t4, 0($t3)           # card_colors[j] = temp
    
    addi $t0, $t0, -1        # i--
    j shuffle_loop
    
shuffle_done:
    jr $ra

# ======= draw_card($a0=top_row, $a1=left_col, $a2=color) =======
draw_card:
    li $t0, 0                # Row offset
card_row_loop:
    li $t1, 0                # Column offset
card_col_loop:
    add $t6, $a0, $t0        # Pixel row
    add $t7, $a1, $t1        # Pixel column

    # Calculate memory offset for pixel
    mul $t8, $t6, 512        # row * 512 (pixels per row)
    add $t8, $t8, $t7        # row * 512 + col
    sll $t8, $t8, 2          # * 4 (bytes per pixel)
    add $t8, $t2, $t8        # bitmap address + offset
  
    sw $a2, 0($t8)           # Set pixel color

    addi $t1, $t1, 1         # Move to next column
    blt $t1, $s3, card_col_loop  # Continue if col < card_width

    addi $t0, $t0, 1         # Move to next row
    blt $t0, $s2, card_row_loop  # Continue if row < card_height

    jr $ra                   # Return to caller


