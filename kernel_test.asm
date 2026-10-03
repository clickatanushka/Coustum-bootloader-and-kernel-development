; ; ; kernel_test.asm — flat 16-bit code placed at 0x8000 that prints on VGA
; ; [BITS 16]
; ; [ORG 0x8000]

; ; start:
; ;     mov si, msg
; ; .print:
; ;     lodsb
; ;     cmp al, 0
; ;     je .halt
; ;     mov ah, 0x0E
; ;     int 0x10
; ;     jmp .print

; ; .halt:
; ;     cli
; ;     hlt
; ;     jmp .halt

; ; msg db "hi pookie <3",0

; %define NASM_PASS 1

; [BITS 16]
; [ORG 0x8000]

; start:
;     mov ah, 0x0E
;     mov si, msg              ; FIX: load address of string

; .print:
;     lodsb
;     test al, al
;     jz enable_a20
;     int 0x10
;     jmp .print

; msg db "Kernel ok", 0         ; FIX: string defined separately

; enable_a20:
;     in al, 0x92
;     or al, 00000010b
;     out 0x92, al

;     lgdt [gdt_descriptor]
;     cli
;     mov eax, cr0
;     or eax, 1
;     mov cr0, eax
;     jmp 0x08:protected_mode   ; FAR jump (correct)


; [BITS 32]

; pic_remap:
;     mov al, 0x11
;     out 0x20, al
;     out 0xA0, al

;     mov al, 0x20
;     out 0x21, al
;     mov al, 0x28
;     out 0xA1, al

;     mov al, 0x04
;     out 0x21, al
;     mov al, 0x02
;     out 0xA1, al

;     mov al, 0x01
;     out 0x21, al
;     out 0xA1, al

;     ret

; protected_mode:
;     mov ax, 0x10
;     mov ds, ax
;     mov es, ax
;     mov ss, ax
;     mov fs, ax
;     mov gs, ax
;     mov esp, 0x90000
;     mov edi, 0xB8000
;     mov eax, 0x07204B     ; 'K'
;     stosw
;     lidt [idt_descriptor]
;     call pic_remap

;     mov al, 0xFD      ; enable IRQ1 only
;     out 0x21, al

;     sti
; .hang:
;     hlt
;     jmp .hang
; keyboard_handler:
;     pusha

;     in al, 0x60
;     cmp al, 0x80
;     ja .done

;     movzx eax, al
;     mov al, [scancode_table + eax]
;     cmp al, 0
;     je .done

;     call print_char

; .done:
;     mov al, 0x20
;     out 0x20, al
;     popa
;     iret
; cursor_pos dd 0

; print_char:
;     mov edi, 0xB8000
;     mov ebx, [cursor_pos]
;     shl ebx, 1
;     add edi, ebx
;     mov ah, 0x07
;     stosw
;     inc dword [cursor_pos]
;     ret
; idt_start:
;     times 33 dq 0

; idt_keyboard:
;     dw keyboard_handler
;     dw 0x08
;     db 0
;     db 10001110b
;     dw 0

; times (256-34) dq 0

; idt_end:

; idt_descriptor:
;     dw idt_end - idt_start - 1
;     dd idt_start
; gdt_start:
;     dq 0

; gdt_code:
;     dw 0xFFFF
;     dw 0
;     db 0
;     db 10011010b
;     db 11001111b
;     db 0

; gdt_data:
;     dw 0xFFFF
;     dw 0
;     db 0
;     db 10010010b
;     db 11001111b
;     db 0

; gdt_end:

; gdt_descriptor:
;     dw gdt_end - gdt_start - 1
;     dd gdt_start
; scancode_table:
;     db 0,27,"1234567890-=",8,9
;     db "qwertyuiop[]",13,0
;     db "asdfghjkl;'",0
;     db "\zxcvbnm,./",0
;     times 128 db 0

[BITS 16]
[ORG 0x8000]

start:
    sti                 ; ENABLE INTERRUPTS

    mov ah, 0x0E
    mov si, msg

.print:
    lodsb
    test al, al
    jz .loop
    int 0x10
    jmp .print

.loop:
    mov ah, 0x00
    int 0x16            ; BIOS keyboard
    mov ah, 0x0E
    int 0x10
    jmp .loop

msg db "Kernel working",0


