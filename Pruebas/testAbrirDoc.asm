section .data
	error_message db 'Failed to open file.', 0xa, 0
	
section .bss 
	buffer resb 2050

section .text
    global _start
_start:
	
    call _openFile		; Abre el archivo a leer

    cmp rax, -2         	; Comprobar si hay error al abrir el archivo
    je error_occurred   	; Si eax es -1, se produjo un error

    mov rsi, rax        	; Guardar el descriptor del archivo en esi
    call _readFile
              
    
    call count_chars ;Contar chars   

    mov rax, buffer ;Imprimir el texto
    call _genericprint
    
_getInput:			;obtiene el texto
	mov rax, 0
	mov rdi, 0
	mov rsi, numString
	mov rdx, 101
	syscall 
	
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


;----------------------ITOA
_startItoa:
	mov rdi, bufferItoa
    mov rsi, rcx 	  ; Numero a convertir en rcx
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



_genericprint:
    mov qword [printCont], 0        ;coloca rdx en 0 (contador)
    push rax        ;almacenamos lo que esta en rax

_printLoop:
    mov cl, [rax]
    cmp cl, 0
    je _endPrint2
    inc qword [printCont]                ;aumenta contador
    inc rax
    jmp _printLoop2

_endPrint:
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
