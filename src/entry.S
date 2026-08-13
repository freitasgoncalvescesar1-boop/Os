.section .multiboot
.align 8

multiboot_header:
    .long 0xE85250D6
    .long 0
    .long multiboot_header_end - multiboot_header
    .long -(0xE85250D6 + 0 + (multiboot_header_end - multiboot_header))
    .word 0
    .word 0
    .long 8
multiboot_header_end:

.section .text
.code32
.global _start
.type _start, @function

_start:
    cli
    mov $stack_top, %esp

    # PML4[0] -> PDPT
    mov $pml4_table, %eax
    mov $pdpt_table, %ebx
    or $0x3, %ebx
    mov %ebx, (%eax)

    # PDPT[0] -> PD
    mov $pdpt_table, %eax
    mov $pd_table, %ebx
    or $0x3, %ebx
    mov %ebx, (%eax)

    # PD[0..511] -> identity mapped 2 MiB pages
    mov $pd_table, %edi
    xor %eax, %eax
    mov $512, %ecx

.fill_pd:
    mov %eax, %ebx
    or $0x83, %ebx
    mov %ebx, (%edi)
    add $8, %edi

    # Each entry maps another 2 MiB.
    add $0x200000, %eax
    loop .fill_pd

    # Load PML4.
    mov $pml4_table, %eax
    mov %eax, %cr3

    # Enable PAE.
    mov %cr4, %eax
    or $0x20, %eax
    mov %eax, %cr4

    # Enable EFER.LME.
    mov $0xC0000080, %ecx
    rdmsr
    or $0x100, %eax
    wrmsr

    # Enable paging.
    mov %cr0, %eax
    or $0x80000000, %eax
    mov %eax, %cr0

    # Load 64-bit GDT.
    lgdt gdt64_ptr

    # Far jump into long mode.
    ljmp $0x08, $long_mode_entry

.code64
long_mode_entry:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss

    xor %ebp, %ebp
    mov $stack_top, %rsp

    call kernel_main

.hang:
    hlt
    jmp .hang

.section .rodata
.align 8

gdt64:
    .quad 0x0000000000000000
    .quad 0x00AF9A000000FFFF
    .quad 0x00AF92000000FFFF

gdt64_ptr:
    .word gdt64_end - gdt64 - 1
    .long gdt64
    .long 0

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
