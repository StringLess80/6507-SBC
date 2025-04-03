;----------------------------------------------------
; Tic-Tac-Toe (Tris) for 6502 via Serial Terminal
; Author: Alessandro Iglina
; Date: 2025-04-01 / Revision 2025-04-03 (Added subroutine comments)
;
; Load Address: $0500
;----------------------------------------------------

; --- Configuration ---
PUTC            = $1811             ; Address of CHROUT (Print Character)
GETC            = $1800             ; Address of CHRIN (Read Character)
                                    ; **ASSUMPTION: Routine at GETC is non-blocking, echoes,**
                                    ; **returns char in A & SEC on success, CLC if no key.**

; --- Zero Page Usage ---
ZP_PTR          = $FB               ; Low byte for string pointer
ZP_PTR_HI       = $FC               ; High byte for string pointer
ZP_TEMP1        = $FD               ; General temporary storage (e.g., saving winner)
ZP_CURPLAYER    = $FE               ; Current player ('X' or 'O') - Optimized in ZP

; --- Constants ---
PLAYER_X        = $58               ; ASCII 'X'
PLAYER_O        = $4F               ; ASCII 'O'
FLIP_MASK       = $17               ; Value for PLAYER_X XOR PLAYER_O ($58 EOR $4F)
SPACE           = $20               ; ASCII ' ' (space)
CR              = $0D               ; Carriage Return
LF              = $0A               ; Line Feed


                * = $0500

START:          JSR INIT_GAME       ; Initialize the game state (board, player)

; --- Main Game Loop ---
GAME_LOOP:      JSR PRINT_BOARD     ; Display the current game board
                JSR PRINT_PROMPT    ; Display the prompt for the current player

WAIT_FOR_INPUT: JSR GET_MOVE        ; Get a valid move ('1'-'9') from the player. Loops internally
                                    ; until valid input is received. Returns 0-8 in A.

                ; A contains a valid board index 0-8 from GET_MOVE
                TAX                 ; Use the index in X for addressing
                LDA BOARD,X         ; Check if the target square on the board is empty
                CMP #SPACE
                BNE SQUARE_TAKEN    ; If not empty, jump to handle occupied square error

                ; Square is free, proceed with the move
                TXA                 ; Restore index from X back to A
                JSR UPDATE_BOARD    ; Place the current player's mark on the board

                ; Check for game end conditions
                JSR CHECK_WIN       ; Check if the current move resulted in a win
                CMP #SPACE          ; Did CHECK_WIN return a player mark (X/O)?
                BNE GAME_OVER_WIN   ; If yes (not SPACE), jump to handle win

                JSR CHECK_DRAW      ; Check if the board is full (a draw)
                BCS GAME_OVER_DRAW  ; If Carry is set (draw), jump to handle draw

                ; Game continues: No win, no draw
                JSR SWITCH_PLAYER   ; Change the current player (X -> O or O -> X)
                JMP GAME_LOOP       ; Jump back to start the next turn

SQUARE_TAKEN:   ; Handle error: Player tried to select an occupied square
                ; GETC already echoed the invalid number pressed by the player.
                JSR PRINT_NEWLINE   ; Print a newline for better formatting
                LDX #<STR_TAKEN     ; Load address of "Square already occupied!" message
                LDY #>STR_TAKEN
                JSR PRINT_STRING    ; Print the error message
                JSR PRINT_NEWLINE   ; Print another newline
                JMP GAME_LOOP       ; Go back to the start of the loop (reprint board/prompt)

GAME_OVER_WIN:  ; Handle game end: A player has won
                STA ZP_TEMP1        ; Save the winning player's mark (X/O from CHECK_WIN)
                JSR PRINT_BOARD     ; Show the final board state
                JSR PRINT_NEWLINE
                LDX #<STR_PLAYER    ; Print "Player "
                LDY #>STR_PLAYER
                JSR PRINT_STRING
                LDA ZP_TEMP1        ; Retrieve the winner's mark
                JSR PUTC            ; Print the mark (X or O)
                LDA #' '            ; Print a space
                JSR PUTC
                LDX #<STR_WINS      ; Print " Wins!"
                LDY #>STR_WINS
                JSR PRINT_STRING
                JMP END_GAME        ; Jump to common game end sequence

GAME_OVER_DRAW: ; Handle game end: The game is a draw (board full, no winner)
                JSR PRINT_BOARD     ; Show the final board state
                LDX #<STR_DRAW      ; Load address of "It's a draw!" message
                LDY #>STR_DRAW
                JSR PRINT_STRING    ; Print the draw message
                ; Fall through to END_GAME

END_GAME:       ; Common actions after game ends (win or draw)
                JSR PRINT_NEWLINE   ; Print a couple of newlines for spacing
                JSR PRINT_NEWLINE
HALT:           JMP $1EFD           ; Jump to the monitor (e.g., Wozmon)

; Initialize the game state.
INIT_GAME:
                LDX #8              ; Initialize loop counter for board positions (8 down to 0)
INIT_LOOP:      LDA #SPACE          ; Load the SPACE character
                STA BOARD,X         ; Store SPACE in the current board position
                DEX                 ; Move to the previous board position
                BPL INIT_LOOP       ; Loop until all 9 positions (0-8) are filled
                LDA #PLAYER_X       ; Set the starting player to 'X'
                STA ZP_CURPLAYER    ; Store 'X' in the zero page variable
                RTS                 ; Return from subroutine

; Displays the Tic-Tac-Toe board on the terminal.
PRINT_BOARD:
                JSR PRINT_NEWLINE   ; Start with a blank line
                LDX #0              ; Set offset for the first row (board index 0)
                JSR PRINT_ROW       ; Print the first row (indices 0, 1, 2)
                JSR PRINT_SEP       ; Print the horizontal separator "---+---+---"
                LDX #3              ; Set offset for the second row (board index 3)
                JSR PRINT_ROW       ; Print the second row (indices 3, 4, 5)
                JSR PRINT_SEP       ; Print the horizontal separator
                LDX #6              ; Set offset for the third row (board index 6)
                JSR PRINT_ROW       ; Print the third row (indices 6, 7, 8)
                JSR PRINT_NEWLINE   ; Add an extra blank line after the board
                RTS                 ; Return from subroutine

; Helper routine to print one row of the board.
PRINT_ROW:
                LDA BOARD+0,X       ; Load character from first square of the row
                JSR PUTC            ; Print it
                LDA #' '            ; Load SPACE for separator
                JSR PUTC
                LDA #'|'            ; Load '|' for separator
                JSR PUTC
                LDA #' '            ; Load SPACE for separator
                JSR PUTC
                LDA BOARD+1,X       ; Load character from second square of the row
                JSR PUTC            ; Print it
                LDA #' '            ; Load SPACE for separator
                JSR PUTC
                LDA #'|'            ; Load '|' for separator
                JSR PUTC
                LDA #' '            ; Load SPACE for separator
                JSR PUTC
                LDA BOARD+2,X       ; Load character from third square of the row
                JSR PUTC            ; Print it
                JSR PRINT_NEWLINE   ; Print CR/LF to end the row
                RTS                 ; Return from subroutine


;----------------------------------------------------
; Helper routine to print the board's horizontal separator line.
; Prints the string "---+---+---" followed by a newline.
;----------------------------------------------------
PRINT_SEP:
                LDX #<STR_SEPARATOR ; Load the address of the separator string
                LDY #>STR_SEPARATOR
                JSR PRINT_STRING    ; Print the "---+---+---" string
                JSR PRINT_NEWLINE   ; Print CR/LF after the separator
                RTS                 ; Return from subroutine

; Display the prompt asking the current player for their move.
PRINT_PROMPT:
                LDX #<STR_PLAYER    ; Load address of "Player " string
                LDY #>STR_PLAYER
                JSR PRINT_STRING    ; Print "Player "
                LDA ZP_CURPLAYER    ; Load the current player's mark from zero page
                JSR PUTC            ; Print the mark ('X' or 'O')
                LDX #<STR_TURN      ; Load address of ", enter move (1-9): " string
                LDY #>STR_TURN
                JSR PRINT_STRING    ; Print the rest of the prompt
                RTS                 ; Return from subroutine


;----------------------------------------------------
; Get a valid move ('1'-'9') from the player via the terminal.
; Reads characters from the input routine (GETC), ignores control
; characters (< SPACE), validates input is '1' through '9',
; prints an error message for other invalid characters, and loops
; until a valid digit is entered. Converts the valid digit to a
; board index (0-8).
;----------------------------------------------------
GET_MOVE:
INPUT_LOOP:     JSR GETC            ; Call input routine at $1800 (assumed to echo)
                BCC INPUT_LOOP      ; Loop if GETC indicates no character ready (Carry Clear)

                ; Character received in A (Carry is Set), GETC supposedly echoed it.

                ; Ignore any non-printing control characters (ASCII < $20)
                CMP #SPACE          ; Compare with ASCII SPACE ($20)
                BCC INPUT_LOOP      ; If A < SPACE, it's a control char (NULL, CR, LF, etc.) -> ignore and get next

                ; Character is printable (A >= SPACE). Check if it's '1' through '9'.
                CMP #$31            ; Compare with ASCII '1'
                BCC HANDLE_INVALID_TYPE ; If A < '1' (e.g., '0', SPACE, symbols), it's invalid

                CMP #$3A            ; Compare with ASCII ':' (which is '9' + 1)
                BCS HANDLE_INVALID_TYPE ; If A >= ':' (e.g., ':', ';', letters), it's invalid

                ; Character is valid ('1' through '9').
VALID_CHAR:     SEC                 ; Ensure Carry is set for subtraction (though GETC likely set it)
                SBC #$31            ; Convert ASCII '1'..'9' to numerical index 0..8
                RTS                 ; Return with the valid index 0-8 in A

HANDLE_INVALID_TYPE:
                ; Handle invalid printable characters (not '1'-'9').
                ; GETC already echoed the invalid character.
                JSR PRINT_NEWLINE   ; Print a newline for formatting after the bad echo
                LDX #<STR_INVALID_TYPE ; Load address of "Invalid input..." message
                LDY #>STR_INVALID_TYPE
                JSR PRINT_STRING       ; Print the error message
                JSR PRINT_NEWLINE      ; Print another newline
                JMP INPUT_LOOP         ; Jump back to wait for more input (loop within GET_MOVE)


;----------------------------------------------------
; Place the current player's mark on the board.
; Writes the character stored in ZP_CURPLAYER to the BOARD location
; indicated by the index in the Accumulator.
;----------------------------------------------------
UPDATE_BOARD:
                TAX                 ; Transfer the index from A to X for indexed addressing
                LDA ZP_CURPLAYER    ; Load the current player's mark ('X' or 'O')
                STA BOARD,X         ; Store the mark onto the board at the specified index
                RTS                 ; Return from subroutine


;----------------------------------------------------
; Check if any player has won the game.
; Examines all rows, columns, and diagonals on the BOARD for
; three identical marks (X or O, not SPACE).
;----------------------------------------------------
CHECK_WIN:
                LDX #0              ; Initialize index for checking rows (start at index 0)
CHECK_ROW:      ; Check row starting at BOARD+0,X / BOARD+1,X / BOARD+2,X
                LDA BOARD+0,X       ; Load the first square of the current row
                CMP #SPACE          ; Is the first square empty?
                BEQ CHECK_NEXT_ROW  ; If yes, this row cannot be a winning row, skip to next
                CMP BOARD+1,X       ; Compare first square with the second square
                BNE CHECK_NEXT_ROW  ; If not equal, not a winning row, skip to next
                CMP BOARD+2,X       ; Compare first square with the third square
                BNE CHECK_NEXT_ROW  ; If not equal, not a winning row, skip to next
                ; If we reach here, all three squares match and are not SPACE.
                RTS                 ; Return; A already holds the winning player's mark

CHECK_NEXT_ROW: TXA                 ; Move current row offset from X to A
                CLC                 ; Clear Carry for addition
                ADC #3              ; Add 3 to move to the next row's starting index (0 -> 3 -> 6)
                TAX                 ; Put the new offset back in X
                CPX #9              ; Have we checked offsets 0, 3, and 6 (i.e., is new offset 9)?
                BCC CHECK_ROW       ; If X < 9, loop back to check the next row

                LDX #0              ; Initialize index for checking columns (start at index 0)
CHECK_COL:      ; Check column BOARD+0,X / BOARD+3,X / BOARD+6,X
                LDA BOARD+0,X       ; Load the top square of the current column
                CMP #SPACE          ; Is the square empty?
                BEQ CHECK_NEXT_COL  ; If yes, this column cannot be a winning one, skip to next
                CMP BOARD+3,X       ; Compare top square with the middle square
                BNE CHECK_NEXT_COL  ; If not equal, not a winning column, skip to next
                CMP BOARD+6,X       ; Compare top square with the bottom square
                BNE CHECK_NEXT_COL  ; If not equal, not a winning column, skip to next
                ; If we reach here, all three squares match and are not SPACE.
                RTS                 ; Return; A already holds the winning player's mark

CHECK_NEXT_COL: INX                 ; Move to the next column index (0 -> 1 -> 2)
                CPX #3              ; Have we checked columns 0, 1, and 2 (i.e., is new index 3)?
                BCC CHECK_COL       ; If X < 3, loop back to check the next column

                ; Check Diagonals
                LDA BOARD+0         ; Load top-left square (for diagonal 0, 4, 8)
                CMP #SPACE
                BEQ CHK_D2          ; If empty, this diagonal cannot win, check the other
                CMP BOARD+4         ; Compare with middle square
                BNE CHK_D2          ; If not equal, check the other diagonal
                CMP BOARD+8         ; Compare with bottom-right square
                BNE CHK_D2          ; If not equal, check the other diagonal
                RTS                 ; Win found on first diagonal; A has the mark

CHK_D2:         LDA BOARD+2         ; Load top-right square (for diagonal 2, 4, 6)
                CMP #SPACE
                BEQ NO_WIN          ; If empty, this diagonal cannot win
                CMP BOARD+4         ; Compare with middle square
                BNE NO_WIN          ; If not equal, no win
                CMP BOARD+6         ; Compare with bottom-left square
                BNE NO_WIN          ; If not equal, no win
                RTS                 ; Win found on second diagonal; A has the mark

NO_WIN:         LDA #SPACE          ; No win found on rows, columns, or diagonals
                RTS                 ; Return SPACE in A


;----------------------------------------------------
; Check if game is a draw (board full, no winner).
; Scans the entire BOARD for any remaining SPACE characters.
; Assumes CHECK_WIN was called first and returned SPACE.
;----------------------------------------------------
CHECK_DRAW:
                LDX #8              ; Initialize index to check board from end (8 down to 0)
CHECK_DRAW_LOOP:LDA BOARD,X         ; Load character from current board position
                CMP #SPACE          ; Is it a SPACE?
                BEQ NOT_DRAW        ; If yes, the board is not full -> Branch to exit (not a draw)
                DEX                 ; Move to the previous board position
                BPL CHECK_DRAW_LOOP ; Loop if index is still >= 0
                ; If loop completes without finding a SPACE, the board is full.
                SEC                 ; Set Carry flag to indicate a draw condition
                RTS
NOT_DRAW:       CLC                 ; Clear Carry flag to indicate not a draw (found a SPACE)
                RTS


;----------------------------------------------------
; Toggle current player between 'X' and 'O'.
; Reads the current player mark from ZP_CURPLAYER, performs an
; Exclusive OR (EOR) with FLIP_MASK to change it to the other
; player's mark, and stores it back.
;----------------------------------------------------
SWITCH_PLAYER:  LDA ZP_CURPLAYER    ; Load the current player's mark
                EOR #FLIP_MASK      ; Toggle between 'X' ($58) and 'O' ($4F) using XOR mask $17
                STA ZP_CURPLAYER    ; Store the new player's mark back to zero page
                RTS                 ; Return from subroutine


;----------------------------------------------------
; PRINT_STRING: Prints a null-terminated string to the terminal.
; Purpose: Iterates through memory starting at the address specified by
;          (ZP_PTR_HI, ZP_PTR) and prints each character using PUTC until
;          a null byte ($00) is encountered.
; Input:   X = Low byte of string start address.
;          Y = High byte of string start address.
; Output:  Prints string characters to terminal via PUTC.
; Modifies: ZP_PTR, ZP_PTR_HI, Calls PUTC.
; Registers Used: A, Y, (ZP_PTR, ZP_PTR_HI implicitly)
; Preserves: X
; Notes:   Assumes strings are less than 256 bytes due to 8-bit index (Y).
;----------------------------------------------------
PRINT_STRING:   STX ZP_PTR          ; Store low byte of address in zero page pointer
                STY ZP_PTR_HI       ; Store high byte of address in zero page pointer
                LDY #0              ; Initialize index Y to 0 for indirect indexed addressing
PRINT_LOOP:     LDA (ZP_PTR),Y      ; Load character using (ZP_PTR) as base address + Y offset
                BEQ PRINT_DONE      ; If character is $00 (null terminator), we are done
                JSR PUTC            ; Print the character
                INY                 ; Increment the index Y
                BNE PRINT_LOOP      ; Branch back to print next character (implicitly checks Y != 0)
                                    ; Assumes string length < 256 bytes, otherwise Y wraps around.
PRINT_DONE:     RTS                 ; Return from subroutine


;----------------------------------------------------
; Print Carriage Return (CR) and Line Feed (LF).
;----------------------------------------------------
PRINT_NEWLINE:  LDA #CR             ; Load Carriage Return character ($0D)
                JSR PUTC            ; Print CR
                LDA #LF             ; Load Line Feed character ($0A)
                JSR PUTC            ; Print LF
                RTS                 ; Return from subroutine


; --- Data ---
BOARD:          .DS 9                   ; Reserve 9 bytes for the board

; --- Message Strings (Zero/Null Terminated ASCII) ---
STR_PLAYER:    .ASCII "Player ", 0
STR_TURN:      .ASCII ", enter move (1-9): ", 0
STR_SEPARATOR: .ASCII "---+---+---", 0
STR_WINS:      .ASCII " Wins!", 0
STR_DRAW:      .ASCII "It's a draw!", 0
STR_TAKEN:     .ASCII "Square already occupied!", 0
STR_INVALID_TYPE:.ASCII "Invalid input. Please use 1-9.", 0
