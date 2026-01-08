extern "C" void kernelMain() {
    const char* str = "Kernel OK";
    char* video = (char*)0xB8000;
    for(int i = 0; str[i]; i++) {
        video[i*2] = str[i];
        video[i*2+1] = 0x0F;
    }
    while(1);
}
