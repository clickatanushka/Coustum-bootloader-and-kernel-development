; kernel_poll.asm -- flat 16-bit code at 0x8000
; Polls keyboard controller (port 0x60) and prints ASCII on VGA text memory

[BITS 16]
[ORG 0x8000]

start:
    cli
    cld
    ; set ES to VGA memory segment 0xB800
    mov ax, 0xB800
    mov es, ax


main_loop:
    call wait_scancode
    cmp al, 0
    je main_loop          ; if unmapped, ignore
    ; handle Enter (ASCII 13) -> move to next line
    cmp al, 13
    je do_enter
    ; handle Backspace (ASCII 8)
    cmp al, 8
    je do_backspace
    ; print normal char
    push ax
    call put_char
    pop ax
    jmp main_loop

do_enter:
    ; move DI to start of next line (col 0)
    ; each line is 80 chars -> 160 bytes
    mov cx, 80
    ; compute current row = di / 160 ; we'll do simple approach: advance to next 160 boundary
    mov dx, di
    ; dx mod 160 -> dx = dx & 0x00FF then repeatedly? Simpler: clear lower 7 bits of char column
    ; We'll compute: di = ((di / 160) + 1) * 160
    mov ax, di
    shr ax, 1      ; now ax = char index (di/2)
    mov bx, 80
    div bx         ; ax = row, dx = col (after this div, ax = quotient row)
    inc ax         ; next row
    mul bx         ; dx = ax * 80 -> char index for start of next row
    shl dx, 1      ; byte offset = charindex*2
    mov di, dx
    jmp main_loop

do_backspace:
    cmp di, 0
    je main_loop
    sub di, 2
    mov byte [es:di], ' '
    mov byte [es:di + 1], 0x07
    jmp main_loop


; wait_scancode: waits until KBC output buffer full, reads scancode into AL, converts to ASCII (only make-on codes)
; returns AL = 0 if unmapped or release code, else ASCII code
wait_scancode:
    ; Wait for output buffer full
.wait_status:
    in al, 0x64
    test al, 1
    jz .wait_status

    in al, 0x60         ; al = scancode
    ; ignore release codes (bit 7 set)
    test al, 0x80
    jnz .return_zero

    ; convert scancode (in AL) to ASCII using lookup table
    ; AL is scancode 0x00..0x58
    mov ah, 0
    mov bl, al
    ; limit index to table size (we have up to 0x3A entries but safe to check >0x3A -> unmapped)
    cmp bl, 0x3A
    ja .return_zero

    ; compute address: table + bl
    mov si, scancode_table
    add si, bx
    mov al, [si]
    ret

.return_zero:
    xor al, al
    ret

; put_char: print character in AL at VGA offset DI; also advance DI by 2
; preserves AX? we don't care, but we'll assume AL holds char
put_char:
    mov [es:di], al
    mov byte [es:di + 1], 0x07
    add di, 2
    ret

; ---------------------------
; Scancode -> ASCII lookup table (set 1), for common keys:
; index = scancode (hex), value = ASCII (0 if unmapped)
; We fill up to 0x3A (58 decimal). Unmapped entries = 0.
; Common mapping for letters and digits (lowercase)
scancode_table:
    db 0      ; 0x00
    db 27     ; 0x01 ESC -> 27 (optional)
    db '1'    ; 0x02
    db '2'    ; 0x03
    db '3'    ; 0x04
    db '4'    ; 0x05
    db '5'    ; 0x06
    db '6'    ; 0x07
    db '7'    ; 0x08
    db '8'    ; 0x09
    db '9'    ; 0x0A
    db '0'    ; 0x0B
    db '-'    ; 0x0C
    db '='    ; 0x0D
    db 8      ; 0x0E Backspace (ASCII 8)
    db 9      ; 0x0F Tab (ASCII 9)
    db 'q'    ; 0x10
    db 'w'    ; 0x11
    db 'e'    ; 0x12
    db 'r'    ; 0x13
    db 't'    ; 0x14
    db 'y'    ; 0x15
    db 'u'    ; 0x16
    db 'i'    ; 0x17
    db 'o'    ; 0x18
    db 'p'    ; 0x19
    db '['    ; 0x1A
    db ']'    ; 0x1B
    db 13     ; 0x1C Enter (ASCII 13)
    db 0      ; 0x1D Ctrl
    db 'a'    ; 0x1E
    db 's'    ; 0x1F
    db 'd'    ; 0x20
    db 'f'    ; 0x21
    db 'g'    ; 0x22
    db 'h'    ; 0x23
    db 'j'    ; 0x24
    db 'k'    ; 0x25
    db 'l'    ; 0x26
    db ';'    ; 0x27
    db '\''   ; 0x28
    db '`'    ; 0x29
    db 0      ; 0x2A Left Shift
    db '\'    ; 0x2B (backslash)
    db 'z'    ; 0x2C
    db 'x'    ; 0x2D
    db 'c'    ; 0x2E
    db 'v'    ; 0x2F
    db 'b'    ; 0x30
    db 'n'    ; 0x31
    db 'm'    ; 0x32
    db ','    ; 0x33
    db '.'    ; 0x34
    db '/'    ; 0x35
    db 0      ; 0x36 Right Shift
    db '*'    ; 0x37 Keypad *
    db 0      ; 0x38 Alt
    db ' '    ; 0x39 Space
    db 0      ; 0x3A CapsLock

; pad table to exact size if needed (we used up to 0x3A)
; ---------------------------

times 510-($-$$) db 0
dw 0xAA55
