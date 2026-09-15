.syntax unified
.cpu cortex-m33
.thumb

.equ    RCC_AHB2ENR, 0x4002104C
.equ    GPIOA_BASE,  0x42020000
.equ    MODER,       0x00
.equ    BSRR,        0x18

.text
.global main
.type   main, %function

main:
    ldr     r0, =RCC_AHB2ENR
    ldr     r1, [r0]
    orr     r1, r1, #1
    str     r1, [r0]
    ldr     r1, [r0]

    ldr     r0, =GPIOA_BASE
    ldr     r1, [r0, #MODER]
    bic     r1, r1, #(3 << 18)
    orr     r1, r1, #(1 << 18)
    str     r1, [r0, #MODER]

    mov     r1, #(1 << 9)
    str     r1, [r0, #BSRR]

stop:
    b       stop

.size main, . - main
