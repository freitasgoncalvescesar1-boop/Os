#include <stdint.h>

#define VGA ((volatile uint16_t *)0xB8000)

static uint8_t row = 0;
static uint8_t col = 0;

static const char *scancode_table =
    "\0\0"
    "1234567890-="
    "\0"
    "qwertyuiop[]"
    "\0"
    "asdfghjkl;'"
    "`"
    "\\zxcvbnm,./";

static void putc(char c)
{
    if (c == '\n') {
        col = 0;
        row++;
        return;
    }

    if (c == '\b') {
        if (col > 0) {
            col--;
            VGA[row * 80 + col] = ' ' | (0x07 << 8);
        }
        return;
    }

    VGA[row * 80 + col] = (uint16_t)c | (0x07 << 8);

    col++;

    if (col >= 80) {
        col = 0;
        row++;
    }

    if (row >= 25) {
        row = 24;
        col = 0;
    }
}

static void print(const char *s)
{
    while (*s)
        putc(*s++);
}

static void clear(void)
{
    for (int i = 0; i < 80 * 25; i++)
        VGA[i] = ' ' | (0x07 << 8);

    row = 0;
    col = 0;
}

static char translate_scancode(uint8_t sc)
{
    /*
     * Set-1 keyboard scancodes.
     * 0x02 starts with '1'.
     */
    if (sc >= 0x02 && sc <= 0x0D)
        return scancode_table[sc - 0x02];

    if (sc >= 0x10 && sc <= 0x1B)
        return scancode_table[sc - 0x02];

    if (sc >= 0x1E && sc <= 0x2B)
        return scancode_table[sc - 0x02];

    if (sc >= 0x2C && sc <= 0x35)
        return scancode_table[sc - 0x02];

    if (sc == 0x39)
        return ' ';

    return 0;
}

void kernel_main(void)
{
    clear();

    print("OS x86_64\n");
    print("Shell> ");

    for (;;) {
        uint8_t status;

        __asm__ volatile (
            "inb $0x64, %0"
            : "=a"(status)
        );

        if (!(status & 1))
            continue;

        uint8_t scancode;

        __asm__ volatile (
            "inb $0x60, %0"
            : "=a"(scancode)
        );

        /* Ignore key release. */
        if (scancode & 0x80)
            continue;

        if (scancode == 0x1C) {
            putc('\n');
            print("Pong\n");
            print("Shell> ");
            continue;
        }

        if (scancode == 0x0E) {
            putc('\b');
            continue;
        }

        char c = translate_scancode(scancode);

        if (c)
            putc(c);
    }
}
