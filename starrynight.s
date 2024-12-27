# mp1.s - Your solution goes here
#
        .section .data                    # Data section for constants and variables
        .extern skyline_beacon             # Declare the external global variable
        .extern skyline_stars              # Declare the external array of stars
        .extern skyline_star_cnt           # Declare the external star count variable
        .extern skyline_win_list          # Declare the external window list pointer
        .extern malloc                        #for add_window allocation for insertion
        .extern free                          #for remove_window deallocation of memory node

        .global skyline_star_cnt
        .type   skyline_star_cnt, @object

        .align 2
        .global MAX_STARS
        .global SCREEN_WIDTH
        .global SCREEN_HEIGHT
        .global STAR_CONST
        .global DRAW_HELPER
        .global DRAW_CONST
        .global WINDOW_STRUCT_SIZE
        .global STACK_SPACE
        .global MALLOC_SPACE
        .global SHIFT_MULTIPLIER
        .global SHIFT_LEFT_9
        .global SHIFT_LEFT_7

# Constants
MAX_STARS:      .word 1000                  # Maximum number of stars
SCREEN_WIDTH:   .word 640                   # Screen width
SCREEN_HEIGHT:  .word 480                   # Screen height
WINDOW_STRUCT_SIZE = 16                     # Size of the window struct
STACK_SPACE = 8                            # Space needed on the stack for saving ra and registers
MALLOC_SPACE = 16                           # malloc space for adding window
SHIFT_MULTIPLIER = 3                        # Multiplier for shifting by 3 (to multiply by 8)
SHIFT_LEFT_9 = 9                            # Shift left by 9 (equivalent to multiplying by 512)
SHIFT_LEFT_7 = 7                            # Shift left by 7 (equivalent to multiplying by 128)

        .text

# ------------------ start_beacon ------------------
        .global start_beacon
        .type   start_beacon, @function

start_beacon:
        la t0, skyline_beacon             # Load address of skyline_beacon into t0 (t0 is 64-bit)

        # Store the function arguments into the struct fields
        sd a0, 0(t0)                      # Store img (a0, 64-bit) at offset 0 (8 bytes)
        sh a1, 8(t0)                      # Store x (a1, 16-bit) at offset 8 (after img pointer)
        sh a2, 10(t0)                     # Store y (a2, 16-bit) at offset 10
        sb a3, 12(t0)                     # Store dia (a3, 8-bit) at offset 12
        sh a4, 14(t0)                     # Store period (a4, 16-bit) at offset 14
        sh a5, 16(t0)                     # Store ontime (a5, 16-bit) at offset 16
        ret                               # Return to caller

# ------------------ add_star ------------------
# - Function adds a star to the skyline_star_cnt array and stores arguments x, y, and color
        .global add_star
        .type add_star, @function

add_star:
        # Arguments:
        # a0 = x (uint16_t) -- x-coordinate of the star
        # a1 = y (uint16_t) -- y-coordinate of the star
        # a2 = color (uint16_t) -- color of the star
        
        la t1, skyline_star_cnt            # Load the address of skyline_star_cnt
        lh t2, 0(t1)                       # Load current star count
        la t3, MAX_STARS                   # Load the address of the MAX_STARS constant
        lw t3, 0(t3)                       # Load the value 1000 from MAX_STARS
        bge t2, t3, add_star_exit          # If star count >= max, exit

        slli t2, t2, SHIFT_MULTIPLIER      # Multiply star count by 8 (size of each star entry is 8 bytes)
        la t3, skyline_stars               # Load base address of skyline_stars array
        add t3, t3, t2                     # Calculate address of the next available star slot

        sh a0, 0(t3)                       # Store x-coordinate in the array
        sh a1, 2(t3)                       # Store y-coordinate in the array
        sh a2, 6(t3)                       # Store color in the array

        lh t2, 0(t1)                       # Reload star count
        addi t2, t2, 1                     # Increment star count
        sh t2, 0(t1)                       # Store updated star count

add_star_exit:
        ret

# ------------------ remove_star ------------------
# - search for the star of the provided x and y coordinate in the array and remove it accordingly
# - update the total star count as well after removing and adding stars
        .global remove_star
        .type   remove_star, @function

remove_star:
        # a0: x (uint16_t)
        # a1: y (uint16_t)

        # Load skyline_star_cnt into t0 (N)
        la      t6, skyline_star_cnt       # t6 = address of skyline_star_cnt
        lhu     t0, 0(t6)                  # t0 = N (number of stars)

        # Initialize index i to 0
        li      t1, 0                      # t1 = i = 0

loop_start:
        # Check if i >= N
        bge     t1, t0, remove_exit        # If i >= N, exit (star not found)

        # Compute address of skyline_stars[i]
        la      t2, skyline_stars          # t2 = base address of skyline_stars
        slli    t5, t1, SHIFT_MULTIPLIER   # t5 = i * 8 (size of struct skyline_star)
        add     t2, t2, t5                 # t2 = address of skyline_stars[i]

        # Load x and y
        lhu     t3, 0(t2)                  # t3 = skyline_stars[i].x
        lhu     t4, 2(t2)                  # t4 = skyline_stars[i].y

        # Compare x and y with input values
        bne     t3, a0, next_star          # If x[i] != x, check next star
        bne     t4, a1, next_star          # If y[i] != y, check next star

        # Found the star at index i - Decrease N (number of stars)
        addi    t0, t0, -1                 # t0 = t0 - 1

        # Update skyline_star_cnt
        sh      t0, 0(t6)                  # skyline_star_cnt = t0

        # Check if i < N (need to move the last star)
        blt     t1, t0, copy_last_star

        # If i == N (after decrement), removed the last star; nothing to copy
        ret

copy_last_star:
        # Copy last star (index N) to position i
        # Compute address of skyline_stars[N]
        la      t5, skyline_stars          # t5 = base address of skyline_stars
        slli    t4, t0, SHIFT_MULTIPLIER   # t4 = N * 8
        add     t5, t5, t4                 # t5 = address of skyline_stars[N]

        # Copy 8 bytes from t5 to t2 (from last star to position i)
        # Copy first 4 bytes
        lw      t3, 0(t5)                  # t3 = [t5]
        sw      t3, 0(t2)                  # [t2] = t3

        # Copy next 4 bytes
        lw      t4, 4(t5)                  # t4 = [t5 + 4]
        sw      t4, 4(t2)                  # [t2 + 4] = t4

        ret

next_star:
        addi    t1, t1, 1                  # i = i + 1
        j       loop_start

remove_exit:
        ret

# ------------------ draw_star ------------------
# - draw star given a pointer to the frame buffer and the star struct itself
# - draw on frame buffer accordingly properly
        .global draw_star
        .type   draw_star, @function

draw_star:
        # Arguments:
        # a0 = fbuf pointer (uint16_t *) -- pointer to the frame buffer
        # a1 = star pointer (const struct skyline_star *) -- pointer to the star struct

        # Load x, y, color from the star struct
        lhu     t0, 0(a1)        # t0 = x (uint16_t)
        lhu     t1, 2(a1)        # t1 = y (uint16_t)
        lhu     t2, 6(a1)        # t2 = color (uint16_t)

        # Compute pixel index: index = y * 640 + x
        slli    t3, t1, SHIFT_LEFT_9  # t3 = y << 9 (y * 512)
        slli    t4, t1, SHIFT_LEFT_7  # t4 = y << 7 (y * 128)
        add     t3, t3, t4            # t3 = t3 + t4 (t3 = y * 640)

        # Add x to get the pixel index
        add     t3, t3, t0            # t3 = t3 + x

        # Compute byte address: address = fbuf + (pixel index * 2)
        slli    t3, t3, 1             # t3 = t3 << 1 (pixel index * 2)
        add     t3, a0, t3            # t3 = fbuf + t3

        # Store color at the computed address
        sh      t2, 0(t3)

        ret

# ------------------ draw_window ------------------
# - draw window on frame buffer given the frame buffer pointer and the struct of the window to draw
# - ensure it fits within the screen bounds and not over previous windows as well
        .global draw_window
        .type   draw_window, @function

draw_window:
        # a0: fbuf pointer (uint16_t *) (frame buffer pointer)
        # a1: window pointer (const struct skyline_window *)

        # Load x and y from the struct skyline_window into temp var
        lhu     t1, 8(a1)              # t1 = original x (uint16_t), window's x-coordinate
        lhu     t2, 10(a1)             # t2 = original y (uint16_t), window's y-coordinate

        # Load window width and height
        lbu     t3, 12(a1)             # t3 = width of the window (uint8_t)
        lbu     t4, 13(a1)             # t4 = height of the window (uint8_t)

        # Load the window color
        lhu     t5, 14(a1)             # t5 = color (uint16_t), window's color

        # Initialize row counter (starting at 0)
        li      t0, 0                  # t0 = row counter (y offset)

loop_height:
        # Check if we've processed all rows
        bge     t0, t4, draw_window_exit # If row counter >= height, exit loop

        # Calculate current y position: y_pos = original y + row
        add     a2, t2, t0             # a2 = current y position (y + row)

        # Check if the y position is within screen bounds (y >= 480)
        la      t6, SCREEN_HEIGHT                # SCREEN_HEIGHT
        lw      t6, 0(t6)
        bge     a2, t6, next_row       # If y >= SCREEN_HEIGHT, skip to next row
        blt     a2, zero, next_row     # If y < 0, skip to next row

        # Initialize column counter (starting at 0)
        li      a3, 0                  # a3 = column counter (x offset)

loop_width:
        # Check if we've processed all columns in row
        bge     a3, t3, next_row       # If column counter >= width, go to next row

        # Calculate current x position: x_pos = original x + column
        add     a4, t1, a3             # a4 = current x position (x + column)

        # Check if the x position is within screen bounds (x >= 640)
        la      t6, SCREEN_WIDTH                # SCREEN_WIDTH
        lw      t6, 0(t6)
        bge     a4, t6, next_column    # If x >= SCREEN_WIDTH, skip to next column
        blt     a4, zero, next_column  # If x < 0, skip to next column

        # Calculate pixel index: index = (y_pos * SCREEN_WIDTH) + x_pos
        mul     a5, a2, t6             # a5 = y_pos * SCREEN_WIDTH
        add     a5, a5, a4             # a5 = pixel index = (y_pos * SCREEN_WIDTH) + x_pos

        # Compute the byte address in the frame buffer: fbuf + (index * 2)
        slli    a5, a5, 1              # a5 = index * 2 (since each pixel is 2 bytes)
        add     a5, a0, a5             # a5 = fbuf + (index * 2)
        sh      t5, 0(a5)              # Store the color at the calculated position

next_column:
        addi    a3, a3, 1              # Increment column counter (col = col + 1)
        blt     a3, t3, loop_width     # If col < width, continue drawing this row

next_row:
        addi    t0, t0, 1              # Increment row counter (row = row + 1)
        blt     t0, t4, loop_height    # If row < height, continue drawing the window

draw_window_exit:
        ret                            # Return when finished drawing the window


# ------------------ draw_beacon ------------------
# - draw beacon based on skyline_beacon struct containing x, y coordinates
# - use the beacon on time and period to correctly display the beacon as well
        .global draw_beacon
        .type   draw_beacon, @function

draw_beacon:
        # a0 = fbuf (pointer to frame buffer)
        # a1 = t (elapsed time in ticks)
        # a2 = bcn (pointer to struct skyline_beacon)

        # Load beacon's period and ontime from the structure
        lhu     t1, 14(a2)          # t1 = bcn->period (16-bit, load from offset 14)
        lhu     t2, 16(a2)          # t2 = bcn->ontime (16-bit, load from offset 16)
        remu    t0, a1, t1          # t0 = t % period

        # Check if the beacon is on (t % period < ontime)
        bge     t0, t2, draw_beacon_exit        # If t % period >= ontime, exit (beacon is off)

        # Load beacon's x and y coordinates (16-bit values)
        lhu     t3, 8(a2)           # t3 = bcn->x (16-bit, load from offset 8)
        lhu     t4, 10(a2)          # t4 = bcn->y (16-bit, load from offset 10)
        lbu     t5, 12(a2)          # t5 = bcn->dia (8-bit, load from offset 12)
        ld      t6, 0(a2)

        # Iterate over the square rows (starting from y coordinate)
        li      t1, 0               # t1 = row counter (start at 0)

draw_rows_loop:
        bge     t1, t5, draw_beacon_exit        # If row counter >= diameter, exit (finish drawing)

        # Calculate the current y position for this row
        add     a5, t4, t1          # a5 = y + row_offset

        # Load SCREEN_HEIGHT only when necessary
        la      a6, SCREEN_HEIGHT             # a6 = SCREEN_HEIGHT (480)
        lw      a6, 0(a6)
        bge     a5, a6, draw_beacon_exit        # If y >= SCREEN_HEIGHT, exit
        blt     a5, zero, draw_beacon_exit      # If y < 0, exit

        # Iterate over the square columns (width = diameter)
        li      t0, 0               # t0 = column counter (start at 0)

draw_columns_loop:
        bge     t0, t5, next_row_label  # If column counter >= diameter, move to next row

        # Calculate the current x position for this column
        add     a6, t3, t0          # a6 = x + column_offset

        # Load SCREEN_WIDTH only when necessary
        la      a7, SCREEN_WIDTH             # a7 = SCREEN_WIDTH (640)
        lw      a7, 0(a7)
        bge     a6, a7, skip_column # If x >= SCREEN_WIDTH, skip to next column
        blt     a6, zero, skip_column # If x < 0, skip to next column

        # Compute pixel index: index = (y_pos * SCREEN_WIDTH) + x_pos
        mul     a7, a5, a7          # a7 = y_pos * SCREEN_WIDTH
        add     a7, a7, a6          # a7 = pixel index = (y_pos * SCREEN_WIDTH) + x_pos

        # Compute the byte address in the frame buffer: fbuf + (index * 2)
        slli    a7, a7, 1           # a7 = index * 2 (since each pixel is 2 bytes)
        add     a7, a0, a7          # a7 = fbuf + (index * 2)

        mul     a4, t1, t5          # a4 = row_offset * dia
        add     a4, a4, t0          # a4 = row_offset * dia + column_offset
        slli    a4, a4, 1           # *2
        add     a4, t6, a4          # img + pixel_offset

        lhu     a3, 0(a4)           # load pixel color

        sh      a3, 0(a7)           # store on frame buffer

skip_column:
        addi    t0, t0, 1                       # Increment column counter
        blt     t0, t5, draw_columns_loop       # Continue drawing the next column

next_row_label:
        addi    t1, t1, 1                       # Increment row counter
        blt     t1, t5, draw_rows_loop          # Continue drawing the next row

draw_beacon_exit:
        ret                                     # Return when done

# ------------------ add_window ------------------
# - add window to linked list based on the arguments provided including the x, y, width, height
# - and also the color of the window
.global add_window
.type add_window, @function

add_window:
        # Arguments:
        # a0 = x (uint16_t) -- x-coordinate of the top-left corner of the window
        # a1 = y (uint16_t) -- y-coordinate of the top-left corner of the window
        # a2 = w (uint8_t)  -- width of the window
        # a3 = h (uint8_t)  -- height of the window
        # a4 = color (uint16_t) -- color of the window

        # Save ra and temporary registers (t0-t4) before calling malloc
        addi sp, sp, -MALLOC_SPACE      # Allocate space for ra and temporary registers
        sd ra, 0(sp)                  # Save return address (ra) on the stack

        # Store arguments into temporary registers
        mv t0, a0                      # Save x-coordinate into t0
        mv t1, a1                      # Save y-coordinate into t1
        mv t2, a2                      # Save width into t2
        mv t3, a3                      # Save height into t3
        mv t4, a4                      # Save color into t4

        sh t0, 8(sp)                   # Save temporary register t0
        sh t1, 10(sp)                   # Save temporary register t1
        sb t2, 12(sp)                   # Save temporary register t2
        sb t3, 13(sp)                  # Save temporary register t3
        sh t4, 14(sp)                  # Save temporary register t4

        # Call malloc to allocate memory for the window struct
        li a0, WINDOW_STRUCT_SIZE       # Load the size of the window struct into a0
        call malloc                      # Execute jump-and-link to malloc
        beqz a0, add_window_exit        # If malloc fails (a0 == NULL), skip to exit

        lhu t0, 8(sp)                   # Restore temporary register t0
        lhu t1, 10(sp)                   # Restore temporary register t1
        lbu t2, 12(sp)                   # Restore temporary register t2
        lbu t3, 13(sp)                  # Restore temporary register t3
        lhu t4, 14(sp)                  # Restore temporary register t4

        # Store the arguments (x, y, w, h, color) at the correct offsets
        sh t0, 8(a0)                    # Store x-coordinate at offset 8
        sh t1, 10(a0)                   # Store y-coordinate at offset 10
        sb t2, 12(a0)                   # Store width at offset 12
        sb t3, 13(a0)                   # Store height at offset 13
        sh t4, 14(a0)                   # Store color at offset 14

        # Add the new window to the linked list
        la t5, skyline_win_list          # Load address of the window list head
        lwu t6, 0(t5)                   # Load the current head of the list (pointer to next window)
        sd t6, 0(a0)                    # Set the next pointer (at offset 0) of the new window
        sd a0, 0(t5)                    # Update the list head to point to the new window

add_window_exit:
        # Restore ra and the temporary registers, then return
        ld ra, 0(sp)                  # Restore return address (ra)
        addi sp, sp, MALLOC_SPACE                # Restore the stack pointer
        ret                           # Return to the caller

# ------------------ remove_window ------------------
# - remove window from linked list based on provided x and y coordinates
# - traverse the linked list and free that element once identified
.global remove_window
.type remove_window, @function

remove_window:
    # Prologue: Save ra and temporary registers (t0-t2) before proceeding
    addi    sp, sp, -STACK_SPACE       # Allocate space for ra and temporary registers
    sd      ra, 0(sp)                 # Save return address (ra) on the stack

    # Step 1: Load the head of the window list into t6
    la      t6, skyline_win_list       # t6 = &skyline_win_list (pointer to the list head)
    lwu     t0, 0(t6)                  # t0 = current window (pointer to the first node)

    # Step 2: If the list is empty, exit immediately
    beqz    t0, remove_window_exit     # If t0 is NULL, exit (list is empty)

    # Check if list has single window and act accordingly
    lwu     t5, 0(t0)
    beqz    t5, single_window_case

    # Initialize t2 as the previous window (NULL at the start)
    li      t2, 0                      # t2 = previous window (NULL initially)

    # Step 3: Traverse the list and find the window with matching (x, y)
find_window_loop:
    beqz    t0, remove_window_exit     # If current window is NULL, exit (no match found)

    # Load x and y from the current window (proper dereferencing using t0)
    lhu     t3, 8(t0)                  # t3 = current window's x-coordinate (offset 2 from t0)
    lhu     t4, 10(t0)                  # t4 = current window's y-coordinate (offset 4 from t0)

    # Check if x and y match the given values
    bne     t3, a0, next_window        # If x doesn't match, check the next window
    bne     t4, a1, next_window        # If y doesn't match, check the next window

    # Step 4: Found the window, now unlink it from the list
    lwu     t5, 0(t0)                  # t5 = current->next (next window is stored at offset 0)

    # Step 5: If previous window is NULL, update head to next (removing the head)
    beqz    t2, update_head            # If previous is NULL, remove the head of the list

    # Update previous->next to current->next (unlink the current window)
    sh      t5, 0(t2)                  # previous->next = current->next
    j       free_window                # Free the current window and exit

    # Step 6: Removing the head window (set head to next using t6)
update_head:
    sh      t5, 0(t6)                  # Update head of the list to point to current->next
    j       free_window                # Proceed to free the memory

single_window_case:
        li      t5, 0
        sh      t5, 0(t6)
        j       free_window

    # Step 7: Free the current window properly
free_window:
    mv      a0, t0                     # Set a0 to current window pointer (for freeing)
    call    free                       # Call free and properly restore the return address
    j       remove_window_exit         # Exit the function

    # Move to the next window in the list
next_window:
    mv      t2, t0                     # Move previous (t2) to current (t0)
    lwu     t0, 0(t0)                  # Move to the next window (current = current->next)
    j       find_window_loop           # Repeat the loop

    # Exit the function (nothing to remove or after removing)
remove_window_exit:
    # Epilogue: Restore ra and temporary registers, then return
    ld     ra, 0(sp)                 # Restore return address (ra)
    addi    sp, sp, STACK_SPACE        # Restore the stack pointer
    ret                         # Return to the caller

.end
