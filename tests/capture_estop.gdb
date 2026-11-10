set pagination off
set confirm off
target extended-remote localhost:61234
break fsm_traiter if e->type == 3
continue
echo === Capture declenchee par EV_ESTOP physique apres coupure ISR ===\n
p *e
p estop_flag
p etat
p pwm_pct
x/wx 0x42020410
x/wx 0x42021014
x/wx 0x40012c34
info registers pc sp lr
x/2wx 0xe000ed28
delete breakpoints
finish
p etat
p estop_flag
detach
quit
