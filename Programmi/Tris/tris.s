;----------------------------------------------------
; 6502 Tic-Tac-Toe for Serial Terminal
; By: Claude 4 / Anthropic (via User Request)
; Date: 2023-10-27 (Revised for VASM Oldstyle Syntax)
;
; Load Address: $0500
; Char Print Routine (CHROUT): $1811 (expects char in A)
; Char Input Routine (CHRIN):  $1800 (non-blocking, echoes, uses Carry)
;----------------------------------------------------

; --- Configuration ---
PUTC       = $1811  ; Address of CHROUT
GETC       = $1800  ; Address of CHRIN

; --- Zero Page Usage ---
ZP_PTR     = $FB    ; Low byte for string pointer
ZP_PTR_HI  = $FC    ; High byte for string pointer
TEMP1      = $FD    ; General purpose temp storage
; TEMP2      = $FE    ; (Unused)

; --- Constants ---
PLAYER_X   = $58    ; ASCII 'X'
PLAYER_O   = $4F    ; ASCII 'O'
SPACE      = $20    ; ASCII ' '
CR         = $0D    ; Carriage Return
LF         = $0A    ; Line Feed

; --- Program Start ---
           * = $0500

START:
    JSR INIT_GAME

GAME_LOOP:
    JSR PRINT_BOARD
    JSR PRINT_PROMPT
GET_INPUT_LOOP:
    JSR GET_MOVE       ; Waits for input using CHRIN loop.
                       ; Returns index 0-8 in A if valid '1'-'9',
                       ; or $FF otherwise. CHRIN handles echo.
    CMP #$FF           ; Check if GET_MOVE flagged invalid type
    BEQ GET_INPUT_LOOP ; If $FF, just loop back to get another character

    ; A contains valid index 0-8 from a valid input character ('1'-'9')
    TAX                ; Use index in X
    LDA BOARD,X
    CMP #SPACE         ; Check if square is empty (Using SPACE constant is OK)
    BNE SQUARE_TAKEN

    ; Valid move and empty square, index is in X
    TXA                ; Put index back in A for UPDATE_BOARD
    JSR UPDATE_BOARD   ; Place the mark

    ; Check for win
    JSR CHECK_WIN      ; Returns winner (X/O) in A, or SPACE if no win yet
    CMP #SPACE
    BNE GAME_OVER_WIN

    ; Check for draw
    JSR CHECK_DRAW     ; Sets Carry if draw, Clears Carry if not
    BCS GAME_OVER_DRAW

    ; No win, no draw - switch player and continue
    JSR SWITCH_PLAYER
    JMP GAME_LOOP

SQUARE_TAKEN:
    JSR PRINT_NEWLINE ; Add newline after the echoed invalid position char
    LDX #<STR_TAKEN
    LDY #>STR_TAKEN
    JSR PRINT_STRING
    JSR PRINT_NEWLINE
    JMP GAME_LOOP

GAME_OVER_WIN:
    STA TEMP1          ; Store winner (contains $58 or $4F)
    JSR PRINT_BOARD    ; Show final board
    JSR PRINT_NEWLINE
    ; Print "Player X/O Wins!" using hex values
    LDA #$50           ; 'P'
    JSR PUTC
    LDA #$6C           ; 'l'
    JSR PUTC
    LDA #$61           ; 'a'
    JSR PUTC
    LDA #$79           ; 'y'
    JSR PUTC
    LDA #$65           ; 'e'
    JSR PUTC
    LDA #$72           ; 'r'
    JSR PUTC
    LDA #$20           ; ' '
    JSR PUTC
    LDA TEMP1          ; Get the winner's character ($58 or $4F)
    JSR PUTC
    LDA #$20           ; ' '
    JSR PUTC
    LDX #<STR_WINS     ; Print " Wins!" (string uses .BYTE, OK)
    LDY #>STR_WINS
    JSR PRINT_STRING
    JMP END_GAME

GAME_OVER_DRAW:
    JSR PRINT_BOARD    ; Show final board
    LDX #<STR_DRAW     ; Print "It's a draw!" (string uses .BYTE, OK)
    LDY #>STR_DRAW
    JSR PRINT_STRING
    ; Fall through to END_GAME

END_GAME:
    JSR PRINT_NEWLINE
    JSR PRINT_NEWLINE
HALT:
    BRK             ; Use BRK or JMP HALT for a simple stop
    ; JMP HALT

;----------------------------------------------------
; Subroutine: INIT_GAME
;----------------------------------------------------
INIT_GAME:
    LDX #8
INIT_LOOP:
    LDA #SPACE         ; Use constant SPACE = $20
    STA BOARD,X
    DEX
    BPL INIT_LOOP
    LDA #PLAYER_X      ; Use constant PLAYER_X = $58
    STA CURPLAYER
    RTS

;----------------------------------------------------
; Subroutine: PRINT_BOARD
;----------------------------------------------------
PRINT_BOARD:
    JSR PRINT_NEWLINE
    ; Row 0
    LDA BOARD+0
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA #$7C  ; '|'
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA BOARD+1
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA #$7C  ; '|'
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA BOARD+2
    JSR PUTC
    JSR PRINT_NEWLINE
    ; Separator
    LDX #<STR_SEPARATOR
    LDY #>STR_SEPARATOR
    JSR PRINT_STRING
    JSR PRINT_NEWLINE
    ; Row 1
    LDA BOARD+3
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA #$7C  ; '|'
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA BOARD+4
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA #$7C  ; '|'
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA BOARD+5
    JSR PUTC
    JSR PRINT_NEWLINE
    ; Separator
    LDX #<STR_SEPARATOR
    LDY #>STR_SEPARATOR
    JSR PRINT_STRING
    JSR PRINT_NEWLINE
    ; Row 2
    LDA BOARD+6
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA #$7C  ; '|'
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA BOARD+7
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA #$7C  ; '|'
    JSR PUTC
    LDA #$20  ; ' '
    JSR PUTC
    LDA BOARD+8
    JSR PUTC
    JSR PRINT_NEWLINE
    JSR PRINT_NEWLINE
    RTS

;----------------------------------------------------
; Subroutine: PRINT_PROMPT
;----------------------------------------------------
PRINT_PROMPT:
    LDX #<STR_PLAYER
    LDY #>STR_PLAYER
    JSR PRINT_STRING
    LDA CURPLAYER
    JSR PUTC
    LDX #<STR_TURN
    LDY #>STR_TURN
    JSR PRINT_STRING
    RTS

;----------------------------------------------------
; Subroutine: GET_MOVE
;----------------------------------------------------
GET_MOVE:
WAIT_INPUT_LOOP:
    JSR GETC           ; Call CHRIN at $1800
    BCC WAIT_INPUT_LOOP ; Loop back if Carry Clear (no key)

    ; Character received in A, CHRIN already echoed it.
    ; Check if input is between '1' ($31) and '9' ($39)
    CMP #$31           ; Compare with ASCII '1'
    BCC INVALID_CHAR   ; Branch if < '1'
    CMP #$3A           ; Compare with ASCII '9' + 1
    BCS INVALID_CHAR   ; Branch if > '9'

    ; Convert valid ASCII '1'-'9' to index 0-8
    SEC
    SBC #$31           ; Subtract ASCII '1'
    RTS                ; Return with index in A

INVALID_CHAR:
    ; Invalid char received and echoed by CHRIN. Add newline.
    JSR PRINT_NEWLINE
    LDA #$FF           ; Load $FF to signal invalid character type
    RTS

;----------------------------------------------------
; Subroutine: UPDATE_BOARD
;----------------------------------------------------
UPDATE_BOARD:
    TAX
    LDA CURPLAYER
    STA BOARD,X
    RTS

;----------------------------------------------------
; Subroutine: CHECK_WIN
;----------------------------------------------------
CHECK_WIN:
    LDX #0
CHECK_ROW_LOOP:
    LDA BOARD+0,X
    CMP #SPACE
    BEQ NEXT_ROW
    CMP BOARD+1,X
    BNE NEXT_ROW
    CMP BOARD+2,X
    BNE NEXT_ROW
    RTS                ; Winner was already in A from LDA BOARD+0,X
NEXT_ROW:
    TXA
    CLC
    ADC #3
    TAX
    CPX #9
    BCC CHECK_ROW_LOOP

    LDX #0
CHECK_COL_LOOP:
    LDA BOARD+0,X
    CMP #SPACE
    BEQ NEXT_COL
    CMP BOARD+3,X
    BNE NEXT_COL
    CMP BOARD+6,X
    BNE NEXT_COL
    RTS                ; Winner was already in A from LDA BOARD+0,X
NEXT_COL:
    INX
    CPX #3
    BCC CHECK_COL_LOOP

    ; Diagonal 1 (0, 4, 8)
    LDA BOARD+0
    CMP #SPACE
    BEQ CHK_D2
    CMP BOARD+4
    BNE CHK_D2
    CMP BOARD+8
    BNE CHK_D2
    RTS                ; Winner was already in A from LDA BOARD+0
CHK_D2:
    ; Diagonal 2 (2, 4, 6)
    LDA BOARD+2
    CMP #SPACE
    BEQ NO_WIN
    CMP BOARD+4
    BNE NO_WIN
    CMP BOARD+6
    BNE NO_WIN
    RTS                ; Winner was already in A from LDA BOARD+2
NO_WIN:
    LDA #SPACE
    RTS

;----------------------------------------------------
; Subroutine: CHECK_DRAW
;----------------------------------------------------
CHECK_DRAW:
    LDX #8
CHECK_DRAW_LOOP:
    LDA BOARD,X
    CMP #SPACE
    BEQ NOT_DRAW
    DEX
    BPL CHECK_DRAW_LOOP
    SEC                ; Set Carry for draw
    RTS
NOT_DRAW:
    CLC                ; Clear Carry, not a draw
    RTS

;----------------------------------------------------
; Subroutine: SWITCH_PLAYER
;----------------------------------------------------
SWITCH_PLAYER:
    LDA CURPLAYER
    EOR #(PLAYER_X EOR PLAYER_O) ; Flip between X($58) and O ($4F)
    STA CURPLAYER
    RTS

;----------------------------------------------------
; Subroutine: PRINT_STRING
;----------------------------------------------------
PRINT_STRING:
    STX ZP_PTR
    STY ZP_PTR_HI
    LDY #0
PRINT_LOOP:
    LDA (ZP_PTR),Y
    BEQ PRINT_DONE
    JSR PUTC
    INY
    BNE PRINT_LOOP     ; Note: Assumes string won't cross page boundary AND Y wraps
                       ; For strings > 255 bytes or crossing page, more complex logic needed
PRINT_DONE:
    RTS

;----------------------------------------------------
; Subroutine: PRINT_NEWLINE
;----------------------------------------------------
PRINT_NEWLINE:
    LDA #CR            ; Use constant CR = $0D
    JSR PUTC
    LDA #LF            ; Use constant LF = $0A
    JSR PUTC
    RTS

;----------------------------------------------------
; Data Area
;----------------------------------------------------
CURPLAYER:  .BYTE PLAYER_X ; $58
BOARD:      .RES 9
STR_PLAYER: .BYTE $50,$6C,$61,$79,$65,$72,$20, 0 ; "Player "
STR_TURN:   .BYTE $2C,$20,$65,$6E,$74,$65,$72,$20,$6D,$6F,$76,$65,$20,$28,$31,$2D,$39,$29,$3A,$20, 0 ; ", enter move (1-9): "
STR_SEPARATOR:.BYTE $2D,$2D,$2D,$2B,$2D,$2D,$2D,$2B,$2D,$2D,$2D, 0 ; "---+---+---"
STR_WINS:   .BYTE $20,$57,$69,$6E,$73,$21, 0 ; " Wins!"
STR_DRAW:   .BYTE $49,$74,$27,$73,$20,$61,$20,$64,$72,$61,$77,$21, 0 ; "It's a draw!"
STR_TAKEN:  .BYTE $53,$71,$75,$61,$72,$65,$20,$61,$6C,$72,$65,$61,$64,$79,$20,$74,$61,$6B,$65,$6E,$21, 0 ; "Square already taken!"

; --- End of Program ---
