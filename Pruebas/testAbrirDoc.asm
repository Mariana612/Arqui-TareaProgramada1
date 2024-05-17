section .data
	text_inicial db 'Ingrese la direccion de un Documento', 0xa, 0
	text_error db 'Error', 0xa, 0
	printCont dq 0
	
section .bss 
	readFileBuffer resb 2050
	user_input resb 2050

section .text
    global _start
_start:

	call _manageDinamicFile
	mov rax, readFileBuffer 		;Imprimir el texto
    call _genericprint
	

    
    jmp _finishCode
    
_manageDinamicFile:
	mov rax, text_inicial
	call _genericprint
	
	call get_input
	dec rax            
    mov byte [rsi + rax], 0 
	
    call _openFile			; Abre el archivo a leer
    cmp rax, -2         	; Comprobar si hay error al abrir el archivo
    je _finishErrorCode   	; Si eax es -1, se produjo un error

    mov rsi, rax        	; Guardar el descriptor del archivo en esi
    call _readFile
              
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
    lea rdi, [user_input]   ; Dirección de la entrada del usuario como nombre del archivo
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

_finishErrorCode:
	mov rax, text_error
	call _genericprint
; Se termina el programa
_finishCode:
	mov rax, 60
	mov rdi, 0
	syscall
