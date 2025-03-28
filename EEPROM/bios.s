               .SETCPU "6502"
               .DEBUGINFO
               .SEGMENT "BIOS"

; 6522
PORTB           = $800
PORTA           = $801
DDRB            = $802
DDRA            = $803

; 6551 ACIA
ACIA_DATA       = $1000
ACIA_STATUS     = $1001
ACIA_CMD        = $1002
ACIA_CTRL       = $1003

CHRIN:          LDA ACIA_STATUS
                AND #$08        ; Check RX buffer status flag
                BEQ @no_key
                LDA ACIA_DATA
                JSR CHROUT
                SEC
                RTS
@no_key:        CLC
                RTS

CHROUT:         STA ACIA_DATA   ; Output a character from the A
                PHA             ;  register to the serial interface
@tx_wait:       LDA ACIA_STATUS
                AND #$10        ; Check TX buffer status flag
                BEQ @tx_wait
                PLA
                RTS

                  .INCLUDE "wozmon.s"

                  .SEGMENT "VECTORS"
                  .WORD RESET     ; RESET
                  .WORD $0000     ; BRK/IRQ