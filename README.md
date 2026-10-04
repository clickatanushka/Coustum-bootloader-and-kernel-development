# Custom Bootloader and Kernel Operating System
<img width="1488" height="1024" alt="image" src="https://github.com/user-attachments/assets/d0f84638-f7a3-4d35-8309-72421e2731e2" />


This project is a from-scratch custom bootloader and kernel developed to understand low-level system programming and operating system fundamentals.
The goal was to learn how an OS boots, switches CPU modes, and hands control from a bootloader to a custom kernel written entirely in Assembly.
The OS is minimal and educational in nature, focusing on the boot sequence, memory layout, and kernel execution rather than user-level features.

# Features
* Custom x86 bootloader written in Assembly
* Boots directly using BIOS (Legacy boot)
* Loads and jumps to an Assembly-based kernel (pinkOS)
* Interactive shell: type commands on a pink VGA text screen
* Keyboard driver that polls the PS/2 controller directly (shift and caps lock supported)
* VGA text driver with scrolling, backspace and hardware cursor
* Three switchable pink colour themes
* Runs successfully in QEMU emulator
* Built and tested on Arch Linux

# Shell commands
| Command | What it does |
|---------|--------------|
| `help`  | list the commands |
| `clear` | clear the screen |
| `echo <text>` | print the text back |
| `about` | how the kernel works |
| `theme` | cycle through the pink themes (blossom, rose, noir) |

# What I Learned
* How BIOS loads the first 512 bytes (boot sector)
* Real mode to protected mode transition basics
* Memory addressing and segmentation
* How a bootloader loads a kernel into memory
* Cross-compiling C++ code without standard libraries
* Low-level debugging using emulators

# Programming Languages
Assembly (NASM) – Bootloader and kernel development

#Tools and Software
* NASM – Assembler for bootloader
* GCC (Cross-Compiler) – Compiling kernel C++ code
* LD (Linker) – Linking kernel object files
* QEMU – OS emulation and testing
* Makefile – Build automation
* VS Code / Vim – Code editor

# Platform
Arch Linux (x86_64)



# Build Process
Requires `nasm` and `qemu-system-i386`.

```
make        # builds build/os.img
make run    # builds and boots it in QEMU
```

Or step by step (this is what `build.sh` and the Makefile do):
1. Assemble the bootloader
nasm -f bin boot.asm -o boot.bin
2. Assemble the kernel
nasm -f elf32 kernel.asm -o kernel.o
3. Link the kernel
ld -m elf_i386 -T linker.ld kernel.o -o kernel.bin
4. Create bootable OS image
cat boot.bin kernel.bin > os-image.bin
5. Run in QEMU
qemu-system-i386 os-image.bin






