; bootloader.asm -- 512-byte BIOS boot sector
;
; The BIOS loads this sector to 0x7C00 and jumps to it. We read the kernel
; from the sectors right after us into memory at 0x0000:0x8000 and jump there.

[BITS 16]
[ORG 0x7C00]

KERNEL_SEG     equ 0x0000
KERNEL_OFF     equ 0x8000
KERNEL_SECTORS equ 16               ; 16 * 512 bytes = 8 KiB of kernel

start:
    ; Set up segments and a stack. The BIOS does not guarantee DS/SS values,
    ; so we must not touch memory before this.
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00                  ; stack grows down from just below us
    sti

    mov [boot_drive], dl            ; BIOS hands us the boot drive in DL

    mov si, msg_loading
    call print

    ; BIOS int 0x13 / AH=0x02: read sectors (CHS addressing)
    mov bx, KERNEL_OFF              ; ES:BX = destination buffer
    mov ah, 0x02
    mov al, KERNEL_SECTORS          ; how many sectors
    mov ch, 0                       ; cylinder 0
    mov cl, 2                       ; start at sector 2 (sector 1 is us)
    mov dh, 0                       ; head 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error                   ; carry set = BIOS reported an error
    cmp al, KERNEL_SECTORS          ; AL = sectors actually read
    jne disk_error

    jmp KERNEL_SEG:KERNEL_OFF       ; hand control to the kernel

disk_error:
    mov si, msg_disk_error
    call print
.halt:
    cli
    hlt
    jmp .halt

; print: write the zero-terminated string at DS:SI using BIOS teletype output
print:
    mov ah, 0x0E
.next:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

boot_drive     db 0
msg_loading    db "Loading pinkOS...", 13, 10, 0
msg_disk_error db "Disk read error!", 0

times 510 - ($ - $$) db 0
dw 0xAA55                           ; boot signature
