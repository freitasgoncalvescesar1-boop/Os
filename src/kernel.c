#include <stdint.h>

static volatile uint16_t *const VGA = (uint16_t *)0xB8000;
static uint8_t row = 0, col = 0;

static void putc(char c) {
    if (c == '\n') { row++; col = 0; return; }
    if (c == '\b') { if (col) col--; VGA[row * 80 + col] = (uint16_t)' ' | (0x07 << 8); return; }
    VGA[row * 80 + col] = (uint16_t)c | (0x07 << 8);
    if (++col >= 80) { col = 0; row++; }
    if (row >= 25) row = 0;
}

void kernel_main(void) {
    for (int i = 0; i < 80 * 25; i++) VGA[i] = (uint16_t)' ' | (0x07 << 8);
    const char *msg = "OS shell> ";
    while (*msg) putc(*msg++);
    for (;;) {
        uint8_t status;
        __asm__ volatile("inb $0x64, %0" : "=a"(status));
        if (!(status & 1)) continue;
        uint8_t sc;
        __asm__ volatile("inb $0x60, %0" : "=a"(sc));
        if (sc & 0x80) continue;
        if (sc == 0x1c) {
            putc('\n');
            const char *pong = "Pong\nOS shell> ";
            while (*pong) putc(*pong++);
        }
    }
}
