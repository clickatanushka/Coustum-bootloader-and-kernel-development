# # # # # #!/bin/bash
# # # # # set -e

# # # # # mkdir -p build

# # # # # nasm -f bin bootloader.asm -o build/boot.bin

# # # # # dd if=/dev/zero of=build/os.img bs=512 count=2880
# # # # # dd if=build/boot.bin of=build/os.img conv=notrunc

# # # # # echo "IMAGE READY — run:"
# # # # # echo "qemu-system-i386 -drive format=raw,file=build/os.img"


# # # # #!/bin/bash
# # # # set -e

# # # # mkdir -p build

# # # # # Assemble bootloader
# # # # nasm -f bin bootloader.asm -o build/boot.bin

# # # # # Compile kernel
# # # # i686-elf-g++ -ffreestanding -c kernel.cpp -o build/kernel.o
# # # # i686-elf-ld -Ttext 0x8000 --oformat binary build/kernel.o -o build/kernel.bin

# # # # # Build disk image
# # # # dd if=/dev/zero of=build/os.img bs=512 count=2880
# # # # dd if=build/boot.bin of=build/os.img conv=notrunc
# # # # dd if=build/kernel.bin of=build/os.img seek=1 conv=notrunc

# # # # echo "DONE — run:"
# # # # echo "qemu-system-i386 -drive format=raw,file=build/os.img"


# # # #!/bin/bash
# # # set -e
# # # mkdir -p build

# # # # bootloader
# # # nasm -f bin bootloader.asm -o build/boot.bin

# # # # kernel entry and kernel
# # # nasm -f elf32 kernel_entry.asm -o build/kernel_entry.o
# # # i686-elf-g++ -ffreestanding -m32 -c kernel.cpp -o build/kernel.o
# # # i686-elf-ld -Ttext 0x8000 -m elf_i386 --oformat binary \
# # #   build/kernel_entry.o build/kernel.o -o build/kernel.bin

# # # # disk image
# # # dd if=/dev/zero of=build/os.img bs=512 count=2880
# # # dd if=build/boot.bin of=build/os.img conv=notrunc
# # # dd if=build/kernel.bin of=build/os.img seek=1 conv=notrunc

# # # echo "DONE — run:"
# # # echo "qemu-system-i386 -drive format=raw,file=build/os.img"




# # SO THIS IS THE WORKING ONE BEFORE POLL
# # #!/bin/bash
# # set -e
# # mkdir -p build

# # # assemble bootloader (must already have working bootloader.asm)
# # nasm -f bin bootloader.asm -o build/boot.bin

# # # assemble test kernel as flat binary (ORG 0x8000)
# # nasm -f bin kernel_test.asm -o build/kernel.bin

# # # make floppy image and write
# # dd if=/dev/zero of=build/os.img bs=512 count=2880 status=none
# # dd if=build/boot.bin of=build/os.img conv=notrunc status=none
# # dd if=build/kernel.bin of=build/os.img seek=1 conv=notrunc status=none

# # echo "IMAGE READY — run:"
# # echo "qemu-system-i386 -drive format=raw,file=build/os.img"


# # AND AFTER POLL


# #!/bin/bash
# set -e
# mkdir -p build

# # assemble bootloader (assumes bootloader.asm is present and correct)
# nasm -f bin bootloader.asm -o build/boot.bin

# # assemble the keyboard-poll kernel as flat binary (ORG 0x8000)
# nasm -f bin kernel_poll.asm -o build/kernel.bin

# # create floppy image and write
# dd if=/dev/zero of=build/os.img bs=512 count=2880 status=none
# dd if=build/boot.bin of=build/os.img conv=notrunc status=none
# dd if=build/kernel.bin of=build/os.img seek=1 conv=notrunc status=none

# echo "IMAGE READY — run:"
# echo "qemu-system-i386 -drive format=raw,file=build/os.img"


#!/bin/bash
set -e
mkdir -p build

# assemble bootloader (512 bytes with boot signature)
nasm -f bin bootloader.asm -o build/boot.bin

# assemble keyboard kernel
nasm -f bin kernel_poll.asm -o build/kernel.bin

# make 1.44MB disk image
dd if=/dev/zero of=build/os.img bs=512 count=2880 status=none

# write bootloader to sector 0
dd if=build/boot.bin of=build/os.img conv=notrunc status=none

# write kernel to sector 1 and onward
dd if=build/kernel.bin of=build/os.img seek=1 conv=notrunc status=none

echo "IMAGE READY — run:"
echo "qemu-system-i386 -drive format=raw,file=build/os.img"
