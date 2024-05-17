;lola buenos dias a todos el sol ya sale hermoso. poder volar es muy genial porque es divertido jaja jaja. yl hombre fue muy amable con la mujer porque le compro una flor de regalo y se lo envolvio
;lola buenos dias a todos el sol ya sale hermoso. poder volar es muy genial porque es divertido jaja jaja. yl hombre fue muy amable con la mujer porque le compro una flor de regalo y se lo envolvio
;/home/mariana/Desktop/Plain Text.txt

section .data
	text_inicial db 'Ingrese la direccion de un Documento', 0xa, 0
	text_modify db 'Ingrese la texto a modificar', 0xa, 0
	text_error db 'Error', 0xa, 0
	printCont dq 0
	lentext dq 0 
	
section .bss 
	file_desc resb 8 
	readFileBuffer resb 2050
	user_input resb 2050
	dynamicFile resb 2050
	buffer resb 4097

section .text
    global _start
_start:

	call _manageDinamicFile
	mov rax, readFileBuffer 		;Imprimir el texto
    call _genericprint
    
    mov rdi, readFileBuffer
    call clear_input
    
    
    call _manageEditDinamicFile
    
    call _manageDinamicFile
	mov rax, readFileBuffer 		;Imprimir el texto
    call _genericprint
    

    jmp _finishCode
    
_manageEditDinamicFile:
	mov rax, text_modify
	call _genericprint
	
	call get_input
	
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
	mov rax, text_inicial
	call _genericprint
	
	call get_input
	dec rax            
    mov byte [rsi + rax], 0 
	
	
	call copy_string
	
    call _openFile			; Abre el archivo a leer
    cmp rax, -2         	; Comprobar si hay error al abrir el archivo
    je _finishErrorCode   	; Si eax es -1, se produjo un error

    mov rsi, rax        	; Guardar el descriptor del archivo en esi
    call _readFile
    
    mov rdi, user_input
    call clear_input
              
    ret
 ;---------------
; Abre el archivo para escritura y truncamiento
_openFileToEdit:
    mov rax, 2               ; sys_open syscall number
    lea rdi, [filename]      ; Address of filename
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
    
get_input:
    mov rax, 0
    mov rdi, 0
    mov rsi, user_input
    mov rdx, 2050
    syscall
    ret

_openFile:
    mov rax, 2              ; sys_open syscall
    lea rdi, [filename]   ; Dirección de la entrada del usuario como nombre del archivo
    mov rsi, 0              ; O_RDONLY
    mov rdx, 0              ; Permisos (no necesarios en O_RDONLY)
    syscall                 ; Ejecuta syscall
    ret

_readFile:
	mov rax, 0              ; Para leer el documento
	mov rdi, rsi             
	mov rsi, readFileBuffer         ; Pointer a buffer
	mov rdx, 2050           ; Tamano
	syscall
	ret
	
clear_input:    ; Start address of user_input
    mov rcx, 2050          ; Size of user_input in bytes
    xor rax, rax           ; Set rax to 0 (value to set)
    rep stosb              ; Repeat storing AL into memory at RDI, RCX times
    ret
	
	
	

; Función para copiar cadenas de caracteres usando instrucciones de string
copy_string:
	lea rdi, [filename]     ; Destino: dirección de inicio de filename
    lea rsi, [user_input]   ; Fuente: dirección de inicio de user_input
    mov rcx, 2050           ; Número máximo de caracteres a copiar
    rep movsb
    

    ret
	
	
;-----------
	

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


_finishErrorCode:
	mov rax, text_error
	call _genericprint
; Se termina el programa
_finishCode:
	mov rax, 60
	mov rdi, 0
	syscall
	
_startItoa: 
    mov rdi, buffer
    mov rsi, rsi 
    mov rbx, 10       ; La base
    call itoa
    mov r8, rax                     ; Almacena la longitud de la cadena

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
