# Custom Bootloader and Kernel Operating System

This project is a from-scratch custom bootloader and kernel developed to understand low-level system programming and operating system fundamentals.
The goal was to learn how an OS boots, switches CPU modes, and hands control from a bootloader to a custom kernel written entirely in Assembly.
The OS is minimal and educational in nature, focusing on the boot sequence, memory layout, and kernel execution rather than user-level features.

# Features
* Custom x86 bootloader written in Assembly
* Boots directly using BIOS (Legacy boot)
* Loads and jumps to an Assembly-based kernel
* Kernel prints output to the screen
* Runs successfully in QEMU emulator
* Built and tested on Arch Linux

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



#Build Process
1. Assemble the bootloader
nasm -f bin boot.asm -o boot.bin
2. Assemble the kernel
nasm -f elf32 kernel_test.asm -o kernel.o
3. Link the kernel
ld -m elf_i386 -T linker.ld kernel.o -o kernel.bin
4. Create bootable OS image
cat boot.bin kernel.bin > os-image.bin
5. Run in QEMU
qemu-system-i386 os-image.bin

## Output
On successful boot, the kernel displays a message such as: OK Kernel... //updated hi pookie<3
<img width="1920" height="1080" alt="Screenshot From 2026-01-21 20-13-24" src="https://github.com/user-attachments/assets/777b792d-ad1f-4aba-acc5-d5f3b456dc94" />



 Author
Anushka Joshi  
B.Tech Student | Systems and OS Enthusiast




