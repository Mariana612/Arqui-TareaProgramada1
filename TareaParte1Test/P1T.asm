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
	lentext dq 0 
	lenUserText dq 0
	lenStartingText dq 0

	

section .bss
	user_input resb 2050
    lineCount resq 1          ; Initialize line count
    printCont resq 1          ; Initialize print content count
    wordCount resq 1          ; Initialize word count
    lastPrint resq 1          ; Pointer to start of last printed word
    lenPrint resq 1
    lenFirstPart resq 1
    sumPrint resq 1
    new_text resb 2050 ; Buffer para el texto final.
    
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
    mov rdx, 2050
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
    mov [lastPrint], r9       ; Initialize lastPrint to start of text
    
    

_fullPrint:
    xor rax, rax              ; Clear rax
    mov qword [lineCount], 0    	; Inicializar contador de líneas
    mov qword [printCont], 0        ; Inicializar contador de caracteres por linea
    mov qword [wordCount], 0
    mov qword[lenFirstPart], -1

_printLoopFP:
    mov cl, [r9]
    test cl, cl
    jz _endPrintFP              ; End if NULL character is reached
    inc qword[lenFirstPart]

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


    mov rax, [buffer] ; Load '1' from userInput into AL
    mov rbx, [user_input]    ; Load '1' from buffer into BL

    cmp rax, rbx
    jne _skipLinePLTE
    
    _firstcontinueBoundary:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 5              ; Number of characters from lastPrint to current position
    syscall


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
    
    cmp byte[flag_printOnePhrase], 1
    je _finishSpecialFP
    
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
    
    cmp byte[flag_printOnePhrase], 0
    je _firstcontinueEP

    mov rax, [buffer] ; Load '1' from userInput into AL
    mov rbx, [user_input]    ; Load '1' from buffer into BL

    cmp rax, rbx
    jne _finishSpecialFP
    
    _firstcontinueEP:
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
   
_finishSpecialFP:
	mov rsi, [lastPrint]      ; Get the pointer to the last printed position
    mov rdx, r9               ; Get the current position in text
    sub rdx, rsi
    mov qword[lenPrint], rdx
    

	ret
 
;-------------- PRINT DE TODO EL DOCUMENTO CON SUS LINEAS --------------

;--------------------- MANEJO DE EDICION DE CODIGO ---------------------
_manageEdit:
	mov byte[flag_printOnePhrase],0
	mov r9, text_start 
	call _startFullPrint
    mov rax, text_escojaLineaEF
    call _genericprint   
    call _enterPrint
    
    call get_input
    mov byte[flag_printOnePhrase],1
    mov r9, text_start 
    call _startFullPrint
    call get_inputSPECIAL
    
    call _getInputInfo
    mov byte[flag_printOnePhrase],0
    call _editText
    
    ret

_getInputInfo:
	mov rdi, user_input 
	call _calculate_size
	
	mov rax, qword[lentext]
	mov qword[lenUserText], rax
	
	;---- texto original
	mov rdi, text_start 
	call _calculate_size
	
	mov rax, qword[lentext]
	mov qword[lenStartingText], rax

	ret
	
get_inputSPECIAL:
    mov rax, 0         ; syscall number for read
    mov rdi, 0         ; file descriptor 0 (stdin)
    mov rsi, user_input; buffer to store the input
    add rsi, 1         ; Adjust buffer pointer to leave space for the space character
    mov rdx, 2049      ; reduce max bytes by one to account for the space at the start
    syscall            ; perform the syscall

    ; Assuming rax contains the number of bytes read, adjust for newline character
    test rax, rax      ; Check if any bytes were read
    jz input_done      ; Jump if zero bytes were read (skip if input is empty)

    dec rax            ; Decrement rax to exclude the newline character from the count
    mov byte [rsi + rax], 0 ; Replace newline with null terminator

    ; Insert space at the beginning of the buffer
    dec rsi            ; Move back to the start of the buffer
    mov byte [rsi], ' '; Insert space character

input_done:
    ret                ; Return from the function
 
    
_editText:
    ; Copia la primera parte al buffer nuevo
    mov r8, [lenFirstPart] 
    sub r8, [lenPrint]
    
    mov rsi, text_start
    mov rdi, new_text
    mov rcx, r8 ; Termina la primera línea más un espacio
    rep movsb

    ; Añade text_test
    mov rsi, user_input
    mov rcx, [lenUserText]  ; Longitud de 'xd ' sin contar el null terminator
    rep movsb
    

	mov r9, [lenStartingText]
	sub r9, [lenFirstPart]
	
	mov rsi, text_start
    add rsi, [lenFirstPart]  ; Salta la primera y segunda línea
    mov rcx, r9 ; Longitud total menos lo ya copiado
    rep movsb

	mov r9, new_text 
	call _startFullPrint
	
    ;mov rax, new_text
    ;call _genericprint

	ret


;--------------------- MANEJO DE EDICION DE CODIGO ---------------------  
;-------------------------------- ITOA ---------------------------------
_startItoa: 
    mov rdi, buffer
    mov rsi, rsi 
    mov rbx, 10       ; La base
    call itoa
    mov r8, rax                     ; Almacena la longitud de la cadena
    
    ;Añade un salto de línea
    cmp byte[flag_printOnePhrase], 0
    jne _continueitoaNS
    mov byte [buffer + r8], ' '
    inc r8
    jmp _enditoa
    
    
    _continueitoaNS:
    mov byte [buffer + r8], 10
    inc r8
    
    _enditoa:
    
    ; Termina la cadena con null
    mov byte [buffer + r8], 0
    
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
;---------------------------- MISCELANEO -------------------------------
_finishCode:
	mov rax, 60
	mov rdi, 0
	syscall
	

_calculate_size:
    push rdi    ; Guarda el valor original de RDI
    xor rcx, rcx    ; RCX será nuestro contador de caracteres

count_loopCS:
    cmp byte [rdi], 0    	; Compara el carácter actual con 0 (carácter nulo)
    je end_loop    			; Si es cero, termina el bucle
    inc rdi    				; Incrementa el puntero al siguiente carácter
    inc rcx    				; Incrementa el contador de caracteres
    jmp count_loopCS   		; Repite el bucle

end_loop:
    mov [lentext], rcx    	; Escribe el contador en la variable 'len'
    pop rdi    				; Restaura el valor original de RDI
    ret    					; Retorna de la función
	
;---------------------------- MISCELANEO -------------------------------


