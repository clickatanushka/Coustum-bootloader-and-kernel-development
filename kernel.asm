; kernel.asm -- pinkOS: a tiny interactive 16-bit real-mode kernel
;
; Loaded by bootloader.asm to 0x0000:0x8000. It stays in real mode and talks
; to the hardware directly:
;   * output: VGA text memory at 0xB800:0000 (80x25 cells, char + attribute)
;   * input:  PS/2 keyboard controller, ports 0x60 (data) and 0x64 (status)
; Interrupts stay disabled so the BIOS keyboard handler cannot steal our
; scancodes while we poll the controller ourselves.

[BITS 16]
[ORG 0x8000]

VGA_SEG     equ 0xB800
COLS        equ 80
ROWS        equ 25
CMD_MAX     equ 64
THEME_COUNT equ 3

; The VGA palette is programmable, so we redefine two of the 16 text colours.
; Values are 0..63 per channel (6-bit VGA DAC). Tweak these to taste!
;   "light magenta" (colour 13) becomes a soft pastel pink
PINK_R      equ 63                  ; ~ RGB(255, 190, 215)
PINK_G      equ 47
PINK_B      equ 53
;   "magenta" (colour 5) becomes a deep rose, used for text on pink
ROSE_R      equ 42                  ; ~ RGB(170, 30, 95)
ROSE_G      equ 7
ROSE_B      equ 23

; ================================================================= entry ====
start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00              ; stack grows down from below the old bootloader
    mov ax, VGA_SEG
    mov es, ax                  ; ES always points at video memory

    ; Ask the video BIOS to treat attribute bit 7 as "bright background"
    ; instead of "blink". Without this, pink (light magenta) backgrounds blink.
    mov ax, 0x1003
    xor bl, bl
    int 0x10

    call set_palette
    call apply_theme
    call show_banner
    call print_prompt
    call update_cursor

; ============================================================ shell loop ====
shell_loop:
    call read_key               ; AL = ASCII, or 0 for nothing printable
    test al, al
    jz shell_loop
    cmp al, 13
    je .enter
    cmp al, 8
    je .backspace
    cmp al, ' '
    jb shell_loop               ; ignore other control characters
    cmp al, '~'
    ja shell_loop

    mov bx, [cmd_len]
    cmp bx, CMD_MAX - 1
    jae shell_loop              ; line buffer full, drop the key
    mov [cmd_buf + bx], al
    inc word [cmd_len]
    call put_char
    call update_cursor
    jmp shell_loop

.backspace:
    cmp word [cmd_len], 0
    je shell_loop
    dec word [cmd_len]
    call erase_char
    call update_cursor
    jmp shell_loop

.enter:
    mov bx, [cmd_len]
    mov byte [cmd_buf + bx], 0  ; zero-terminate the command
    call newline
    call run_command
    mov word [cmd_len], 0
    call print_prompt
    call update_cursor
    jmp shell_loop

; ============================================================== commands ====
; run_command: look at cmd_buf and dispatch to a handler.
run_command:
    mov si, cmd_buf
    cmp byte [si], 0
    je .done                    ; empty line, nothing to do

    mov di, kw_help
    call starts_with
    jc cmd_help
    mov di, kw_clear
    call starts_with
    jc cmd_clear
    mov di, kw_echo
    call starts_with
    jc cmd_echo
    mov di, kw_about
    call starts_with
    jc cmd_about
    mov di, kw_theme
    call starts_with
    jc cmd_theme

    mov si, msg_unknown
    call print_string
    mov si, cmd_buf
    call print_string
    call newline
.done:
    ret

cmd_help:
    mov si, msg_help
    call print_string
    ret

cmd_clear:
    call clear_screen
    ret

cmd_echo:
    call skip_spaces            ; SI now points at the text after "echo"
    call print_string
    call newline
    ret

cmd_about:
    mov si, msg_about
    call print_string
    ret

cmd_theme:
    mov al, [theme_idx]
    inc al
    cmp al, THEME_COUNT
    jb .set
    xor al, al
.set:
    mov [theme_idx], al
    call apply_theme
    call show_banner
    mov si, msg_theme
    call print_string
    call print_theme_name
    call newline
    ret

; starts_with: does the string at DS:SI begin with the word at DS:DI, followed
; by end-of-string or a space?
;   yes: CF=1, SI -> first char after the word
;   no:  CF=0, SI unchanged
starts_with:
    push si
.loop:
    mov al, [di]
    test al, al
    jz .word_done
    cmp al, [si]
    jne .no
    inc si
    inc di
    jmp .loop
.word_done:
    mov al, [si]
    test al, al
    jz .yes
    cmp al, ' '
    jne .no
.yes:
    add sp, 2                   ; discard saved SI, keep the advanced one
    stc
    ret
.no:
    pop si
    clc
    ret

; skip_spaces: advance SI past any spaces
skip_spaces:
    cmp byte [si], ' '
    jne .done
    inc si
    jmp skip_spaces
.done:
    ret

; ================================================================ themes ====
; set_palette: reprogram two VGA DAC entries via BIOS int 0x10 / AX=0x1010.
; Text colour 13 (light magenta) uses DAC entry 0x3D, colour 5 uses entry 0x05.
;   BX = DAC entry, DH = red, CH = green, CL = blue
set_palette:
    mov ax, 0x1010
    mov bx, 0x3D
    mov dh, PINK_R
    mov ch, PINK_G
    mov cl, PINK_B
    int 0x10
    mov ax, 0x1010
    mov bx, 0x05
    mov dh, ROSE_R
    mov ch, ROSE_G
    mov cl, ROSE_B
    int 0x10
    ret

; apply_theme: load the current theme's attributes and repaint the screen
apply_theme:
    mov bl, [theme_idx]
    xor bh, bh
    shl bx, 1
    mov al, [themes + bx]
    mov [attr], al
    mov al, [themes + bx + 1]
    mov [attr_accent], al
    call clear_screen
    ret

print_theme_name:
    mov bl, [theme_idx]
    xor bh, bh
    shl bx, 1
    mov si, [theme_names + bx]
    call print_string
    ret

; show_banner / print_prompt: print using the accent colour, then restore
show_banner:
    mov si, msg_banner
    jmp print_accent

print_prompt:
    mov si, msg_prompt
    ; fall through

print_accent:
    mov al, [attr]
    push ax
    mov al, [attr_accent]
    mov [attr], al
    call print_string
    pop ax
    mov [attr], al
    ret

; ============================================================== keyboard ====
; read_key: block until the keyboard controller has a byte, then translate it.
; Returns AL = ASCII character, or 0 if the key produced nothing printable
; (releases, shift/caps changes, arrows, etc).
read_key:
    in al, 0x64
    test al, 1                  ; bit 0: output buffer full
    jz read_key
    in al, 0x60                 ; scancode (set 1)

    cmp al, 0x2A                ; left shift pressed
    je .shift_down
    cmp al, 0x36                ; right shift pressed
    je .shift_down
    cmp al, 0xAA                ; left shift released
    je .shift_up
    cmp al, 0xB6                ; right shift released
    je .shift_up
    cmp al, 0x3A                ; caps lock pressed
    je .caps

    test al, 0x80               ; bit 7 set = key release (or 0xE0 prefix)
    jnz .none
    cmp al, 0x3A                ; beyond our keymap
    jae .none

    xor bh, bh
    mov bl, al
    mov si, keymap_lower
    cmp byte [shift_state], 0
    je .lookup
    mov si, keymap_upper
.lookup:
    mov al, [si + bx]
    cmp byte [caps_state], 0
    je .done
    ; caps lock flips the case of letters only
    cmp al, 'a'
    jb .check_upper
    cmp al, 'z'
    ja .done
    sub al, 'a' - 'A'
    ret
.check_upper:
    cmp al, 'A'
    jb .done
    cmp al, 'Z'
    ja .done
    add al, 'a' - 'A'
.done:
    ret

.shift_down:
    mov byte [shift_state], 1
    jmp .none
.shift_up:
    mov byte [shift_state], 0
    jmp .none
.caps:
    xor byte [caps_state], 1
.none:
    xor al, al
    ret

; ================================================================= video ====
; put_char: draw AL at the cursor with the current attribute, advance cursor
put_char:
    cmp al, 13
    je newline
    cmp al, 10
    je newline
    push ax
    call cursor_offset          ; DI = byte offset of cursor cell
    pop ax
    mov ah, [attr]
    stosw                       ; ES:DI <- AL (char), AH (attribute)
    inc word [cursor_col]
    cmp word [cursor_col], COLS
    jb .done
    jmp newline                 ; wrapped past the right edge
.done:
    ret

; newline: move to column 0 of the next row, scrolling if needed
newline:
    mov word [cursor_col], 0
    inc word [cursor_row]
    cmp word [cursor_row], ROWS
    jb .done
    call scroll
.done:
    ret

; erase_char: step the cursor back one cell and blank it (backspace)
erase_char:
    cmp word [cursor_col], 0
    jne .back
    cmp word [cursor_row], 0
    je .done                    ; top-left corner, nowhere to go
    dec word [cursor_row]
    mov word [cursor_col], COLS
.back:
    dec word [cursor_col]
    call cursor_offset
    mov al, ' '
    mov ah, [attr]
    mov [es:di], ax
.done:
    ret

; cursor_offset: DI = (row * COLS + col) * 2
cursor_offset:
    mov ax, [cursor_row]
    mov bx, COLS
    mul bx
    add ax, [cursor_col]
    shl ax, 1
    mov di, ax
    ret

; print_string: print the zero-terminated string at DS:SI
print_string:
    lodsb
    test al, al
    jz .done
    call put_char
    jmp print_string
.done:
    ret

; clear_screen: fill every cell with a space in the current attribute
clear_screen:
    xor di, di
    mov al, ' '
    mov ah, [attr]
    mov cx, COLS * ROWS
    rep stosw
    mov word [cursor_row], 0
    mov word [cursor_col], 0
    ret

; scroll: move rows 1..24 up by one and blank the bottom row
scroll:
    push si
    push cx
    push ds
    mov ax, VGA_SEG
    mov ds, ax                  ; DS:SI = row 1, ES:DI = row 0
    mov si, COLS * 2
    xor di, di
    mov cx, COLS * (ROWS - 1)
    rep movsw
    pop ds
    mov di, COLS * (ROWS - 1) * 2
    mov al, ' '
    mov ah, [attr]
    mov cx, COLS
    rep stosw
    mov word [cursor_row], ROWS - 1
    pop cx
    pop si
    ret

; update_cursor: tell the VGA CRT controller where to draw the blinking cursor
update_cursor:
    mov ax, [cursor_row]
    mov bx, COLS
    mul bx
    add ax, [cursor_col]
    mov bx, ax
    mov dx, 0x3D4
    mov al, 0x0F                ; cursor location low register
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    dec dx
    mov al, 0x0E                ; cursor location high register
    out dx, al
    inc dx
    mov al, bh
    out dx, al
    ret

; ================================================================== data ====
cursor_row   dw 0
cursor_col   dw 0
attr         db 0xD0
attr_accent  db 0xD5
theme_idx    db 0
shift_state  db 0
caps_state   db 0
cmd_len      dw 0
cmd_buf      times CMD_MAX db 0

; VGA attribute byte = (background << 4) | foreground
;   0x5 = rose (remapped magenta), 0xD = pink (remapped light magenta),
;   0xF = white, 0x0 = black
themes:
    db 0xD0, 0xD5               ; blossom: black on pink, accent rose on pink
    db 0x5F, 0x5D               ; rose:    white on rose, accent pink on rose
    db 0x0D, 0x0F               ; noir:    pink on black, accent white on black
theme_names:
    dw name_blossom, name_rose, name_noir
name_blossom db "blossom", 0
name_rose    db "rose", 0
name_noir    db "noir", 0

kw_help  db "help", 0
kw_clear db "clear", 0
kw_echo  db "echo", 0
kw_about db "about", 0
kw_theme db "theme", 0

msg_banner:
    db 13
    db "  ~*~  pinkOS v0.1  <3  ~*~", 13
    db "  a tiny x86 kernel, hand-assembled in NASM", 13
    db "  type 'help' to see what it can do", 13, 13, 0
msg_prompt  db "pink> ", 0
msg_unknown db "unknown command: ", 0
msg_theme   db "theme: ", 0
msg_help:
    db "commands:", 13
    db "  help   - show this list", 13
    db "  clear  - clear the screen", 13
    db "  echo   - print text back  (echo hi pookie)", 13
    db "  about  - about this kernel", 13
    db "  theme  - cycle pink themes", 13, 0
msg_about:
    db "pinkOS v0.1 - a from-scratch 16-bit x86 kernel", 13
    db "  boot:     BIOS loads bootloader.asm at 0x7C00, which loads us at 0x8000", 13
    db "  display:  VGA text mode, writing straight to 0xB800:0000", 13
    db "  keyboard: polling the PS/2 controller on ports 0x60/0x64", 13
    db "  made by Anushka Joshi <3", 13, 0

; scancode set 1 -> ASCII, indexes 0x00..0x39
keymap_lower:
    db 0, 27, "1234567890-=", 8, 9
    db "qwertyuiop[]", 13, 0
    db "asdfghjkl;", 39, "`", 0, "\"
    db "zxcvbnm,./", 0, "*", 0, " "
keymap_upper:
    db 0, 27, "!@#$%^&*()_+", 8, 9
    db "QWERTYUIOP{}", 13, 0
    db "ASDFGHJKL:", 34, "~", 0, "|"
    db "ZXCVBNM<>?", 0, "*", 0, " "
