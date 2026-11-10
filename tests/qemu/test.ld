ENTRY(reset)
MEMORY { FLASH(rx) : ORIGIN = 0x10000000, LENGTH = 1M
         RAM(rwx) : ORIGIN = 0x30000000, LENGTH = 64K }
SECTIONS {
 .text : { KEEP(*(.vectors)) *(.text*) *(.rodata*) } > FLASH
 .bss : { _sbss = .; *(.bss*) *(COMMON) _ebss = .; } > RAM
 /DISCARD/ : { *(.ARM.exidx*) *(.ARM.extab*) *(.comment) }
}
