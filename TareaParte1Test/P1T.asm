section .data
    espacio db 10             ; New line character for syscalls

section .bss
    lineCount resq 1          ; Initialize line count
    printCont resq 1          ; Initialize print content count
    wordCount resq 1          ; Initialize word count
    lastPrint resq 1          ; Pointer to start of last printed word
    buffer resb 2050

section .text
    global _start

_start:


_startFullPrint:
    mov r9, text_start        ; Pointer to start of the text
    mov [lastPrint], r9       ; Initialize lastPrint to start of text

_fullPrint:
    xor rax, rax              ; Clear rax
    mov qword [lineCount], 0    	; Inicializar contador de líneas
    mov qword [printCont], 0        ; Inicializar contador de caracteres por linea
    mov qword [wordCount], 0

_printLoopFP:
    mov cl, [r9]
    test cl, cl
    jz _endPrintFP              ; End if NULL character is reached
    ; Check if character is space, tab, or newline
    cmp cl, ' '
    je _checkWordBoundaryFP
    cmp cl, 9                 ; ASCII for Tab
    je _checkWordBoundaryFP
    cmp cl, 10                ; ASCII for Newline
    je _checkWordBoundaryFP

    inc qword[printCont]           ; Increment character counter
    inc r9                    ; Move to next character
    jmp _printLoopFP

_checkWordBoundaryFP:
    inc qword[wordCount]           ; Increment word count
    cmp qword[wordCount], 10
    jl _incrementCharFP         ; If less than 10 words, keep printing
    
    mov rsi, [lineCount]
    call _startItoa
    
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 2               ; Number of characters from lastPrint to current position
    syscall

    ; Logic to print every ten words
	mov rax, 1                  ; syscall: write
	mov rdi, 1                  ; fd: stdout
	mov rsi, [lastPrint]        ; Start of string to print
	mov rdx, r9
	sub rdx, [lastPrint]        ; Calculate length to print
	test rdx, rdx               ; Check if length is positive
	jle _endPrintFP              ; Skip printing if length is not positive
	syscall                     ; Perform print
	
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio          ; Print newline
    mov rdx, 1
    syscall

    mov [lastPrint], r9       ; Update lastPrint to new position
    xor rax, rax
    mov [wordCount], rax      ; Reset word count
    inc qword[lineCount]           ; Increment line count

_incrementCharFP:
    inc qword[printCont]           ; Increment character counter
    inc r9                    ; Move to next character
    jmp _printLoopFP

_endPrintFP:
    mov rsi, [lineCount]
    call _startItoa
    
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 2               ; Number of characters from lastPrint to current position
    syscall

; Check if there's remaining content to print
    mov rsi, [lastPrint]      ; Get the pointer to the last printed position
    mov rdx, r9               ; Get the current position in text
    sub rdx, rsi              ; Calculate the length of the remaining text
    test rdx, rdx             ; Check if there is anything to print
    jle _finalizeFP             ; Jump to finalize if nothing to print

    ; Print remaining content
    mov rax, 1                ; syscall number for sys_write
    mov rdi, 1                ; file descriptor 1 for stdout
    syscall                   ; Execute the print

_finalizeFP:
    ; Optionally, ensure the output ends with a newline
    mov rax, 1
    mov rdi, 1
    lea rsi, [espacio]        ; Load the address of the newline character
    mov rdx, 1                ; Length is 1
    syscall
    ; Optional: Print remaining content if not empty
    
    jmp _finishCode
    ;ret
    
_startItoa: 
    mov rdi, buffer
    mov rsi, rsi 
    mov rbx, 10       ; La base
    call itoa
    mov r8, rax                     ; Almacena la longitud de la cadena
    
    ; Añade un salto de línea
    mov byte [buffer + r8], " "
    inc r8
    
    ; Termina la cadena con null
    mov byte [buffer + r8], 0

    ;mov rax, buffer
    
    ;call  _genericprint
    
    ret

; Definición de la función ITOA
itoa:
    mov rax, rsi                    ; Mueve el número a convertir (en rsi) a rax
    mov rsi, 0                      ; Inicializa rsi como 0 (contador de posición en la cadena)
    mov r10, 10                    

.loop:
    mov rdx, 0                    
    div r10                         
	add rdx, "0"
	mov [rdi +rsi], dl
	inc rsi
	cmp rax, 0
	jg .loop
	
	mov rdx, rdi
	lea rcx, [rdi + rsi -1]
	jmp .reversetest

.reverseloop:
    mov al, [rdx]
    mov ah, [rcx]
    mov [rcx], al
    mov [rdx], ah
    inc rdx
    dec rcx

.reversetest:
    cmp rdx, rcx
    jl .reverseloop

    mov rax, rsi                    ; Devuelve la longitud de la cadena
    ret


section .data
    text_start db 'hola me llamo sandia carrasco y me gusta las sandia amarrilla no la roja es que la roja es fea, ademas la gente solo piensa en la sandia roja esto es una palabra por favor me gusta holi.', 0
