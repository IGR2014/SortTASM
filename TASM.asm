; Memory model
.MODEL TINY
; Stack size
.STACK 100h


; CPU Arch
.386


; Data segment
.DATA

    ; HOR. TAB
    HTAB equ 09h
    ; LF
    LF equ 0Ah
    ; VERT. TAB
    VTAB equ 0Bh
    ; CR
    CR equ 0Dh
    ; SPACE
    SPACE equ 20h
    ; EOF
    EOF equ 1Ah

    ; Maximum lines count
    MAX_LINE_COUNT equ 10000

    ; Line buffer size
    LINE_SIZE equ 32
    ; Key buffer size
    KEY_SIZE equ 16
    ; Value buffer size
    VALUE_SIZE equ 6

    ; Buffer to receive line
    dataLine db LINE_SIZE DUP('$'),'$'

    ; Buffer for parsed key
    dataKey db KEY_SIZE DUP('$'),'$'
    ; Buffer for parsed value
    dataValue db VALUE_SIZE DUP('$'),'$'

    ; Received lines count
    countLines dw 0

    ; Keys
    arrayKeys db LINE_SIZE*KEY_SIZE DUP('$'),'$'
    ; Values
    arrayValues dw LINE_SIZE DUP(0)


; Code segment
.CODE

    ; Go to entry point
    jmp start

; Entry point
start:
    ; Segments setup
    mov ax, @data               ; Get CS
    mov ds, ax                  ; Make DS point to CODE segment
    mov es, ax                  ; Make ES point to CODE segment
    mov ss, ax                  ; Make SS point to CODE segment

; Input loop
loop_read:
    lea dx, dataLine            ; Line receive buffer
    call line_read              ; Do read line
    cmp al, EOF                 ; EOF ?
    jz loop_read_exit           ; Done processing input
    inc countLines              ; Increment lines count
    call line_parse             ; Parse <key> <value>
    jmp loop_read               ; Next line
; Read loop done
loop_read_exit:
    ;lea dx, dataLine
    ;call line_print

    call exit                   ; Exit program


; Read line function
line_read proc
    xor bx, bx                  ; BX <-- 0
; Read single char
loop_read_char:
    mov si, dx                  ; Buffer address to SI
    mov ah, 01h                 ; DOS Read char
    int 21h                     ; DOS interrupt
    cmp al, LF                  ; LF ?
    jz line_read_exit           ; Done
    cmp al, CR                  ; CR ?
    jz line_read_exit           ; Done
    cmp al, EOF                 ; EOF ?
    jz line_read_exit           ; Done
    mov ds:[si + bx], al        ; Store char to temp storage
    cmp bx, LINE_SIZE           ; Line filled ?
    jz line_read_exit           ; Done
    inc bx                      ; Next char
    jmp loop_read_char          ; Continue loop
; Read single char exit
line_read_exit:
    ret                         ; Exit function
line_read endp

; Print line function
line_print proc
    mov ah, 09h                 ; DOS Print line
    int 21h                     ; DOS interrupt
    ret                         ; Exit function
line_print endp


; Parse line function
line_parse proc
    lea dx, dataLine            ; Line buffer
    mov si, dx                  ; Line buffer address to SI
    lea dx, arrayKeys           ; Key storage buffer
    mov cx, countLines          ; Key storage buffer address to DI
    imul cx, LINE_SIZE
    add dx, cx
    mov di, dx
    call key_parse              ; Parse key
    ret                         ; Exit function
line_parse endp


; Skip space
skip_leading_spaces proc
; Loop skip leading spaces
loop_skip_leading_space:
    mov al, ds:[si + bx]        ; Copy line char to AL
    inc bx                      ; Next char
    cmp al, HTAB                ; HTAB ?
    jz loop_skip_leading_space  ; Continue
    cmp al, VTAB                ; VTAB ?
    jz loop_skip_leading_space  ; Continue
    cmp al, SPACE               ; SPACE ?
    jz loop_skip_leading_space  ; Continue
    ret                         ; Exit function
skip_leading_spaces endp


; Key parse
key_parse proc
    xor bx, bx                  ; BX <-- 0
    call skip_leading_spaces    ; Skip spaces
; Loop key parsing
loop_key_parse:
    mov al, ds:[si + bx]        ; Copy line char to AL
    cmp al, HTAB                ; HTAB ?
    jz loop_key_parse_exit      ; Done
    cmp al, LF                  ; LF ?
    jz loop_key_parse_exit      ; Done
    cmp al, VTAB                ; VTAB ?
    jz loop_key_parse_exit      ; Done
    cmp al, CR                  ; CR ?
    jz loop_key_parse_exit      ; Done
    cmp al, SPACE               ; SPACE ?
    jz loop_key_parse_exit      ; Done
    cmp al, EOF                 ; EOF ?
    mov ds:[di + bx], al        ; Copy AL char to keys array
    inc bx                      ; Next char
    jmp loop_key_parse          ; Continue loop
; Loop key parsing exit
loop_key_parse_exit:
    ret                         ; Exit function
key_parse endp

; Value parse
value_parse proc
    call skip_leading_spaces    ; Skip spaces
; Loop value parsing
loop_value_parse:
    mov al, ds:[si + bx]        ; Copy line char to AL
    cmp al, HTAB                ; HTAB ?
    jz loop_key_parse_exit      ; Done
    cmp al, LF                  ; LF ?
    jz loop_value_parse_exit    ; Done
    cmp al, VTAB                ; VTAB ?
    jz loop_key_parse_exit      ; Done
    cmp al, CR                  ; CR ?
    jz loop_value_parse_exit    ; Done
    cmp al, SPACE               ; SPACE ?
    jz loop_value_parse_exit    ; Done
    cmp al, EOF                 ; EOF ?
    mov ds:[di + bx], al        ; Copy AL char to keys array
    inc bx                      ; Next char
    jmp loop_value_parse        ; Continue loop
; Loop value parsing exit
loop_value_parse_exit:
    ret                         ; Exit function
value_parse endp


; Exit function
exit proc
    mov ax, 4C00h               ; DOS exit program with al = exit code
    int 21h                     ; DOS interrupt;
    ret                         ; Exit function
exit endp

; Program end
END start
