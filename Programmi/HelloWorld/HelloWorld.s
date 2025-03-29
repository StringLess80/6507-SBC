               .ORG $0500

RESET:          LDX #0
SENDMSG:        LDA MSG,X
                BEQ DONE
                JSR $1811       ; .CHROUT (bios)
                INX
                JMP SENDMSG
DONE:           JMP $1efd       ; Jump back to WozMon

MSG: .asciiz 0x0d, 0x0a, "Hello, World!", 0x0d, 0x0a
