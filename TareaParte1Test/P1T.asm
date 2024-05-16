section .data
    espacio db 10             ; New line character for syscalls
    text_start db 'hola me llamo sandia carrasco y me gusta las sandia amarrilla no la roja es que la roja es fea, ademas la gente solo piensa en la sandia roja esto es una palabra por favor me gusta holi.', 0
	; --Menu
	text_menuInicial db 'Bienvenido a el editor de documnetos, que desea realizar?', 0
	text_menuInicialCont db 'a) Editar un documento b) Terminar Programa', 0
	;-- Edit file
	text_escojaLineaEF  db 'Por favor seleccione la linea que desea modificar',0
	text_ingreseDocumento db 'Por favor ingrese un documento', 0
	flag_printOnePhrase db 0
	testInput db '2',10,0
	

section .bss
	user_input resb 5 
    lineCount resq 1          ; Initialize line count
    printCont resq 1          ; Initialize print content count
    wordCount resq 1          ; Initialize word count
    lastPrint resq 1          ; Pointer to start of last printed word
    buffer resb 2050

section .text
    global _start

_start:
	mov rax, text_menuInicial
    call _genericprint  
    call _enterPrint 
    
    mov rax, text_menuInicialCont
    call _genericprint   
    call _enterPrint
    
    
    call get_input
    call menu_compare
    
    jmp _finishCode

;-------------- INTERACCION CON EL USUARIO -----------------------
get_input:
    mov rax, 0
    mov rdi, 0
    mov rsi, user_input
    mov rdx, 2
    syscall
    ret

menu_compare:   
    cmp byte[user_input], 'a'		; Up, se mueve una línea de texto hacia arriba
    je _manageEdit
    cmp byte[user_input], 'b'		; Quit, se sale del programa
    je _finishCode
    ret

;-------------- INTERACCION CON EL USUARIO -----------------------  
    
;-------------- PRINT DE TODO EL DOCUMENTO CON SUS LINEAS --------------
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
    
    cmp byte[flag_printOnePhrase], 0
    je _firstcontinueBoundary

    
    
    mov rax, user_input ; Load '1' from userInput into AL
    ;mov rbx, [buffer]    ; Load '1' from buffer into BL
    ;mov rsi, rbx
    call _genericprint
    
    xor rax, rax
    mov rax, testInput ; Load '1' from userInput into AL
    ;mov rbx, [buffer]    ; Load '1' from buffer into BL
    ;mov rsi, rbx
    call _genericprint
    xor rax, rax
    mov rax, user_input ; Load '1' from userInput into AL
    
    cmp rax, [testInput]
    jne _skipLinePLTE
    
    _firstcontinueBoundary:
    ;mov rax, 1
    ;mov rdi, 1
    ;mov rsi, buffer
    ;mov rdx, 5              ; Number of characters from lastPrint to current position
    ;syscall


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
    
    cmp qword[flag_printOnePhrase], 1
    je _endPrintFP
    
    jmp _continueBoundary
    
    _skipLinePLTE:				; CHEQUEO por si no se necesita el print

	mov rdx, r9
	sub rdx, [lastPrint]        ; Calculate length to print
	test rdx, rdx               ; Check if length is positive
	jle _endPrintFP              ; Skip printing if length is not positive
	syscall 

	_continueBoundary:
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
    call _enterPrint
    call _enterPrint
    ret

    

    
;-------------- PRINT DE TODO EL DOCUMENTO CON SUS LINEAS --------------

;--------------------- MANEJO DE EDICION DE CODIGO ---------------------
_manageEdit:
	mov byte[flag_printOnePhrase],0
	call _startFullPrint
    mov rax, text_escojaLineaEF
    call _genericprint   
    call _enterPrint
    
    call get_input
    mov byte[flag_printOnePhrase],1
    call _startFullPrint
    ret

;--------------------- MANEJO DE EDICION DE CODIGO ---------------------  
;-------------------------------- ITOA ---------------------------------
_startItoa: 
    mov rdi, buffer
    mov rsi, rsi 
    mov rbx, 10       ; La base
    call itoa
    mov r8, rax                     ; Almacena la longitud de la cadena
    
    ; Añade un salto de línea
    ;mov byte [buffer + r8], 10
    ;inc r8
    
    ; Termina la cadena con null
    ;mov byte [buffer + r8], 0

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
;-------------------------------- ITOA ---------------------------------

;------------------------- GENERIC PRINT -------------------------------
_genericprint:
    mov qword [printCont], 0        ;coloca rdx en 0 (contador)
    push rax        ;almacenamos lo que esta en rax

_printLoop:
    mov cl, [rax]
    cmp cl, 0
    je _endPrint
    inc qword [printCont]                ;aumenta contador
    inc rax
    jmp _printLoop

_endPrint:
    mov rax, 1
    mov rdi, 1
    mov rdx,[printCont]
    pop rsi            ;texto
    syscall
    ret
    
_enterPrint:
    mov rax, 1
    mov rdi, 1
    lea rsi, [espacio]        ; Load the address of the newline character
    mov rdx, 1                ; Length is 1
    syscall
    ret
;------------------------- GENERIC PRINT -------------------------------
_finishCode:
	mov rax, 60
	mov rdi, 0
	syscall



