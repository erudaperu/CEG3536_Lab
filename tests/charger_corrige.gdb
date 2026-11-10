set pagination off
set confirm off
target extended-remote localhost:61234
monitor reset
load
monitor reset
dump binary memory preuves/materiel/flash_corrige_O0_relecture.bin 0x08000000 0x800269c
detach
quit
