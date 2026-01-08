; [BITS 16]
; [ORG 0x7C00]

; mov ah, 0x0E
; mov si, msg
; print:
;     lodsb
;     test al, al
;     jz halt
;     int 0x10
;     jmp print

; halt:
;     cli
;     hlt
;     jmp halt

; msg db "BOOTLOADER OK", 0

; times 510-($-$$) db 0
; dw 0xAA55


[BITS 16]
[ORG 0x7C00]

start:
    mov [BOOT_DRIVE], dl       ; save BIOS boot drive

    mov ah, 0x0E
    mov si, msg
.print:
    lodsb
    test al, al
    jz load_kernel
    int 0x10
    jmp .print

load_kernel:
    mov ax, 0
    mov es, ax
    mov bx, 0x8000            ; load address 0x8000
    mov ah, 0x02              ; BIOS read sectors
    mov al, 10                ; number of sectors to read
    mov ch, 0
    mov cl, 2                 ; from sector 2 onward
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    int 0x13
    jmp 0x0000:0x8000         ; jump to kernel

BOOT_DRIVE db 0
msg db "Loading kernel...", 0

times 510-($-$$) db 0
dw 0xAA55
