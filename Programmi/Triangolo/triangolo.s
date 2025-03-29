                .ORG $0500

RESET:          LDA #$0D        ; A capo
                JSR $1811
                LDX #1          ; Inizializza counter righe a 1

RIGHE:          CPX #$06        ; Raggiunta fine?
                BEQ DONE            ; Termina
                TXA
                TAY

STAR:           CPY #$00
                BEQ NUOVA_RIGA
                LDA #$2A
                JSR $1811       ; CHROUT
                LDA #$20
                JSR $1811       ; CHROUT
                DEY
                JMP STAR

NUOVA_RIGA:     INX
                LDA #$0D        ; A capo
                JSR $1811       ; CHROUT
                JMP RIGHE

DONE:           JMP $1efd       ; Torna a WozMon
