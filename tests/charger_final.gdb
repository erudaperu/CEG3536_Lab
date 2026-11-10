set pagination off
set confirm off
target extended-remote localhost:61234
monitor reset
load
monitor reset
dump binary memory preuves/materiel/flash_final_O2_relecture.bin 0x08000000 0x8002168
detach
quit
