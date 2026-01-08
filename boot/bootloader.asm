[BITS 16]
[ORG 0x7C00]

mov ah, 0x0E
mov si, msg
print:
    lodsb
    test al, al
    jz halt
    int 0x10
    jmp print

halt:
    cli
    hlt
    jmp halt

msg db "BOOTLOADER OK", 0

times 510-($-$$) db 0
dw 0xAA55
