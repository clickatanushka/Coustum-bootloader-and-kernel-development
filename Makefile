# pinkOS build
#   make        build build/os.img
#   make run    build and boot it in QEMU
#   make clean  remove build outputs

ASM   := nasm
QEMU  := qemu-system-i386
BUILD := build

.PHONY: all run clean

all: $(BUILD)/os.img

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/boot.bin: bootloader.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

$(BUILD)/kernel.bin: kernel.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

# 1.44 MB floppy-sized image: boot sector first, kernel from sector 2 onward
$(BUILD)/os.img: $(BUILD)/boot.bin $(BUILD)/kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=$(BUILD)/boot.bin of=$@ conv=notrunc status=none
	dd if=$(BUILD)/kernel.bin of=$@ seek=1 conv=notrunc status=none

run: all
	$(QEMU) -drive format=raw,file=$(BUILD)/os.img

clean:
	rm -rf $(BUILD)
