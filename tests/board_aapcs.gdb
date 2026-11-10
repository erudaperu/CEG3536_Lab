set pagination off
set confirm off
set remotetimeout 10
target extended-remote localhost:61234
break enc_fronts_vers_rpm_q16
continue
echo === T2 entree vitesse depuis le C - cible STM32 ===\n
info registers r0 r1 sp lr pc
p/u ((unsigned int)$sp & 7)
x/8wx $sp
x/wu &enc_count
disassemble /r enc_fronts_vers_rpm_q16
finish
echo === Retour vitesse ===\n
p/u $r0
delete breakpoints
break motor_set_pwm
continue
echo === T2 entree PWM depuis le C - moteur en ARRET ===\n
info registers r0 r1 sp lr pc
p/u ((unsigned int)$sp & 7)
x/8wx $sp
finish
p/u $r0
x/wu 0x40012c34
delete breakpoints
echo === T3 cinq appels de test sur STM32, arguments injectes ===\n
p/u enc_fronts_vers_rpm_q16(0)
p/u enc_fronts_vers_rpm_q16(1)
p/u enc_fronts_vers_rpm_q16(748)
p/u enc_fronts_vers_rpm_q16(1870)
p/u enc_fronts_vers_rpm_q16(65535)
echo === Registres peripheriques ADC1 DMA1 LPUART1 ===\n
x/6wx 0x42028000
x/4wx 0x40020008
x/12wx 0x40008000
x/wx 0x42021014
x/2wx 0xe000ed28
detach
quit
