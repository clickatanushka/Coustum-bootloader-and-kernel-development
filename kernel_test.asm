; kernel_test.asm — flat 16-bit code placed at 0x8000 that prints on VGA
[BITS 16]
[ORG 0x8000]

start:
    mov si, msg
.print:
    lodsb
    cmp al, 0
    je .halt
    mov ah, 0x0E
    int 0x10
    jmp .print

.halt:
    cli
    hlt
    jmp .halt

msg db "hi pookie <3",0
