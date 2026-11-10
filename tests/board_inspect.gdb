set pagination off
set confirm off
target extended-remote localhost:61234
echo === STM32L552 reel - controle initial ===\n
info registers pc sp lr xpsr
p ticks_ms
p compteur_pas
p etat
p pwm_pct
p estop_flag
x/3wx 0xe000ed28
p/x *(unsigned int*)0x40012c34
p/x *(unsigned int*)0x40020008
p/x *(unsigned int*)0x4000800c
p tampon_adc
p tours
p bench_ret_asm
p bench_ret_c
p bench_ccr_asm
p bench_ccr_c
p bench_cycles_asm
p bench_cycles_c
p bench_cycles_fsm
detach
quit
