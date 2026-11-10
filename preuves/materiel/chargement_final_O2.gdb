set pagination off
set confirm off
target extended-remote localhost:61234
monitor reset
load
monitor reset
dump binary memory /home/erenarikan/.codex/.chatgpt-projects/g-p-6a8b6ddab12c8191bf5a0182ace3f622/output/lab3/CEG3536_Lab3_Arikan_Zuze/preuves/materiel/flash_verification_finale_O2.bin 0x08000000 0x8002168
detach
quit
