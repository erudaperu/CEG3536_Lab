.syntax unified
.cpu cortex-m33
.thumb
.section .vectors,"a"
.word 0x30004000
.word reset
.text
.global reset
.thumb_func
reset:
    ldr r0, =_sbss
    ldr r1, =_ebss
    movs r2, #0
1:  cmp r0, r1
    bhs 2f
    str r2, [r0], #4
    b 1b
2:  bl main
3:  b 3b
