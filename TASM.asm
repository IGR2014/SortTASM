; Memory model
.MODEL SMALL
; Stack size
.STACK 100h


; CPU Arch
.386


; Data segment
.DATA

    ; FALSE
    FALSE equ 00h
    ; TRUE
    TRUE equ 0FFh

    ; EOL
    EOL equ 00h
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

    ; Maximum value
    MAX_VALUE equ 10000
    ; Minimum value
    MIN_VALUE equ -10000

    ; Maximum lines count
    MAX_LINE_COUNT equ 10000

    ; Line buffer size
    LINE_SIZE equ 32
    ; Key buffer size
    KEY_SIZE equ 16
    ; Value buffer size
    VALUE_SIZE equ 8

    ; Buffer to receive line
    dataLine db LINE_SIZE DUP(EOL),'$'

    ; Buffer for parsed key
    dataKey db KEY_SIZE DUP(EOL),'$'
    ; Buffer for parsed value
    dataValue db VALUE_SIZE DUP(EOL),'$'

    ; Parsed binary value
    dataValueBin dw 0

    ; Received lines count
    countLines dw 0

    ; Received keys count
    countKeys dw 0

    ; Keys
    arrayKeys db LINE_SIZE*KEY_SIZE DUP(EOL),'$'
    ; Sum of key values
    arraySum dw  LINE_SIZE DUP(0)
    ; Average values
    arrayAverage dw LINE_SIZE DUP(0)
    ; Count values
    arrayCount dw LINE_SIZE DUP(0)


; Code segment
.CODE

    ; Go to entry point
    jmp start


; Entry point
start:
    ; Segments setup
    mov ax, @data                   ; Get CS
    mov ds, ax                      ; Make DS point to CODE segment
    mov es, ax                      ; Make ES point to CODE segment
    mov ss, ax                      ; Make SS point to CODE segment
; Input loop
loop_read:
    ; Read line
    call line_read                  ; Do read line
    ; Check EOF
    cmp al, EOF                     ; EOF ?
    je loop_read_exit               ; Done processing input
    ; Update line count
    inc countLines                  ; Increment lines count
    ; Parse line
    call line_parse                 ; Parse <key> <value>
    ; Convert value
    call decimal_convert            ; Convert value from dec to bin
    ; Find key in table
    xor bx, bx                      ; BX <-- 0
; Loop stored keys
loop_stored_keys:
    ; Check keys
    cmp bx, countKeys               ; Has more keys ?
    jge loop_stored_keys_new        ; Done
    ; Compare keys
    lea si, dataKey                 ; SI <-- Current key
    lea di, arrayKeys               ; DI <-- Key from array
    mov cx, bx
    imul cx, KEY_SIZE
    add di, cx
    call string_compare             ; Do key comparison
    ; Check comparison result
    cmp al, TRUE                    ; Key exists ?
    je loop_stored_key_exists       ; Key already exists
    ; Key does not exist
    inc bx                          ; Next key
    jmp loop_stored_keys            ; Continue loop
; Loop stored key new
loop_stored_keys_new:
    ; Add new key
    lea si, dataKey                 ; SI <-- Current key
    lea di, arrayKeys               ; DI <-- Key from array
    mov cx, bx
    imul cx, KEY_SIZE
    add di, cx
    cld                             ; Clear dir flag
    mov cx, KEY_SIZE                ; Rep count
    rep                             ; Do rep
    movsb                           ; Move bytes from address at SI -> to address at DI
    ; Word offset fix
    shl bx, 01h                     ; BX <-- BX * 2
    ; Update key values sum
    lea di, arraySum                ; DI <-- Values sum from array
    mov ax, word ptr ds:[di + bx]   ; Get values sum
    add ax, dataValueBin            ; Add current value to sum
    mov word ptr ds:[di + bx], ax   ; Set values sum
    ; Update key values count
    lea di, arrayCount              ; DI <-- Values count from array
    mov ax, word ptr ds:[di + bx]   ; Get values count
    inc ax                          ; Increment values count
    mov word ptr ds:[di + bx], ax   ; Store values count
    ; Word offset fix restore
    shr bx, 01h                     ; BX <-- BX / 2
    ; Go to next key
    inc countKeys                   ; Increment keys counter
    jmp loop_stored_keys_exit       ; Done
; Loop stored key exists
loop_stored_key_exists:
    ; Word offset fix
    shl bx, 01h                     ; BX <-- BX * 2
    ; Update key values sum
    lea di, arraySum                ; DI <-- Values sum from array
    mov ax, word ptr ds:[di + bx]   ; Get values sum
    add ax, dataValueBin            ; Add current value to sum
    mov word ptr ds:[di + bx], ax   ; Set values sum
    ; Update key values count
    lea di, arrayCount              ; DI <-- Values count from array
    mov ax, word ptr ds:[di + bx]   ; Get values count
    inc ax                          ; Increment values count
    mov word ptr ds:[di + bx], ax   ; Store values count
    ; Word offset fix restore
    shr bx, 01h                     ; BX <-- BX / 2
; Loop stored keys
loop_stored_keys_exit:
    ; Get next line
    cmp countLines, MAX_LINE_COUNT  ; Max lines received ?
    jge loop_read_exit              ; Done
    jmp loop_read                   ; Next line
; Read loop done
loop_read_exit:
    ; Find key in table
    xor bx, bx                      ; BX <-- 0
; Loop calc average
loop_calc_average:
    ; Check keys
    cmp bx, countKeys               ; Has more keys ?
    jge loop_calc_average_end       ; Done
    ; Word offset fix
    shl bx, 01h                     ; BX <-- BX * 2
    ; Get key values sum
    lea di, arraySum                ; DI <-- Values sum from array
    mov ax, word ptr ds:[di + bx]   ; Get values sum
    ; Get key values count
    lea di, arrayCount              ; DI <-- Values count from array
    mov cx, word ptr ds:[di + bx]   ; Get values count
    idiv cx                         ; Divide values sum by values count
    ; Store key value average
    lea di, arrayAverage            ; DI <-- Average from array
    mov word ptr ds:[di + bx], ax   ; Store average value
    ; Word offset fix restore
    shr bx, 01h                     ; BX <-- BX / 2
    ; Next average calc
    inc bx                          ; Next key
    jmp loop_calc_average           ; Continue loop
; Loop calc average end
loop_calc_average_end:
    ; Exit program
    mov al, 00h                     ; Exit code
    mov ax, 4C00h                   ; DOS exit program with AL = exit code
    int 21h                         ; DOS interrupt
    ret                             ; Exit function


; New line check
is_new_line proc
    ; Check EOL
    cmp al, EOL                     ; EOL ?
    je is_new_line_true             ; Done
    ; Check LF
    cmp al, LF                      ; LF ?
    je is_new_line_true             ; Done
    ; Check CR
    cmp al, CR                      ; CR ?
    je is_new_line_true             ; Done
    ; Not a new line
    mov ah, FALSE
    ret                             ; Exit function
; New line symbol
is_new_line_true:
    ; New line
    mov ah, TRUE
    ret                             ; Exit function
is_new_line endp


; Space check
is_space proc
    ; Check HTAB
    cmp al, HTAB                    ; HTAB ?
    je is_space_true                ; Done
    ; Check VTAB
    cmp al, VTAB                    ; VTAB ?
    je is_space_true                ; Done
    ; Check SPACE
    cmp al, SPACE                   ; SPACE ?
    je is_space_true                ; Done
    ; Not a space
    mov ah, FALSE
    ret                             ; Exit function
; Space symbol
is_space_true:
    ; Space
    mov ah, TRUE
    ret                             ; Exit function
is_space endp


; Read line function
line_read proc
    cld                             ; Clear dir flag
    lea dx, dataLine                ; Line receive buffer
    mov si, dx                      ; Buffer address to SI
    xor bx, bx                      ; BX <-- 0
; Read single char
loop_read_char:
    ; DOS Read char
    mov ah, 01h                     ; DOS Read char
    int 21h                         ; DOS interrupt
    ; Check new line
    call is_new_line
    cmp ah, TRUE                    ; New line ?
    je loop_read_char_exit          ; Done
    ; Check EOF
    cmp al, EOF                     ; EOF ?
    je loop_read_char_exit          ; Done
    ; Store char
    mov byte ptr ds:[si + bx], al   ; Store char to temp storage
    inc bx                          ; Next char
    cmp bx, LINE_SIZE               ; Line filled ?
    jge loop_read_char_exit         ; Done
    jmp loop_read_char              ; Continue loop
; Read single char exit
loop_read_char_exit:
    ; Store EOL
    mov byte ptr ds:[si + bx], EOL  ; Store EOL to temp storage
    ret                             ; Exit function
line_read endp

; Print line function
line_print proc
    cld                             ; Clear dir flag
    mov di, dx                      ; Buffer address to DI
    xor bx, bx                      ; BX <-- 0
; Print single char
loop_print_char:
    mov dl, byte ptr ds:[di + bx]   ; Copy line char to DL
    cmp dl, EOL                     ; Line end ?
    je loop_print_char_exit         ; Done
    mov ah, 02h                     ; DOS Print char
    int 21h                         ; DOS interrupt
    inc bx                          ; Next char
    jmp loop_print_char             ; Continue loop
; Print single char exit
loop_print_char_exit:
    ; Print CR
    mov dl, CR                      ; Copy CR char to DL
    mov ah, 02h                     ; DOS Print char
    int 21h                         ; DOS interrupt
    ; Print LF
    mov dl, LF                      ; Copy LF char to DL
    mov ah, 02h                     ; DOS Print char
    int 21h                         ; DOS interrupt
    ret                             ; Exit function
line_print endp


; Parse line function
line_parse proc
    ; Offset
    xor bx, bx                      ; Reset line offset
    ; Parse key
    call key_parse                  ; Parse key
    ;lea dx, dataKey
    ;call line_print
    ; Parse value
    call value_parse                ; Parse value
    ;lea dx, dataValue
    ;call line_print
    ; Exit
    ret                             ; Exit function
line_parse endp


; Skip space
skip_leading_spaces proc
    cld                             ; Clear dir flag
; Loop skip space
loop_skip_space:
    ; Get char
    mov al, byte ptr ds:[si + bx]   ; Copy line char to AL
    ; Check space
    call is_space
    cmp ah, TRUE                    ; Space ?
    jne loop_skip_space_exit        ; Done
    ; More spaces to eliminate
    inc bx                          ; Next char
    jmp loop_skip_space             ; Continue loop
; Loop skip space exit
loop_skip_space_exit:
    ret                             ; Exit function
skip_leading_spaces endp


; Key parse
key_parse proc
    ; Received line data
    lea dx, dataLine                ; Line buffer
    mov si, dx                      ; Line buffer address to SI
    ; Key storage
    lea dx, dataKey                 ; Key storage buffer
    mov di, dx                      ; Key storage buffer address to DI
    ; Remove any spaces
    call skip_leading_spaces        ; Skip spaces
; Loop key parsing
loop_key_parse:
    ; Check new line
    call is_new_line
    cmp ah, TRUE                    ; New line ?
    je loop_key_parse_exit          ; Done
    ; Check space
    call is_space
    cmp ah, TRUE                    ; Space ?
    je loop_key_parse_exit          ; Done
    ; Check EOF
    cmp al, EOF                     ; EOF ?
    je loop_key_parse_exit          ; Done
    ; Store key char
    mov byte ptr ds:[di], al        ; Copy AL char to keys array
    inc di
    inc bx                          ; Next char
    cmp bx, LINE_SIZE               ; Line end ?
    jge loop_key_parse_exit         ; Done
    ; Get char
    mov al, byte ptr ds:[si + bx]   ; Copy line char to AL
    jmp loop_key_parse              ; Continue loop
; Loop key parsing exit
loop_key_parse_exit:
    ; Store EOL
    mov byte ptr ds:[di], EOL       ; Store EOL to temp storage
    ret                             ; Exit function
key_parse endp

; Value parse
value_parse proc
    ; Received line data
    lea dx, dataLine                ; Line buffer
    mov si, dx                      ; Line buffer address to SI
    ; Value storage
    lea dx, dataValue               ; Value storage buffer
    mov di, dx                      ; Value storage buffer address to DI
    ; Remove any spaces
    call skip_leading_spaces        ; Skip spaces
; Loop value parsing
loop_value_parse:
    ; Check new line
    call is_new_line
    cmp ah, TRUE                    ; New line ?
    je loop_value_parse_exit        ; Done
    ; Check space
    call is_space
    cmp ah, TRUE                    ; Space ?
    je loop_value_parse_exit        ; Done
    ; Check EOF
    cmp al, EOF                     ; EOF ?
    je loop_value_parse_exit        ; Done
    ; Store value char
    mov byte ptr ds:[di], al        ; Copy AL char to keys array
    inc di
    inc bx                          ; Next char
    cmp bx, LINE_SIZE               ; Line end ?
    jge loop_value_parse_exit       ; Done
    ; Get char
    mov al, byte ptr ds:[si + bx]   ; Copy line char to AL
    jmp loop_value_parse            ; Continue loop
; Loop value parsing exit
loop_value_parse_exit:
    ; Store EOL
    mov byte ptr ds:[di], EOL       ; Store EOL to temp storage
    ret                             ; Exit function
value_parse endp


; Convert decimal to binary
decimal_convert proc
    ; Offset
    xor cx, cx                      ; Reset temporary value storage
    xor bx, bx                      ; Reset value storage offset
    ; Value storage
    lea dx, dataValue               ; Value storage buffer
    mov si, dx                      ; Value storage buffer address to SI
    ; Remove any spaces
    call skip_leading_spaces        ; Skip spaces
; Loop decimal convert
loop_decimal_convert:
    ; Get char
    movsx ax, byte ptr ds:[si + bx] ; Copy line char to AL
    ; Check range
    cmp ax, '0'                     ; Lower bound OK ?
    jl loop_decimal_convert_exit    ; Done
    cmp ax, '9'                     ; Upper bound OK ?
    jg loop_decimal_convert_exit    ; Done
    sub ax, '0'                     ; Convert ASCII char to digit
    imul cx, 10                     ; Multiply value storage by 10
    add cx, ax                      ; Add digit
    cmp cx, MIN_VALUE               ; Lower bound OK ?
    jl loop_decimal_convert_error   ; Done
    cmp cx, MAX_VALUE               ; Upper bound OK ?
    jg loop_decimal_convert_error   ; Done
    inc bx                          ; Next char
    cmp bx, VALUE_SIZE              ; Line end ?
    jge loop_value_parse_exit       ; Done
    jmp loop_decimal_convert        ; Continue loop
; Loop decimal convert error
loop_decimal_convert_error:
    mov cx, 0000h                   ; Clear value in case of error
; Loop decimal convert exit
loop_decimal_convert_exit:
    ; Store binary value
    mov dataValueBin, cx            ; Store value
    ret                             ; Exit function
decimal_convert endp


; Compare strings
string_compare proc
    ; Prepare
    cld                             ; Clear dir flag
; Loop compare character
string_compare_char:
    lodsb                           ; Load AL with next char from string 1
    cmp [di], al                    ; Compare characters
    jne string_compare_exit         ; Jump out of loop if they are not the same
    inc di                          ; DI -> next character in string 2
    cmp al, EOL                     ; EOL ?
    jne string_compare_char         ; Continue loop
    mov al, TRUE                    ; Strings are equal
    ret                             ; Exit function
; Loop compare character exit
string_compare_exit:
    mov al, FALSE                   ; Strings are not equal
    ret                             ; Exit function
string_compare endp


; Program end
END start
