PORTB = $1000
PORTA = $1001
DDRB = $1002
DDRA = $1003


    .org $0000

reset:
    lda #%11111111
    sta DDRA

loop:
    lda #$55
    sta PORTA

    lda #$aa
    sta PORTA

    jmp loop

    .org $0ffc
    .word reset
    .word $0000