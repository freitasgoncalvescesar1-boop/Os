.section .multiboot
.align 8
header_start:
    .long 0xE85250D6
    .long 0
    .long header_end - header_start
    .long -(0xE85250D6 + (header_end - header_start))
    .word 0
    .word 0
    .long 8
header_end:

.section .text
.code32
.global _start
.type _start, @function
_start:
    cli
    mov $stack_top, %esp

    # Enable PAE.
    mov %cr4, %eax
    or $0x20, %eax
    mov %eax, %cr4

    # Install identity-mapped 2 MiB page tables.
    mov $pml4_table, %eax
    mov $pdpt_table, %ebx
    or $0x3, %ebx
    mov %ebx, (%eax)

    mov $pd_table, %ebx
    or $0x3, %ebx
    mov %ebx, (%ebx)

    mov $pd_table, %eax
    mov $0x83, %ebx
    mov %ebx, (%eax)

    mov $pml4_table, %eax
    mov %eax, %cr3

    # Enable long mode.
    mov $0xC0000080, %ecx
    rdmsr
    or $0x100, %eax
    wrmsr

    # Enable paging.
    mov %cr0, %eax
    or $0x80000000, %eax
    mov %eax, %cr0

    lgdt gdt64_ptr
    ljmp $0x08, $long_mode_entry

.code64
long_mode_entry:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    xor %ebp, %ebp
    call kernel_main

halt:
    hlt
    jmp halt

.section .rodata
.align 8
gdt64:
    .quad 0
    .quad 0x00AF9A000000FFFF
    .quad 0x00AF92000000FFFF
gdt64_ptr:
    .word gdt64_end - gdt64 - 1
    .long gdt64
gdt64_end:

.section .bss
.align 4096
pml4_table:
    .skip 4096
pdpt_table:
    .skip 4096
pd_table:
    .skip 4096
.align 16
stack_bottom:
    .skip 16384
stack_top:
