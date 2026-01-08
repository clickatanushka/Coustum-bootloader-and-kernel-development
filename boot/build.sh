#!/bin/bash
set -e

mkdir -p build

nasm -f bin bootloader.asm -o build/boot.bin

dd if=/dev/zero of=build/os.img bs=512 count=2880
dd if=build/boot.bin of=build/os.img conv=notrunc

echo "IMAGE READY — run:"
echo "qemu-system-i386 -drive format=raw,file=build/os.img"
