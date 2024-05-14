section .data
    filename db 'input.txt', 0
    error_message db 'Failed to open file.', 0xa, 0
    line_message_up db '----No hay una línea anterior----', 0xa, 0
    line_message_down db '----Fin del documento----', 0xa, 0
    printCont dq 0
    espacio db 10
     ; Define scan codes for arrow keys
    clear_screen db 33o, "[2J"  	 ; ANSI escape sequence to clear the screen
    null_flag db 0

section .bss 
    buffer resb 2050
    bufferNum resb 2050
    wordCount resq 1                 ; Counter for words
    lineCount resq 1                 ; Counter for lines
    user_input resb 2           	 ; Buffer to store user input
    lineLengths resq 10    ; Array to store lengths of each line
    
section .text
    global _start

_start:

    call _openFile		; Abre el archivo a leer

    cmp rax, -2         	; Comprobar si hay error al abrir el archivo
    je error_occurred   	; Si eax es -1, se produjo un error

    mov rsi, rax        	; Guardar el descriptor del archivo en esi
    call _readFile 

    mov r9, buffer ;Imprimir el texto
    call _genericprint
    
    ;Imprimir un espacio
    mov rax, 1          
    mov rdi, 1          
    mov rsi, espacio    
    mov rdx, 1          
    syscall
    
    call get_input
    
    ; Write the escape sequence to clear the screen
    ;mov rax, 1          ; System call for write
    ;mov rdi, 1          ; File descriptor 1 (stdout)
    ;mov rsi, clear_screen  ; Pointer to the clear screen escape sequence
    ;mov rdx, 4          ; Length of the escape sequence
    ;syscall             ; Call kernel
     
    ; Cerrar el archivo
    mov rax, 3             
    mov rdi, rsi        
    syscall               

    ; Salir del programa
    jmp _finishCode

error_occurred:           
	mov rax, error_message
	call _genericprint
	jmp _finishCode

_openFile:
    mov rax, 2          	; Para abrir el documento
    mov rdi, filename      	; Documento a leer
	mov rsi, 0              ; read only
	mov rdx, 0
    syscall                 
	ret

_readFile:
	mov rax, 0              ; Para leer el documento
	mov rdi, rsi             
	mov rsi, buffer         ; Pointer a buffer
	mov rdx, 2050           ; Tamano
	syscall
	ret
    
_genericprint:
    mov qword [lineCount], 0    	; Inicializar contador de líneas
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

; Se termina el programa
_finishCode:
	mov rax, 60
	mov rdi, 0
	syscall
