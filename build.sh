#!/bin/bash
# Build pinkOS: boot sector + kernel into a bootable disk image.
# Equivalent to `make`; see the Makefile.
set -e
mkdir -p build

nasm -f bin bootloader.asm -o build/boot.bin
nasm -f bin kernel.asm     -o build/kernel.bin

dd if=/dev/zero       of=build/os.img bs=512 count=2880 status=none
dd if=build/boot.bin  of=build/os.img conv=notrunc status=none
dd if=build/kernel.bin of=build/os.img seek=1 conv=notrunc status=none

echo "IMAGE READY - run:"
echo "qemu-system-i386 -drive format=raw,file=build/os.img"
