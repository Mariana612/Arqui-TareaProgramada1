section .data
    text_start db 'hola me llamo sandia carrasco y me gusta las sandia amarrilla no la roja es que la roja es fea, ademas la gente solo piensa en la sandia roja esto es una palabra por favor me gusta holi.', 0
	;-- Edit file
	text_escojaLineaEF  db 'Por favor seleccione la linea que desea modificar: ',0
	flag_printOnePhrase db 0
	lentext dq 0 
	lenUserText dq 0
	lenStartingText dq 0
	
	;--Manejo Dinamico Files
	text_ingreseDocumento db 'Ingrese la direccion de un Documento: ', 0xa, 0
	
    ; DECORACIONES
    deco1 db '  =================================================$', 0xa, 0
    deco2 db '||         Editor y Comparador de Archivos         ||$', 0xa, 0
    deco3 db '||                                                 ||$', 0xa, 0
    deco4 db '||                                                 ||$', 0xa, 0
    deco5 db '||            Carmen, Mariana & Valeria            ||$', 0xa, 0
    deco6 db '  =================================================$', 0xa, 0
    decoVer 	 db '||                   Ver Archivo                   ||$', 0xa, 0
    decoEditar 	 db '||                 Editar  Archivo                 ||$', 0xa, 0
    decoComparar db '||               Comparar 2 Archivos               ||$', 0xa, 0
    ; INSTRUCCIONES
    instruction_initial1 db '----- Presionar: v = Ver archivo, e = Editar archivo -----', 0xa, 0
    instruction_initial2 db '   -----    c = Comparar 2 archivos, s = Salir -----   ', 0xa, 0
    instruction_scroll1 db '----- Presionar: u = Ir a línea anterior, d = Siguiente línea -----', 0xa, 0
    instruction_scroll2 db '-- h = Ver texto en hexadecimal, q = Regresar al menú principal --', 0xa, 0
    instruction_edit db '----- Presionar: u = Ir a línea anterior, d = Siguiente línea -----', 0xa, 0
    instruction_compare db '----- Presionar: q = Regresar al menú principal -----', 0xa, 0
    option db '--Ingresar opción: ', 0
    option_no_valida db '--Opción Incorrecta Ingresada, por favor ingresar la correcta: ', 0
    filename1 db 'input1.txt', 0
    filename2 db 'input2.txt', 0
    line_num dq 1
    ; MENSAJES DE AYUDA
    error_message db 'Archivo no se pudo abrir', 0xa, 0
    error_message_size db 'Archivo muy grande', 0xa, 0
    line_message_up db '----No hay una línea anterior----', 0xa, 0
    line_message_down db '----Fin del documento----', 0xa, 0
    same_text db '----El texto no tiene diferencias----', 0xa, 0
    line_diff_message db 'Diferencia encontrada en la linea: ', 0
    ; VARIABLES
    printCont dq 0
    espacio db 10
    new_line db 0xa, 0
    clear_screen db 0x1B, '[2J', 0x1B, '[H' ; Combine clear screen and cursor to top-left
    statbuf  times 144 db 0
    ; FLAGS
    null_flag db 0
    diff_flag db 0
	
section .bss
	user_input resb 4097
	user_input_line resb 4097
    lastPrint resq 1          ; Pointer to start of last printed word
    lenPrint resq 1
    lenFirstPart resq 1
    sumPrint resq 1
    new_text resb 4097 ; Buffer para el texto final.
    buffer resb 4097
	
    ; BUFFERS PARA GUARDAR VARIABLES
    buffer1 resb 4097
    buffer2 resb 4097
    bufferItoa resb 4097
    bufferNum resb 4097
    readFileBuffer resb 4097
    compareText1 resb 4097
    compareText2 resb 4097
    ; CONTADORES
    wordCount resq 1                 ; Counter for words
    lineCount resq 1                 ; Counter for lines
    lineCount2 resq 1                 ; Counter for lines
    ; INPUTS
    user_input_edit resb 2           	 ; Buffer to store user input
    user_input_comp resb 2           	 ; Buffer to store user input
    user_input_scroll resb 2           	 ; Buffer to store user input
    user_input_initial resb 2           	 ; Buffer to store user input
    ; ARRAYS
    lineLengths resq 10    ; Array to store lengths of each line
    lineLengths2 resq 10
    ; EXTRAS
    file_descriptors resq 2 
    fd resd 1                          ; File descriptor
    filesize resq 1                    ; Variable to store the file size
    dynamicFile resb 4097
    file_desc resb 8 
    
section .text
    global _start

_start:
	call clrScrn		   ; Limpiar pantalla
	;----------------------Imprimir decoraciones
    mov rax, deco1
    call _genericprint
    mov rax, deco2
    call _genericprint
    mov rax, deco3
    call _genericprint
    mov rax, deco4
    call _genericprint
    mov rax, deco5
    call _genericprint
    mov rax, deco6
    call _genericprint
    mov rax, instruction_initial1
    call _genericprint
    mov rax, instruction_initial2
    call _genericprint
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    ; Imprimir texto
    mov rax, option
	call _genericprint

    call get_input_initial		; Input del usuario
;--------------------------------------------------------

_openFiles:					; Abrir archivo
    ; Abre el primer archivo
    mov rax, 2
    mov rdi, filename1
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .error
    mov [file_descriptors], rax

    ; Abre el segundo archivo
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

_readFiles:					; Leer archivos
    ; Lee el primer archivo
    mov rax, 0
    mov rdi, [file_descriptors]
    mov rsi, buffer1
    mov rdx, 2050
    syscall

    ; Lee el segundo archivo
    mov rax, 0
    mov rdi, [file_descriptors+8]
    mov rsi, buffer2
    mov rdx, 2050
    syscall
    ret

;---------------------------------------------- COMPARE TEXTOS

compare:
	xor rax, rax
	xor rdx, rdx
	xor rcx, rcx
	xor rbx, rbx
	xor r8, r8
	xor rsi, rsi
	xor r14, r14
	mov byte [diff_flag], 0 ; Bandera de diferencia
	mov rax, 0 ; Contador de indice del buffer1
	mov rsi, 0 ; Contador de indice del buffer2
	mov rdx, 0 ; Num de chars en LineLengths
	mov rcx, 0 ; Num de chars en LineLengths2
	mov r8, 0  ; Contador de los chars
	
	mov rbx, qword[lineCount]
	cmp rbx, qword[lineCount2] ; Comparar cuál de los textos tiene más líneas 
	jge establish_lineCount
	
	mov r15, qword[lineCount2]
	mov rbx, 0 ; Contador de posiciones en los LineLengths y LineLengths2
	jmp compare_loop_lines

establish_lineCount:
	mov r15, qword[lineCount]
	mov rbx, 0 ; Contador de posiciones en los LineLengths y LineLengths2

compare_loop_lines:
	cmp rbx, r15
	je textos_iguales ;Los textos son iguales
	
	mov rdx, [lineLengths + rbx * 8]  ; Obtiene el lenght del array lineLengths
	mov rcx, [lineLengths2 + rbx * 8] ; Obtiene el lenght del array lineLengths2
	
	cmp rdx, rcx                      ; Compara los lengths de ambas lineas
	jne diferencia_lineas_count       ; Si son diferentes va a diferencia_lineas_count que es para cuando las lineas tienen distintos tamanos
	jmp compare_loop_chars            ; Si no continua el ciclo

cont_compare_loop:
	mov r8, 0                         ; Limpia r8
	inc rbx                           ; Aumenta contador
	jmp compare_loop_lines

compare_loop_chars:
	cmp r8, rdx                       ; Compara el contador de caracteres con el tamano de la linea
	je cont_compare_loop              ; Son iguales salta a cont_compare_loop
	
	mov r10b, byte[buffer1 + rax]     ; Carga un byte del buffer1 en el registro
	mov r11b, byte[buffer2 + rsi]     ; Carga un byte del buffer2 en el registro
	
	cmp r10b, r11b
	jne diferencia_lineas
	
	inc rax                           ; Incrementa el indice del buffer1
	inc rsi                           ; Incrementa el indice del buffer2
	inc r8                            ; Incrementa el contador de caracteres
	jmp compare_loop_chars

diferencia_lineas:
	mov byte [diff_flag], 1
	mov r13, rdx
	; Guarda los registros en pila
	push rax
	push rbx
	push rcx
	push rdx
	push r8
	push rsi
	push r14
	mov rax, line_diff_message
	call _genericprint
	
	mov byte [flag_printOnePhrase], 1
	mov rsi, rbx                      ; Carga el contador de lineas
	call _startItoa
	mov rax, buffer
	call _genericprint
	
	;mov r9, buffer1
	;mov qword [printCont], 0        ; Inicializar contador de caracteres por linea
    ;mov qword [wordCount], 0        ; Inicializar contador de palabras
    ;mov r8, r9                      ; Guardar el valor del texto en r8
    ;add r8, r13
    ;add r9, r13
	;call _printLoop
	;mov r9, buffer2
	pop r14
	pop rsi
	pop r8
	pop rdx
	pop rcx
	pop rbx
	pop rax
	
	inc rbx                        ; Incrementa el contador de lineas
	inc r8                         ; Incrementa el contador de caracteres
	sub r8, rdx                    ; Ajusta r8 restando el tamaño de la linea actual
	neg r8						   ; Cambia signo de r8 a positivo
	add rax, r8                    ; Ajusta indice de buffer1
	add rsi, r8                    ; Ajusta indice de buffer2
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
	call _genericprint
	
	mov byte [flag_printOnePhrase], 1
	mov rsi, rbx
	call _startItoa
	mov rax, buffer
	call _genericprint
	
	pop r14
	pop rsi
	pop r8
	pop rdx
	pop rcx
	pop rbx
	pop rax
	
	inc rbx                          ; Incrementa el contador de lineas
	add rax, rdx                     ; Ajusta indice de buffer1
	add rsi, rcx                     ; Ajusta indice de buffer2
	jmp compare_loop_lines

textos_iguales:
	cmp byte[diff_flag], 1           ; Si la bandera esta encendida salta salta a diferencias_encontradas
	je diferencias_encontradas       
	
	mov rax, same_text
	call _genericprint
	
diferencias_encontradas:
	ret

;---------------------------------------------- FIN COMPARE TEXTOS

;---------------------------------------------- GUARDAR TEXTOS

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


;---------------------------------------------- FIN GUARDAR TEXTOS


;------------------------------------------------------------------------------------ P R I N T S


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
    mov rbx, [user_input_line]    ; Load '1' from buffer into BL

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
    mov rbx, [user_input_line]    ; Load '1' from buffer into BL

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

;--------------------- MANEJO DE EDICION DE CODIGO ---------------------

_manageEdit:
	mov byte[flag_printOnePhrase],0
	mov r9, readFileBuffer 
	call _startFullPrint
    mov rax, text_escojaLineaEF
    call _genericprint   
    call _enterPrint
    
    call get_input_line
    mov byte[flag_printOnePhrase],1
    mov r9, readFileBuffer 
    call _startFullPrint
    call get_inputSPECIAL
    
    call _getInputInfo
    mov byte[flag_printOnePhrase],0
    call _editText
    
    ret

_getInputInfo:
	mov rdi, user_input_line
	call _calculate_size
	
	mov rax, qword[lentext]
	mov qword[lenUserText], rax
	
	;---- texto original
	mov rdi, readFileBuffer
	call _calculate_size
	
	mov rax, qword[lentext]
	mov qword[lenStartingText], rax

	ret
	
get_inputSPECIAL:
    mov rax, 0         ; syscall number for read
    mov rdi, 0         ; file descriptor 0 (stdin)
    mov rsi, user_input_line; buffer to store the input
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
    
    mov rsi, readFileBuffer
    mov rdi, new_text
    mov rcx, r8 ; Termina la primera línea más un espacio
    rep movsb

    ; Añade text_test
    mov rsi, user_input_line
    mov rcx, [lenUserText]  ; Longitud de 'xd ' sin contar el null terminator
    rep movsb
    

	mov r9, [lenStartingText]
	sub r9, [lenFirstPart]
	
	mov rsi, readFileBuffer
    add rsi, [lenFirstPart]  ; Salta la primera y segunda línea
    mov rcx, r9 ; Longitud total menos lo ya copiado
    rep movsb

	mov r9, new_text 
	call _startFullPrint
	
    ;mov rax, new_text
    ;call _genericprint

	ret

;---------------------------------------------- PRINT TEXTO LÍNEA POR LÍNEA

_print_ver:
    mov qword [lineCount], 0    	; Inicializar contador de líneas
    mov qword [lineCount2], 0    	; Inicializar contador de líneas
    mov qword [printCont], 0        ; Inicializar contador de caracteres por linea
    mov qword [wordCount], 0        ; Inicializar contador de palabras
    mov r8, r9                      ; Guardar el valor del texto en r8

_printLoop_ver:
    mov cl, [r9]
    cmp cl, 0
    je null_flag_line				; Terminar impresión si se encuentra un null

    ; Revisar si el actual caracter es un espacio, tab o enter 
    cmp cl, ' '
    je _checkWordBoundary_ver
    cmp cl, 9
    je _checkWordBoundary_ver
    cmp cl, 10
    je _checkWordBoundary_ver

    inc qword [printCont]           ; Incrementar contador de caracter
    inc r9                          ; Moverse al siguiente caracter
    jmp _printLoop_ver					; Seguir en el loop

_checkWordBoundary_ver:
    inc qword [printCont]           ; Incrementar contador de caracter
    inc qword [wordCount]           ; Incrementar contador de palabras

    cmp qword [wordCount], 10       ; Revisar si ya se tienen las 10 palabras
    jne _continuePrinting_ver
    
    jmp _endPrint_ver

null_flag_line:
	mov byte [null_flag], 1			; Colocar flag de última línea

_endPrint_ver:
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

_continuePrinting_ver:
    inc r9                          ; Moverse al siguiente caracter
    jmp _printLoop_ver					; Seguir con el loop

;---------------------------------------------- FIN IMPRIMIR TEXTO LÍNEA POR LÍNEA

; Clean Screen
clrScrn:
    mov rax, 1 
    mov rdi, 1
    mov rsi, clear_screen  ; Secuencia de clear screen
    mov rdx, 7
    syscall
    ret
    
;------------------------------------------------------------------------------------ I N P U T S

;---------------------------------------------- LEER INPUT DE MENÚ INICIAL
get_input_initial:
    mov rax, 0
    mov rdi, 0
    mov rsi, user_input_initial
    mov rdx, 2
    syscall
	
	; Comparar el input a las letras
    cmp byte[user_input_initial], 'v'		; Ver archivo, se mueve una línea de texto hacia arriba
    je ver_archivo
    cmp byte[user_input_initial], 'e'		; Editar archivo, se mueve una línea de texto hacia arriba
    je editar_archivo
    cmp byte[user_input_initial], 'c'		; Comparar archivos, se sale del programa
    je comparar_archivos
    cmp byte[user_input_initial], 's'		; Salir, se sale del programa
    je _finishCode
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    mov rax, option_no_valida
    call _genericprint

    jmp get_input_initial            		; Se repite el loop para seguir leyendo los inputs

;------------------------------ VER ARCHIVO
ver_archivo:
	call clrScrn
	
	mov rax, deco1
    call _genericprint
    mov rax, decoVer
    call _genericprint
    mov rax, deco6
    call _genericprint
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    mov rax, instruction_scroll1
    call _genericprint
    mov rax, instruction_scroll2
    call _genericprint
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    call _manageDinamicFile
    
    ;call _openFiles	

    ;cmp rax, -2
    ;je error_occurred   	
        	
    ;call _readFiles
    
    mov r9, readFileBuffer
	call _print_ver
	
	call get_input_ver

;------------------------------ EDITAR ARCHIVO
editar_archivo:
	call clrScrn
	
	mov rax, deco1
    call _genericprint
    mov rax, decoEditar
    call _genericprint
    mov rax, deco6
    call _genericprint
    
    mov rax, instruction_compare
    call _genericprint
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    call _manageDinamicFile
    
    call _manageEdit
    
    call get_input_edit

;------------------------------ COMPARAR ARCHIVOS
comparar_archivos:
	call clrScrn
	
	mov rax, deco1
    call _genericprint
    mov rax, decoComparar
    call _genericprint
    mov rax, deco6
    call _genericprint
    
    mov rax, instruction_compare
    call _genericprint
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    call _manageDinamicFile
    lea rsi, [readFileBuffer]   ; Fuente: dirección de inicio de user_input
    mov rcx, 4097           ; Número máximo de caracteres a copiar
    lea rdi, [buffer1]     ; Destino: dirección de inicio de filename
    rep movsb
    
    call _manageDinamicFile
    lea rsi, [readFileBuffer]   ; Fuente: dirección de inicio de user_input
    mov rcx, 4097           ; Número máximo de caracteres a copiar
    lea rdi, [buffer2]     ; Destino: dirección de inicio de filename
    rep movsb

    
    ;Guardar los datos de los buffers
	mov r9, buffer1
    mov r12, lineLengths
    call store_text
    mov qword [lineCount], r10
	
	mov r9, buffer2
    mov r12, lineLengths2
	call store_text
	mov qword [lineCount2], r10
	
	;Llama al compare
	call compare
    
    jmp get_input_comp
    
;---------------------------------------------- LEER INPUT DE MENÚ EDITAR ARCHIVO
get_input_edit:
	mov rax, 0
    mov rdi, 0
    mov rsi, user_input_edit
    mov rdx, 2
    syscall
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall

	; Comparar el input a las letras
    cmp byte[user_input_edit], 'q'		; Quit, se sale del programa
    je _start
	
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    mov rax, option_no_valida
    call _genericprint
    
    jmp get_input_edit            		; Se repite el loop para seguir leyendo los inputs

;---------------------------------------------- LEER INPUT DE MENÚ COMPARAR ARCHIVOS
get_input_comp:
    mov rax, 0
    mov rdi, 0
    mov rsi, user_input_comp
    mov rdx, 2
    syscall
    
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall

	; Comparar el input a las letras
    cmp byte[user_input_comp], 'q'		; Quit, se sale del programa
    je _start
	
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    mov rax, option_no_valida
    call _genericprint
    
    jmp get_input_comp            		; Se repite el loop para seguir leyendo los inputs
    
;---------------------------------------------- LEER INPUT DE MENÚ VER ARCHIVO
get_input_ver:
    mov rax, 0
    mov rdi, 0
    mov rsi, user_input_scroll
    mov rdx, 2
    syscall

	; Comparar el input a las letras
    cmp byte[user_input_scroll], 'u'		; Up, se mueve una línea de texto hacia arriba
    je move_up
    cmp byte[user_input_scroll], 'd'		; Down, se mueve una línea de texto hacia arriba
    je move_down
    cmp byte[user_input_scroll], 'q'		; Quit, se sale del programa
    je _start
	
    ; Imprimir un enter
    mov rax, 1
    mov rdi, 1
    mov rsi, espacio
    mov rdx, 1
    syscall
    
    mov rax, option_no_valida
    call _genericprint
    
    jmp get_input_ver            		; Se repite el loop para seguir leyendo los inputs

; Si se presiona la 'u'
move_up:
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
    
    call _printLoop_ver					; Se imprime la línea actual
	
    jmp get_input_ver					; Se vuelve a pedir el input

; Si se presiona la 'd'
move_down:
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
    
    call _printLoop_ver

    jmp get_input_ver

; Cuando se está al incio del texto
no_prev_line:
	; Imprimir texto
    mov rax, 1
    mov rdi, 1
    mov rsi, line_message_up
    mov rdx, 36
    syscall
    
    jmp get_input_ver

; Cuando se está al final del texto
last_line:
	; Imprimir texto
    mov rax, 1
    mov rdi, 1
    mov rsi, line_message_down
    mov rdx, 27
    syscall
    
    jmp get_input_ver


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
;-------------Fin Itoa---------------------------
;------------------------------------------------------ MANEJO DE ARCHIVOS DINÁMICOS
_manageEditDinamicFile:
	;mov rax, text_modify
	;call _genericprint
	
	;call get_input
	
	mov rdi, user_input 
	call _calculate_size
	
	mov rsi, qword[lentext]
	call _startItoa
	
	mov rax, buffer
	call _genericprint
	
	call _openFileToEdit
	call _writeToFile
	call _closeFile
	
	mov rdi, user_input
    call clear_input
	ret
	
_manageDinamicFile:
	mov rax, text_ingreseDocumento
	call _genericprint
	
	call get_input
	dec rax            
    mov byte [rsi + rax], 0
    
    lea rdi, [dynamicFile]     ; Destino: dirección de inicio de filename
	call copy_string 
	
    call _openFile			; Abre el archivo a leer
    cmp rax, -2         	; Comprobar si hay error al abrir el archivo
    je _finishErrorCode   	; Si eax es -1, se produjo un error
    mov [fd], eax ; store file descriptor

file_stats:    
    push rax
    ; Get file statistics
    mov rax, 5                          ; syscall number for fstat (5)
    mov rdi, [fd]                       ; file descriptor
    mov rsi, statbuf                    ; pointer to buffer
    syscall                             ; invoke syscall
    test rax, rax                       ; check if result is non-negative
    js _finishErrorCode                 ; jump to error if negative (fstat failed)
    
    ; Extract the file size (off_t st_size is at offset 48 in the struct stat)
    mov rax, [statbuf + 48]             ; read st_size from struct stat
    mov [filesize], rax                 ; store the file size
    
    ; Check if file size is greater than 4096
    cmp rax, 4096                       ; compare file size with 4096
    jle file_ok                         ; if less or equal, file is ok
    jmp file_too_large                  ; otherwise, file is too large

file_ok:
    pop rax
    mov rsi, rax        	; Guardar el descriptor del archivo en esi
    call _readFile  
    
    mov rdi, user_input
    call clear_input
    ret

file_too_large:
    mov rax, error_message
	call _genericprint
	jmp _finishCode
    
get_input:
    mov rax, 0
    mov rdi, 0
    mov rsi, user_input
    mov rdx, 4097
    syscall
    ret

get_input_line:
    mov rax, 0
    mov rdi, 0
    mov rsi, user_input_line
    mov rdx, 4097
    syscall
    ret    

_openFile:
    mov rax, 2              ; sys_open syscall
    lea rdi, [user_input]   ; Dirección de la entrada del usuario como nombre del archivo
    mov rsi, 0              ; O_RDONLY
    mov rdx, 0              ; Permisos (no necesarios en O_RDONLY)
    syscall                 ; Ejecuta syscall
    ret

_readFile:
	mov rax, 0              ; Para leer el documento
	mov rdi, rsi             
	mov rsi, readFileBuffer         ; Pointer a buffer
	mov rdx, 4097           ; Tamano
	syscall
	ret
	
clear_input:    ; Start address of user_input
    mov rcx, 4097          ; Size of user_input in bytes
    xor rax, rax           ; Set rax to 0 (value to set)
    rep stosb              ; Repeat storing AL into memory at RDI, RCX times
    ret

; Abre el archivo para escritura y truncamiento
_openFileToEdit:
    mov rax, 2               ; sys_open syscall number
    lea rdi, [dynamicFile]      ; Address of filename
    mov rsi, 0201h           ; Flags: O_WRONLY | O_TRUNC (open for writing and truncate)
    mov rdx, 0666h           ; Permissions: rw-rw-rw- (if the file needs to be created)
    syscall                  ; Perform the syscall
    mov [file_desc], rax     ; Store the file descriptor in a memory location
    ret

; Escribe en el archivo
_writeToFile:
    mov rax, 1               ; sys_write syscall number
    mov rdi, [file_desc]     ; Load the stored file descriptor into rdi
    lea rsi, [user_input]    ; Address of data to write
    mov rdx, qword[lentext]       ; Length of data to write
    syscall                  ; Perform the syscall
    ret

; Cierra el archivo
_closeFile:
    mov rax, 3               ; sys_close syscall number
    mov rdi, [file_desc]     ; Load the stored file descriptor into rdi
    syscall                  ; Perform the syscall
    ret
    
copy_string:
	lea rdi, [dynamicFile]     ; Destino: dirección de inicio de filename
    lea rsi, [user_input]   ; Fuente: dirección de inicio de user_input
    mov rcx, 2050           ; Número máximo de caracteres a copiar
    rep movsb
    

    ret
	
	
    
_finishErrorCode:				; Error de file           
	mov rax, error_message
	call _genericprint
	jmp _finishCode

;------------------------------------------------------ END MANEJO DE ARCHIVOS DINÁMICOS

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

; Se termina el programa
_finishCode:
	mov rax, 60
	mov rdi, 0
	syscall
