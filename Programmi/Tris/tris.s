;----------------------------------------------------
; Tic-Tac-Toe (Tris) per 6502 per Terminale Seriale
; Realizzato da: Alessandro Iglina
; Data: 2025-04-01
;
; Indirizzo di Caricamento: $0500
;----------------------------------------------------

; --- Configurazione ---
PUTC       = $1811  ; Indirizzo di CHROUT (Stampa Carattere)
GETC       = $1800  ; Indirizzo di CHRIN (Leggi Carattere)

; --- Uso Pagina Zero ---
ZP_PTR     = $FB    ; Byte basso per puntatore stringa
ZP_PTR_HI  = $FC    ; Byte alto per puntatore stringa
TEMP1      = $FD    ; Memoria temporanea generica

; --- Costanti ---
PLAYER_X   = $58    ; ASCII 'X'
PLAYER_O   = $4F    ; ASCII 'O'
FLIP_MASK  = $17    ; Valore per PLAYER_X EOR PLAYER_O
SPACE      = $20    ; ASCII ' ' (spazio)
CR         = $0D    ; Ritorno a Capo (Carriage Return)
LF         = $0A    ; Nuova Linea (Line Feed)

; --- Inizio Programma ---
           * = $0500

START:
    JSR INIT_GAME      ; Inizializza il gioco

GAME_LOOP:
    JSR PRINT_BOARD    ; Stampa il tavoliere
    JSR PRINT_PROMPT   ; Stampa il prompt per il giocatore
GET_INPUT_LOOP:
    JSR GET_MOVE       ; Attende input usando loop CHRIN.
                       ; Ritorna indice 0-8 in A se valido '1'-'9',
                       ; o $FF altrimenti. CHRIN gestisce l'echo.
    CMP #$FF           ; Controlla se GET_MOVE ha segnalato tipo invalido
    BEQ GET_INPUT_LOOP ; Se $FF, torna indietro a prendere un altro carattere

    ; A contiene indice valido 0-8 da un carattere input valido ('1'-'9')
    TAX                ; Usa indice in X
    LDA BOARD,X
    CMP #SPACE         ; Controlla se la casella è libera
    BNE SQUARE_TAKEN   ; Salta se la casella non è libera

    ; Mossa valida e casella libera, indice è in X
    TXA                ; Rimetti l'indice in A per UPDATE_BOARD
    JSR UPDATE_BOARD   ; Piazza il simbolo

    ; Controlla se c'è una vittoria
    JSR CHECK_WIN      ; Ritorna vincitore (X/O) in A, o SPAZIO se non c'è ancora vittoria
    CMP #SPACE
    BNE GAME_OVER_WIN  ; Salta se qualcuno ha vinto

    ; Controlla se c'è un pareggio
    JSR CHECK_DRAW     ; Imposta Carry se pareggio, Pulisce Carry altrimenti
    BCS GAME_OVER_DRAW ; Salta se è pareggio

    ; Nessuna vittoria, nessun pareggio - cambia giocatore e continua
    JSR SWITCH_PLAYER
    JMP GAME_LOOP

SQUARE_TAKEN:          ; Casella Occupata
    JSR PRINT_NEWLINE  ; Aggiungi nuova linea dopo il carattere (posizione non valida) già mostrato con echo
    LDX #<STR_TAKEN    ; Carica puntatore alla stringa "Casella gia' occupata!"
    LDY #>STR_TAKEN
    JSR PRINT_STRING   ; Stampa la stringa
    JSR PRINT_NEWLINE
    JMP GAME_LOOP      ; Torna al loop principale (ristampa tavoliere/prompt)

GAME_OVER_WIN:         ; Fine Partita - Vittoria
    STA TEMP1          ; Salva vincitore (contiene $58 o $4F)
    JSR PRINT_BOARD    ; Mostra tavoliere finale
    JSR PRINT_NEWLINE
    ; Stampa "Giocatore X/O Vince!" usando valori hex
    LDA #$47           ; 'G'
    JSR PUTC
    LDA #$69           ; 'i'
    JSR PUTC
    LDA #$6F           ; 'o'
    JSR PUTC
    LDA #$63           ; 'c'
    JSR PUTC
    LDA #$61           ; 'a'
    JSR PUTC
    LDA #$74           ; 't'
    JSR PUTC
    LDA #$6F           ; 'o'
    JSR PUTC
    LDA #$72           ; 'r'
    JSR PUTC
    LDA #$65           ; 'e'
    JSR PUTC
    LDA #$20           ; ' '
    JSR PUTC
    LDA TEMP1          ; Prendi il simbolo del vincitore ($58 o $4F)
    JSR PUTC
    LDA #$20           ; ' '
    JSR PUTC
    LDX #<STR_WINS     ; Carica puntatore stringa " Vince!"
    LDY #>STR_WINS
    JSR PRINT_STRING   ; Stampa " Vince!"
    JMP END_GAME       ; Salta alla fine del gioco

GAME_OVER_DRAW:        ; Fine Partita - Pareggio
    JSR PRINT_BOARD    ; Mostra tavoliere finale
    LDX #<STR_DRAW     ; Carica puntatore stringa "E' un pareggio!"
    LDY #>STR_DRAW
    JSR PRINT_STRING   ; Stampa "E' un pareggio!"
    ; Passa a END_GAME (senza JMP esplicito)

END_GAME:              ; Fine Gioco
    JSR PRINT_NEWLINE
    JSR PRINT_NEWLINE
HALT:
    BRK                ; Ferma l'esecuzione (o attiva il monitor)
    ; JMP HALT

;----------------------------------------------------
; Sottoprogramma: INIT_GAME (Inizializza il gioco)
;----------------------------------------------------
INIT_GAME:
    LDX #8             ; Indice per il loop (da 8 a 0)
INIT_LOOP:
    LDA #SPACE         ; Carica carattere spazio ($20)
    STA BOARD,X        ; Salva nella posizione X del tavoliere
    DEX                ; Decrementa indice
    BPL INIT_LOOP      ; Continua finché X >= 0
    LDA #PLAYER_X      ; Inizia con il giocatore X ($58)
    STA CURPLAYER      ; Salva giocatore corrente
    RTS                ; Ritorna dalla subroutine

;----------------------------------------------------
; Sottoprogramma: PRINT_BOARD (Stampa il tavoliere)
;----------------------------------------------------
PRINT_BOARD:
    JSR PRINT_NEWLINE
    ; Riga 0
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
    ; Separatore
    LDX #<STR_SEPARATOR
    LDY #>STR_SEPARATOR
    JSR PRINT_STRING
    JSR PRINT_NEWLINE
    ; Riga 1
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
    ; Separatore
    LDX #<STR_SEPARATOR
    LDY #>STR_SEPARATOR
    JSR PRINT_STRING
    JSR PRINT_NEWLINE
    ; Riga 2
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
; Sottoprogramma: PRINT_PROMPT (Stampa il prompt per il giocatore)
;----------------------------------------------------
PRINT_PROMPT:
    LDX #<STR_PLAYER   ; Carica puntatore stringa "Giocatore "
    LDY #>STR_PLAYER
    JSR PRINT_STRING
    LDA CURPLAYER      ; Carica simbolo giocatore corrente
    JSR PUTC           ; Stampalo
    LDX #<STR_TURN     ; Carica puntatore stringa ", inserisci mossa (1-9): "
    LDY #>STR_TURN
    JSR PRINT_STRING
    RTS

;----------------------------------------------------
; Sottoprogramma: GET_MOVE (Ottiene la mossa dal giocatore)
;----------------------------------------------------
GET_MOVE:
WAIT_INPUT_LOOP:
    JSR GETC           ; Chiama CHRIN a $1800
    BCC WAIT_INPUT_LOOP ; Torna indietro se Carry pulito (nessun tasto premuto)

    ; Carattere ricevuto in A, CHRIN ha già fatto l'echo.
    ; Controlla se input è tra '1' ($31) e '9' ($39)
    CMP #$31           ; Confronta con ASCII '1'
    BCC INVALID_CHAR   ; Salta se < '1' (non valido)
    CMP #$3A           ; Confronta con ASCII '9' + 1
    BCS INVALID_CHAR   ; Salta se > '9' (non valido)

    ; Converti ASCII valido '1'-'9' in indice 0-8
    SEC
    SBC #$31           ; Sottrai codice ASCII di '1' per ottenere 0-8
    RTS                ; Ritorna con indice 0-8 in A

INVALID_CHAR:          ; Carattere non valido
    ; Carattere non valido ricevuto ed echo fatto da CHRIN. Aggiungi nuova linea.
    JSR PRINT_NEWLINE
    LDA #$FF           ; Carica $FF per segnalare tipo carattere non valido
    RTS

;----------------------------------------------------
; Sottoprogramma: UPDATE_BOARD (Aggiorna il tavoliere)
; Input: Indice 0-8 in A
;----------------------------------------------------
UPDATE_BOARD:
    TAX                ; Usa A (indice) come offset in X
    LDA CURPLAYER      ; Carica il simbolo del giocatore corrente ('X' o 'O')
    STA BOARD,X        ; Scrivi il simbolo sul tavoliere all'indice X
    RTS

;----------------------------------------------------
; Sottoprogramma: CHECK_WIN (Controlla se c'è una vittoria)
; Ritorna: Simbolo vincitore (X/O) in A, o SPAZIO se nessuna vittoria.
;----------------------------------------------------
CHECK_WIN:
    LDX #0             ; Indice per controllare righe/colonne (inizia da 0)
CHECK_ROW_LOOP:        ; Controlla Righe (0-2, 3-5, 6-8)
    LDA BOARD+0,X      ; Carica casella 1 della riga (indici 0, 3, 6)
    CMP #SPACE         ; È vuota?
    BEQ NEXT_ROW       ; Se vuota, la riga non può essere vincente, passa alla prossima
    CMP BOARD+1,X      ; Confronta con casella 2 (indici 1, 4, 7)
    BNE NEXT_ROW       ; Se diverse, non c'è vittoria, passa alla prossima
    CMP BOARD+2,X      ; Confronta con casella 3 (indici 2, 5, 8)
    BNE NEXT_ROW       ; Se diverse, non c'è vittoria, passa alla prossima
    RTS                ; Se uguali, A contiene il simbolo vincente. Ritorna.
NEXT_ROW:
    TXA                ; Sposta l'indice X in A
    CLC
    ADC #3             ; Aggiungi 3 per passare all'inizio della riga successiva (0->3, 3->6)
    TAX                ; Rimetti in X
    CPX #9             ; Abbiamo controllato la riga che inizia con 6? (Indice sarebbe 9)
    BCC CHECK_ROW_LOOP ; Se indice < 9, controlla la prossima riga

    LDX #0             ; Resetta indice per controllo colonne
CHECK_COL_LOOP:        ; Controlla Colonne (0,3,6 / 1,4,7 / 2,5,8)
    LDA BOARD+0,X      ; Carica casella 1 della colonna (indici 0, 1, 2)
    CMP #SPACE
    BEQ NEXT_COL       ; Se vuota, passa alla prossima colonna
    CMP BOARD+3,X      ; Confronta con casella 2 (indici 3, 4, 5)
    BNE NEXT_COL
    CMP BOARD+6,X      ; Confronta con casella 3 (indici 6, 7, 8)
    BNE NEXT_COL
    RTS                ; Se uguali, A contiene il vincitore. Ritorna.
NEXT_COL:
    INX                ; Passa alla prossima colonna (0->1, 1->2)
    CPX #3             ; Abbiamo controllato la colonna 2? (Indice sarebbe 3)
    BCC CHECK_COL_LOOP ; Se indice < 3, controlla prossima colonna

    ; Controlla Diagonali
    ; Diagonale 1 (0, 4, 8)
    LDA BOARD+0
    CMP #SPACE
    BEQ CHK_D2         ; Se vuota, controlla l'altra diagonale
    CMP BOARD+4
    BNE CHK_D2
    CMP BOARD+8
    BNE CHK_D2
    RTS                ; A contiene il vincitore (da BOARD+0)
CHK_D2:
    ; Diagonale 2 (2, 4, 6)
    LDA BOARD+2
    CMP #SPACE
    BEQ NO_WIN         ; Se vuota, nessuna vittoria
    CMP BOARD+4
    BNE NO_WIN
    CMP BOARD+6
    BNE NO_WIN
    RTS                ; A contiene il vincitore (da BOARD+2)
NO_WIN:                ; Nessuna vittoria trovata
    LDA #SPACE
    RTS

;----------------------------------------------------
; Sottoprogramma: CHECK_DRAW (Controlla se c'è un pareggio - tavoliere pieno)
; Ritorna: Carry IMPOSTATO se pareggio, Carry PULITO altrimenti
;----------------------------------------------------
CHECK_DRAW:
    LDX #8             ; Indice per controllare da 8 a 0
CHECK_DRAW_LOOP:
    LDA BOARD,X        ; Carica casella X
    CMP #SPACE         ; È uno spazio vuoto?
    BEQ NOT_DRAW       ; Se sì, non è pareggio, esci
    DEX                ; Decrementa indice
    BPL CHECK_DRAW_LOOP ; Se indice >= 0, continua controllo
    ; Se il loop finisce, non ci sono spazi vuoti -> Pareggio
    SEC                ; Imposta Carry per segnalare pareggio
    RTS
NOT_DRAW:              ; Trovato uno spazio, non è pareggio
    CLC                ; Pulisci Carry
    RTS

;----------------------------------------------------
; Sottoprogramma: SWITCH_PLAYER (Cambia il giocatore corrente)
;----------------------------------------------------
SWITCH_PLAYER:
    LDA CURPLAYER      ; Carica giocatore attuale
    EOR #FLIP_MASK     ; Applica XOR con maschera $17 per alternare tra X($58) e O ($4F)
    STA CURPLAYER      ; Salva il nuovo giocatore corrente
    RTS

;----------------------------------------------------
; Sottoprogramma: PRINT_STRING (Stampa una stringa terminata da zero)
; Input: Byte basso indirizzo in X, Byte alto in Y
; Modifica: A, Y, ZP_PTR, ZP_PTR_HI
;----------------------------------------------------
PRINT_STRING:
    STX ZP_PTR         ; Salva byte basso puntatore in pagina zero
    STY ZP_PTR_HI      ; Salva byte alto puntatore in pagina zero
    LDY #0             ; Indice Y inizia da 0
PRINT_LOOP:
    LDA (ZP_PTR),Y     ; Carica carattere usando indirizzamento indiretto indicizzato
    BEQ PRINT_DONE     ; Se è il byte zero (fine stringa), esci
    JSR PUTC           ; Stampa il carattere
    INY                ; Incrementa indice Y
    BNE PRINT_LOOP     ; Continua (Assume stringa < 256 byte / non serve gestione cambio pagina)
PRINT_DONE:
    RTS

;----------------------------------------------------
; Sottoprogramma: PRINT_NEWLINE (Stampa ritorno a capo + nuova linea)
;----------------------------------------------------
PRINT_NEWLINE:
    LDA #CR            ; Carica Ritorno a Capo ($0D)
    JSR PUTC
    LDA #LF            ; Carica Nuova Linea ($0A)
    JSR PUTC
    RTS

;----------------------------------------------------
; --- Area Dati ---
;----------------------------------------------------
CURPLAYER:  .BYTE PLAYER_X ; $58 - Giocatore Corrente
BOARD:      .DS 9            ; 9 byte per il tavoliere (Definisci Spazio)

; --- Stringhe Messaggi (Italiano, ASCII 7-bit) ---
STR_PLAYER: .BYTE $47,$69,$6F,$63,$61,$74,$6F,$72,$65,$20, 0 ; "Giocatore "
STR_TURN:   .BYTE $2C,$20,$69,$6E,$73,$65,$72,$69,$73,$63,$69,$20,$6D,$6F,$73,$73,$61,$20,$28,$31,$2D,$39,$29,$3A,$20, 0 ; ", inserisci mossa (1-9): "
STR_SEPARATOR:.BYTE $2D,$2D,$2D,$2B,$2D,$2D,$2D,$2B,$2D,$2D,$2D, 0 ; "---+---+---" (Grafico, mantenuto)
STR_WINS:   .BYTE $20,$56,$69,$6E,$63,$65,$21, 0 ; " Vince!"
STR_DRAW:   .BYTE $45,$27,$20,$75,$6E,$20,$70,$61,$72,$65,$67,$67,$69,$6F,$21, 0 ; "E' un pareggio!"
STR_TAKEN:  .BYTE $43,$61,$73,$65,$6C,$6C,$61,$20,$67,$69,$61,$27,$20,$6F,$63,$63,$75,$70,$61,$74,$61,$21, 0 ; "Casella gia' occupata!"

; --- Fine Programma ---
