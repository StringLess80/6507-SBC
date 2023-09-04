PORTB = $1000
PORTA = $1001
DDRB = $1002
DDRA = $1003

E  = %10000000
RW = %01000000
RS = %00100000

    .org $0000

reset:
    lda #%11111111
    sta DDRB

    lda #%11100000
    sta DDRA

    lda #%00111000      ;8-bit mode, 2-line display, 5x8 font
    sta PORTB
    lda #0              ;Clear RS/RW/E bits
    sta PORTA
    lda #E              ;Set E bit to send instruction
    sta PORTA
    lda #0              ; Clear RS/RW/E bits
    sta PORTA

    lda #%00001111      ;Display on, cursor on, blink on
    sta PORTB
    lda #0
    sta PORTA
    lda #E
    sta PORTA
    lda #0
    sta PORTA

    lda #%00000001      ;Clear display, reset display memory
    sta PORTB
    lda #0
    sta PORTA
    lda #E
    sta PORTA
    lda #0
    sta PORTA

    lda #$00000001 ; Clear display
    sta PORTB
    lda #0
    sta PORTA
    lda #E
    sta PORTA
    lda #0
    sta PORTA

    lda #"A"
    sta PORTB
    lda #RS         ; Set RS; Clear RW/E bits
    sta PORTA
    lda #(RS | E)   ; Set E bit to send instruction
    sta PORTA
    lda #RS         ; Clear E bits
    sta PORTA

loop:
  jmp loop

    .org $0ffc
    .word reset
    .word $0000