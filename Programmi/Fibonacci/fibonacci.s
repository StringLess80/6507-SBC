; Fibonacci Sequence Generator for 6502

; Memory Locations:
; $00: Fib1
; $01: Fib2
; $02: Temp storage for next Fibonacci number
; $03: Calculated Hundreds Digit (PRINT_NUMBER)
; $04: Calculated Tens Digit (PRINT_NUMBER)
; $05: Calculated Ones Digit (PRINT_NUMBER)
; $06: Temp storage for PRINT_NUMBER input

                ; Program Start
                .ORG $0500

                ; Initialize Fib1 and Fib2
INIT:           LDA #$01
                STA $00             ; Fib1 = 1
                LDA #$01
                STA $01             ; Fib2 = 1

LOOP:           LDA $00
                JSR PRINT_NUMBER

                LDA #$20            ; Space character for separation
                JSR $1811

                ; Calculate next Fibonacci number
                LDA $00             ; Load current Fib1
                CLC                 ; Clear carry flag before adding
                ADC $01             ; Add current Fib2, result in A, carry flag set if overflow
                STA $02             ; Store new Fibonacci number in TEMP ($02)
                BCC NO_OVERFLOW     ; Branch if carry is clear
                ; --- Overflow detected ---
                ; Last valid number calculated is still in Fib2, print it
                LDA $01         
                JSR PRINT_NUMBER
                LDA #$20            ; Print a space after the number
                JSR $1811

                ; Print the '>OVFLOW' message
                LDA #$3E            ; '>'
                JSR $1811
                LDA #$4F            ; 'O'
                JSR $1811
                LDA #$56            ; 'V'
                JSR $1811
                LDA #$46            ; 'F'
                JSR $1811
                LDA #$4C            ; 'L'
                JSR $1811
                LDA #$4F            ; 'O'
                JSR $1811
                LDA #$57            ; 'W'
                JSR $1811
                JMP $1EFD           ; Jump back to WozMon

NO_OVERFLOW:    LDA $01             ; Load current Fib2
                STA $00             ; New Fib1 = old Fib2
                LDA $02             ; Load new Fibonacci number from TEMP
                STA $01
                JMP LOOP            ; Continue loop

                ; PRINT_NUMBER subroutine - Converts 8-bit number in A to ASCII and prints
PRINT_NUMBER:   STA $06             ; Store original number into $06
                LDA #$00            ; Clear digit storage
                STA $03             ; Hundreds digit = 0
                STA $04             ; Tens digit = 0
                STA $05             ; Ones digit = 0

                ; Calculate hundreds digit
                LDA $06
HUNDREDS_LOOP:  CMP #100            ; Compare content of A with 100
                BCC TENS_LOOP       ; If A < 100, done with hundreds, goto tens
                SEC
                SBC #100            ; A = A - 100
                STA $06             ; Store modified value in $06
                INC $03             ; Increment hundreds count
                LDA $06             ; Load modified value back for next comparison
                JMP HUNDREDS_LOOP
   
TENS_LOOP:      CMP #10             ; Compare A (remainder < 100) with 10
                BCC CALC_ONES       ; If A < 10, done with tens, goto ones
                SEC
                SBC #10             ; A = A - 10
                INC $04             ; Increment tens count
                JMP TENS_LOOP

CALC_ONES:      STA $05             ; Store ones digit in $05

                ; --- Printing Logic (with leading zero suppression) ---
                LDY #$00            ; Use Y as a flag: 0=leading zeros ok, 1=non-zero digit printed

                ; Print Hundreds?
                LDA $03             ; Load hundreds digit
                CMP #$00
                BEQ SKIP_HUNDREDS   ; If zero, skip printing hundreds
                ORA #$30            ; Convert hundreds digit to ASCII
                JSR $1811           ; Print hundreds digit
                INY                 ; Set flag Y=1: a non-zero digit has been printed

SKIP_HUNDREDS:  LDA $04             ; Load tens digit
                CMP #$00
                BNE PRINT_TEN       ; If tens digit is not zero, print it
                ; Tens digit is zero. Only print '0' if a prior digit was printed (Y=1)
                CPY #$00
                BEQ SKIP_TENS       ; If Y=0 (no prior digits printed), skip printing tens '0'
                ; If Y=1 (hundreds was printed), print '0' for tens
                LDA #$30            ; ASCII '0'
                JSR $1811           ; Print tens '0'
                JMP PRINT_ONES

PRINT_TEN:      ORA #$30            ; Convert tens digit to ASCII
                JSR $1811           ; Print tens digit
                INY                 ; Set flag Y=1 (or keep it 1)

SKIP_TENS:      CPY #$00            ; Was anything printed before?
                BNE PRINT_ONES      ; If Y=1, print the ones digit regardless
                LDA $05             ; Load ones digit
                CMP #$00            ; Is it zero?
                BEQ END_PRINT_SUB   ; If Y=0 and Ones=0, we are done (handles input 0 correctly)

PRINT_ONES:     LDA $05             ; Load ones digit
                ORA #$30            ; Convert ones digit to ASCII
                JSR $1811           ; Print ones digit

END_PRINT_SUB:  RTS                 ; Return from subroutine
