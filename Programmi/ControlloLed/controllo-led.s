                .ORG $500

INIT:           LDA #$FF            ; PORTA A 6522 OUTPUT
                STA $803

MAIN:           JSR $1800           ; CHRIN dal bios
                CMP #$31            ; 1?
                BEQ CASOA               ; > Caso A
                CMP #$32            ; 2?
                BEQ CASOB               ; > Caso B
                CMP #$33            ; 3?
                BEQ CASOC               ; > Caso C
                CMP #$34            ; 4?
                BEQ CASOD               ; > Caso D
                CMP #$51            ; Q?
                BEQ QUIT                ; Torna a WozMon
                JMP MAIN            ; loop

CASOA:          LDX #%00000001
                STX $801            ; Porta A
                JMP MAIN

CASOB:          LDX #%00000010
                STX $801
                JMP MAIN

CASOC:          LDX #%00000100
                STX $801
                JMP MAIN

CASOD:          LDX #%00001000
                STX $801
                JMP MAIN

QUIT:           JMP $1EFD           ; Torna a WozMon
