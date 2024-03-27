; Memory model
.MODEL TINY
; Stack size
.STACK 100h


; CPU Arch
.386


; Data segment
.DATA

    ; Line buffer size
    LINE_SIZE equ 32

    ; Buffer to receive line
    lineSize db LINE_SIZE
    lineRead db ?
    lineData db LINE_SIZE DUP('$'),'$'


; Code segment
.CODE

    ; Go to entry point
    jmp start

; Entry point
start:
    mov ax, @data           ; Get CS
    mov ds, ax              ; Make DS point to CODE segment
    mov es, ax              ; Make ES point to CODE segment
    mov ss, ax              ; Make SS point to CODE segment

    lea dx, lineSize
    call read_string

    lea dx, lineData
    call print_string

    call exit               ; Exit program


; Read string function
read_string proc
    mov ah, 0Ah             ; DOS Read string
    int 21h                 ; DOS interrupt
    ret                     ; Exit function
read_string endp

; Print string function
print_string proc
    mov ah, 09h             ; DOS Print string
    int 21h                 ; DOS interrupt
    ret                     ; Exit function
print_string endp

; Exit function
exit proc
    mov ax, 4C00h           ; DOS exit program with al = exit code
    int 21h                 ; DOS interrupt;
    ret                     ; Exit function
exit endp

; Program end
END start
