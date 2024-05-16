section .data
    filename1 db 'input1.txt', 0
    filename2 db 'input2.txt', 0
    line_num dq 1
    error_message db 'Failed to open file.', 0xa, 0
    line_message_up db '----No hay una línea anterior----', 0xa, 0
    line_message_down db '----Fin del documento----', 0xa, 0
    same_text db '----El texto no tiene diferencias----', 0xa, 0
    printCont dq 0
    espacio db 10
     ; Define scan codes for arrow keys
    clear_screen db 33o, "[2J"  	 ; ANSI escape sequence to clear the screen
    null_flag db 0
    diff_flag db 0
    line_diff_message db 'Diferencia encontrada en la linea: ', 0
	new_line db 0xa, 0
	
section .bss 
    buffer1 resb 2050
    buffer2 resb 2050
    bufferItoa resb 2050
    bufferNum resb 2050
    wordCount resq 1                 ; Counter for words
    lineCount resq 1                 ; Counter for lines
    lineCount2 resq 1                 ; Counter for lines
    user_input resb 2           	 ; Buffer to store user input
    lineLengths resq 10    ; Array to store lengths of each line
    lineLengths2 resq 10
    file_descriptors resq 2 
    
section .text
    global _start

_start:
    call _openFiles	

    cmp rax, -2
    je error_occurred   	
        	
    call _readFiles     
	
	mov r9, buffer1
    mov r12, lineLengths
    call store_text
    mov qword [lineCount], r10
	
	mov r9, buffer2
    mov r12, lineLengths2
	call store_text
	mov qword [lineCount2], r10
	
	call compare
	
	mov r9, buffer1
	call _genericprint
	
	call get_input

   ; Cerrar
    mov rax, 3
    mov rdi, [file_descriptors]
    syscall
    mov rdi, [file_descriptors+8]
    syscall        

    ; Salir del programa
    jmp _finishCode

error_occurred:           
	mov rax, error_message
	call _genericprint
	jmp _finishCode

_openFiles:
    ; Open the first file
    mov rax, 2
    mov rdi, filename1
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .error
    mov [file_descriptors], rax

    ; Open the second file
    mov rax, 2
    mov rdi, filename2
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .error
    mov [file_descriptors+8], rax
    ret

.error:
    mov rax, -2
    ret

_readFiles:
    ; Read the first file
    mov rax, 0
    mov rdi, [file_descriptors]
    mov rsi, buffer1
    mov rdx, 2050
    syscall

    ; Read the second file
    mov rax, 0
    mov rdi, [file_descriptors+8]
    mov rsi, buffer2
    mov rdx, 2050
    syscall
    ret

;--------------------BEGIN COMPARE

compare:
	xor rax, rax
	xor rdx, rdx
	xor rcx, rcx
	xor rbx, rbx
	xor r8, r8
	xor rsi, rsi
	xor r14, r14
	mov byte [diff_flag], 0
	mov rax, 0 ;Contador de indice del buffer1
	mov rsi, 0 ;Contador de indice del buffer2
	mov rdx, 0 ;Num de chars en LineLengths
	mov rcx, 0 ;Num de chars en LineLengths2
	mov r8, 0  ;Conatdor de los chars
	
	mov rbx, qword[lineCount]
	cmp rbx, qword[lineCount2]
	jge establish_lineCount
	mov r15, qword[lineCount2]
	mov rbx, 0 ;Contador de posiciones en los LineLengths/2
	jmp compare_loop_lines

establish_lineCount:
	mov r15, qword[lineCount]
	mov rbx, 0 ;Contador de posiciones en los LineLengths/2

compare_loop_lines:
	cmp rbx, r15
	je textos_iguales
	
	mov rdx, [lineLengths + rbx * 8]
	mov rcx, [lineLengths2 + rbx * 8]
	
	cmp rdx, rcx
	jne diferencia_lineas_count
	jmp compare_loop_chars

cont_compare_loop:
	mov r8, 0
	inc rbx
	jmp compare_loop_lines

compare_loop_chars:
	cmp r8, rdx
	je cont_compare_loop
	
	mov r10b, byte[buffer1 + rax]
	mov r11b, byte[buffer2 + rsi]
	
	cmp r10b, r11b
	jne diferencia_lineas
	
	inc rax
	inc rsi
	inc r8
	jmp compare_loop_chars

diferencia_lineas:
	mov byte [diff_flag], 1
	push rax
	push rbx
	push rcx
	push rdx
	push r8
	push rsi
	push r14
	mov rax, line_diff_message
	call _genericprint2
	mov rcx, rbx
	call _startItoa
	pop r14
	pop rsi
	pop r8
	pop rdx
	pop rcx
	pop rbx
	pop rax
	
	inc rbx
	inc r8
	sub r8, rdx
	neg r8
	add rax, r8
	add rsi, r8
	mov r8, 0
	jmp compare_loop_lines

diferencia_lineas_count:
	mov byte [diff_flag], 1	
	push rax
	push rbx
	push rcx
	push rdx
	push r8
	push rsi
	push r14
	mov rax, line_diff_message
	call _genericprint2
	mov rcx, rbx
	call _startItoa
	pop r14
	pop rsi
	pop r8
	pop rdx
	pop rcx
	pop rbx
	pop rax
	
	inc rbx
	add rax, rdx
	add rsi, rcx
	jmp compare_loop_lines

textos_iguales:
	cmp byte[diff_flag], 1
	je diferencias_encontradas
	
	mov rax, same_text
	call _genericprint2
	
diferencias_encontradas:
	ret
	 	 
;----------------------------------------------------------------------
store_text:
    mov r10, 0
    mov qword [printCont], 0        ; Inicializar contador de caracteres por linea
    mov qword [wordCount], 0        ; Inicializar contador de palabras
    mov r8, r9                      ; Guardar el valor del texto en r8
    mov byte [null_flag], 0			; Colocar flag de última línea

_storeLoop:
    mov cl, [r9]
    cmp cl, 0
    je null_flag_encounter				; Terminar impresión si se encuentra un null

    ; Revisar si el actual caracter es un espacio, tab o enter 
    cmp cl, ' '
    je _checkBoundary
    cmp cl, 9
    je _checkBoundary
    cmp cl, 10
    je _checkBoundary

    inc qword [printCont]           ; Incrementar contador de caracter
    inc r9                          ; Moverse al siguiente caracter
    jmp _storeLoop					; Seguir en el loop

_checkBoundary:
    inc qword [printCont]           ; Incrementar contador de caracter
    inc qword [wordCount]           ; Incrementar contador de palabras

    cmp qword [wordCount], 10       ; Revisar si ya se tienen las 10 palabras
    jne _continueStoring
    
    jmp _endStore

null_flag_encounter:
	mov byte [null_flag], 1			; Colocar flag de última línea

_endStore:
    call store
	
	cmp byte[null_flag], 1
	je end_loop_store
	
	jmp _storeLoop

_continueStoring:
    inc r9                          ; Moverse al siguiente caracter
    jmp _storeLoop					; Seguir con el loop

store:
    push rdi
    push r12
    push r10
    mov rdi, qword[printCont]		; Se guarda el contador de caracteres de la línea en un registro
    mov qword [r12 + r10 * 8], rdi	; Se guarda la cantidad de caracteres de la línea actual en la variable lineLengths
    pop r10
    pop r12
    pop rdi
    
	
	add r8, [printCont]				; Avanza a la siguiente línea
	inc r9							; Se incrementa el puntero para que apunte a la primera letra de la línea
	inc r10
    
    mov qword [wordCount], 0        ; Se resetea el contador de palabras
    mov qword [printCont], 0        ; Se resetea el contador de caracteres
    
    ret

end_loop_store:
	ret


; -------------------END COMPARE

_genericprint:
    mov qword [lineCount], 0    	; Inicializar contador de líneas
    mov qword [lineCount2], 0    	; Inicializar contador de líneas
    mov qword [printCont], 0        ; Inicializar contador de caracteres por linea
    mov qword [wordCount], 0        ; Inicializar contador de palabras
    mov r8, r9                      ; Guardar el valor del texto en e8

_printLoop:
    mov cl, [r9]
    cmp cl, 0
    je null_flag_line				; Terminar impresión si se encuentra un null

    ; Revisar si el actual caracter es un espacio, tab o enter 
    cmp cl, ' '
    je _checkWordBoundary
    cmp cl, 9
    je _checkWordBoundary
    cmp cl, 10
    je _checkWordBoundary

    inc qword [printCont]           ; Incrementar contador de caracter
    inc r9                          ; Moverse al siguiente caracter
    jmp _printLoop					; Seguir en el loop

_checkWordBoundary:
    inc qword [printCont]           ; Incrementar contador de caracter
    inc qword [wordCount]           ; Incrementar contador de palabras

    cmp qword [wordCount], 10       ; Revisar si ya se tienen las 10 palabras
    jne _continuePrinting
    
    jmp _endPrint

null_flag_line:
	mov byte [null_flag], 1			; Colocar flag de última línea

_endPrint:
    mov rax, 1
    mov rdi, 1
    mov rdx, [printCont]			; Variable de cantidad de caracteres
    mov rsi, r8						; Contiene el inicio de la línea
    syscall
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    ret

_continuePrinting:
    inc r9                          ; Moverse al siguiente caracter
    jmp _printLoop					; Seguir con el loop

; Leer input del usuario
get_input:
    mov rax, 0
    mov rdi, 0
    mov rsi, user_input
    mov rdx, 2
    syscall

	; Comparar el input a las letras
    cmp byte[user_input], 'u'		; Up, se mueve una línea de texto hacia arriba
    je .move_up
    cmp byte[user_input], 'd'		; Down, se mueve una línea de texto hacia arriba
    je .move_down
    cmp byte[user_input], 'q'		; Quit, se sale del programa
    je _finishCode

    jmp get_input            		; Se repite el loop para seguir leyendo los inputs

; Si se presiona la 'u'
.move_up:
	mov byte [null_flag], 0
	
	cmp qword [lineCount], 0
    je no_prev_line
	
	dec qword [lineCount]			; Se decrementa el contador de líneas
	
	push rbx
	push rsi
	push rcx
    mov rbx, qword [lineCount]		; Se guarda el contador de líneas en un registro
    mov rsi, lineLengths			; Se guarda la variable de la lista de tamaños de líneas en un registro
    mov rcx, [rsi + rbx * 8]   		; Se obtiene el valor almacenado en la lista de tamaños de líneas
    sub r8, rcx						; Se le resta el resultado obtenido al puntero del inicio de la línea actual
    pop rcx
    pop rsi
    pop rbx
	
    mov r9, r8						; Se guarda el valor en el otro puntero del texto
	
    mov qword [wordCount], 0        ; Se resetea el contador de palabras
    mov qword [printCont], 0        ; Se resetea el contador de caracteres
    
    call _printLoop					; Se imprime la línea actual
    
    jmp get_input					; Se vuelve a pedir el input

; Si se presiona la 'd'
.move_down:
    cmp byte[null_flag], 1			; Si el null flaf está prendida, es la última línea del texto
    je last_line
    
    push rbx
    push rsi
    mov rbx, qword[lineCount]		; Se guarda el contador de líneas en un registro
    mov rsi, lineLengths			; Se guarda la variable de la lista de tamaños de líneas en un registro
    mov rdi, qword[printCont]		; Se guarda el contador de caracteres de la línea en un registro
    mov qword [rsi + rbx * 8], rdi	; Se guarda la cantidad de caracteres de la línea actual en la variable lineLengths
    pop rdi
    pop rsi
    pop rbx

	add r8, [printCont]				; Avanza a la siguiente línea
	inc r9							; Se incrementa el puntero para que apunte a la primera letra de la línea
	inc qword [lineCount]			; Se incrementa el contador de líneas
    
    mov qword [wordCount], 0        ; Se resetea el contador de palabras
    mov qword [printCont], 0        ; Se resetea el contador de caracteres
    
    call _printLoop

    jmp get_input

; Cuando se está al incio del texto
no_prev_line:
	; Imprimir texto
    mov rax, 1
    mov rdi, 1
    mov rsi, line_message_up
    mov rdx, 36
    syscall
    
    jmp get_input

; Cuando se está al final del texto
last_line:
	; Imprimir texto
    mov rax, 1
    mov rdi, 1
    mov rsi, line_message_down
    mov rdx, 27
    syscall
    
    jmp get_input


;----------------------ITOA
_startItoa:
	mov rdi, bufferItoa
    mov rsi, rcx 
    mov rbx, 10       ; La base
    call itoa
    mov r8, rax
    
    mov byte [bufferItoa + r8], 10
    inc r8
    
    mov byte [bufferItoa + r8], 0

    mov rax, bufferItoa
    
    mov rax, bufferItoa
    call _genericprint2
    
    ret

itoa:
    mov rax, rsi
    mov rsi, 0
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

    mov rax, rsi
    ret
;-------------Fin Itoa---------------------------


_genericprint2:
    mov qword [printCont], 0        ;coloca rdx en 0 (contador)
    push rax        ;almacenamos lo que esta en rax

_printLoop2:
    mov cl, [rax]
    cmp cl, 0
    je _endPrint2
    inc qword [printCont]                ;aumenta contador
    inc rax
    jmp _printLoop2

_endPrint2:
    mov rax, 1
    mov rdi, 1
    mov rdx,[printCont]
    pop rsi            ;texto
    syscall
    ret

; Se termina el programa
_finishCode:
	mov rax, 60
	mov rdi, 0
	syscall
