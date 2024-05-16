section .data
    text_start db '1. hola me llamo sandia carrasco y me gusta las sandia amarrilla 2. no la roja es que la roja es fea, ademas la gente solo piensa en la sandia 3. roja esto es una palabra por favor me gusta holi.', 0
    text_test db ' xd ', 0

section .bss
    new_text resb 211 ; Buffer para el texto final.
    printCont resq 1  ; Initialize print content count

section .text
global _start

_start:
    ; Copia la primera parte al buffer nuevo
    mov esi, text_start
    mov edi, new_text
    mov ecx, 65  ; Termina la primera línea más un espacio
    rep movsb

    ; Añade text_test
    mov esi, text_test
    mov ecx, 3   ; Longitud de 'xd ' sin contar el null terminator
    rep movsb

    ; Añade el resto del texto original
    mov esi, text_start
    add esi, 65 + 78  ; Salta la primera y segunda línea
    mov ecx, 195 - (65 + 78)  ; Longitud total menos lo ya copiado
    rep movsb

    ; Función para imprimir el texto nuevo
    mov rax, new_text
    call _genericprint

    ; Termina el programa
    mov eax, 1       ; syscall: exit
    xor ebx, ebx     ; status: 0
    int 0x80
    

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
    
