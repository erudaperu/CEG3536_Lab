set pagination off
set confirm off
target extended-remote localhost:61234
echo === Etat final STM32, firmware O2 ===\n
p ticks_ms
p compteur_pas
p etat
p consigne_pct
p pwm_pct
p estop_flag
x/wx 0x40012c34
x/wx 0x42021014
p/x (*(unsigned int*)0x42020014 & 0x200)
p/x (*(unsigned int*)0x42020814 & 0x80)
p/x (*(unsigned int*)0x42020414 & 0x80)
x/2wx 0xe000ed28
x/6wx 0x42028000
x/wx 0x42028030
x/4wx 0x40020008
x/wx 0x40020800
x/4wx 0x40008000
detach
quit
