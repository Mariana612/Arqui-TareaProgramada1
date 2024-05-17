section .data
    espacio db 10             ; New line character for syscalls
    text_start db 'hola me llamo sandia carrasco y me gusta las sandia amarrilla no la roja es que la roja es fea, ademas la gente solo piensa en la sandia roja esto es una palabra por favor me gusta holi.', 0
	digits db '0123456789ABCDEF' 
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
    binary_str db "1111", 0
    decimal_number dd 0
    

	
	

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
    
    result resb 2050
    bin_num resb 20
    hex_result resb 2050

section .text
    global _start
    

_start:
	;mov rax, text_menuInicial
    ;call _genericprint  
    ;call _enterPrint 
    
    ;mov rax, text_menuInicialCont
    ;call _genericprint   
    ;call _enterPrint
    
    
    ;call get_input
    ;call menu_compare
    
    ;mov rdi, binary_str
    ;call _calculate_size
    ;mov rsi, [lentext]
    ;call is_binary
    
    ;mov rsi, rax
    ;call _startItoa
    
    ;mov rax, buffer
    ;call _genericprint
    
    call _AtoiStart
	mov qword[bin_num], rax
    mov rsi, bin_num
    call ascii_to_hex
   
   ;mov rax, hex_result
   ;call _genericprint

    jmp _finishCode

;-------------- INTERACCION CON EL USUARIO -----------------------

;-------------- INTERACCION CON EL USUARIO -----------------------  

;---------------COMPARE BINARIO-----------------------------------

is_binary:
    xor rcx, rcx      

.loop:
    cmp rcx, rsi
    jge .done             

    mov al, [rdi + rcx]

    cmp al, '0'
    je .next          

    cmp al, '1'
    je .next      

    mov rax, 1
    ret

.next:
    ; Incrementa el contador
    inc rcx
    jmp .loop            

.done:
    xor rax, rax          ; rax = 0
    ret
;---------------COMPARE BINARIO-----------------------------------




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

_startItoa2:
    	;Llama a ITOA para convertir n a cadena
    	mov rdi, buffer
    	mov rsi, rsi
    	mov rbx, 16			;Establece la base (Se puede cambiar)
    	call itoa2
    	mov r8, rax  					;Almacena la longitud de la cadena
    
    	; Añade un salto de línea
    	mov byte [buffer + r8], 10
    	inc r8
    
    	; Termina la cadena con null
		mov byte [buffer + r8], 0

		mov rax, buffer
		jmp _genericprint

; Definición de la función ITOA
itoa2:
    	mov rax, rsi    				; Mueve el número a convertir (en rsi) a rax
    	mov rsi, 0      				; Inicializa rsi como 0 (contador de posición en la cadena)
    	mov r10, rbx   					; Usa rbx como la base del número a convertir

.loop2:
	xor rdx, rdx       					; Limpia rdx para la división
    	div r10            				; Divide rax por rbx
    	cmp rbx, 10
    	jbe .lower_base_digits2 ; Salta si la base es menor o igual a 10
    
    	; Maneja bases mayores que 10
    	movzx rdx, dl
    	mov dl, byte [digits + rdx]
    	jmp .store_digit2
    
.lower_base_digits2:
    	; Maneja bases menores o iguales a 10
    	add dl, '0'    ; Convierte el resto a un carácter ASCII
    
.store_digit2:
    	mov [rdi + rsi], dl  ; Almacena el carácter en el buffer
    	inc rsi              ; Se mueve a la siguiente posición en el buffer
    	cmp rax, 0           ; Verifica si el cociente es cero
    	jg .loop2            ; Si no es cero, continúa el bucle
    
    	; Invierte la cadena
    	mov rdx, rdi
    	lea rcx, [rdi + rsi - 1]
    	jmp reversetest2
    
reverseloop2:
		mov al, [rdx]
    	mov ah, [rcx]
    	mov [rcx], al
    	mov [rdx], ah
    	inc rdx
    	dec rcx
    
reversetest2:
    	cmp rdx, rcx
    	jl reverseloop2
    
    	mov rax, rsi  ; Devuelve la longitud de la cadena
    	ret

;------------------------------ATOI-------------------------------------
; bin_to_hex function
ascii_to_hex:
    mov rsi, 0      				; Cantidad de digitos del string
    mov r13, [bin_num]
    mov rax, digits
    call _genericprint
    mov rdi, hex_result
    xor r8, r8  ; Clear R8 to use as a loop counter
loop_base16_high:
	mov r11, 0xf
	and r11, r13 ;Enmascaramiento de los bits menos significativos para obtener los cuatro menores
	shr r13, 4 ;Se mueven los bits 4 veces a la derecha
	
    mov dl, byte [digits + r11] ;Se busca el dígito obtenido en el look up table

store_digit_16_high:
    mov [rdi + rsi], dl  ;Almacena el caracter en el string
    inc rsi             ;Se mueve a la siguiente posición del string
    inc r8 ;Se incrementa el contador
    cmp r8, 1024 ;Se pregunta si ya se hicieron la cantidad de agrupaciones máxima
	je final_base_16
		
	jmp loop_base16_high	

final_base_16:
	mov rdx, rdi
    lea rcx, [rdi + rsi - 1]
    call reversetest2 ;Darle vuelta al string
    
    mov rax, hex_result
	call _genericprint ;Imprimir el string
	ret
;--------------------END ATOI-------------------------------------------

_AtoiStart:
	xor rbx, rbx			;reinicia el registro
	xor rax, rax			;reinicia el registro
	lea rcx, [binary_str]			;ingresa el numString a rcx
	jmp _Atoi

_Atoi:
	mov bl, byte[rcx]
	cmp bl, 0xA		
	je _exitFunction		;se asegura de que sea el final del string

	sub rbx,30h			;resta 30h al string para volverlo el numero
	imul rax, 2 			;multiplica el numero almacenado en rax x 10 para volverlo decimal
	add rax, rbx			;agrega el ultimo numero obtenido a rax (ej: 10+3=13)
	jc _finishCode		;check de overflow


	xor rbx,rbx			;reinicia el registro
	inc rcx				;incrementa x 1 el rcx (obtiene el siguiente caracter
	jmp _Atoi			;realiza loop

_exitFunction: 
	ret

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


