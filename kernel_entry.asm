[BITS 16]
[ORG 0x8000]

extern kernelMain
call kernelMain
cli
hlt
