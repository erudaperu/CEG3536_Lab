set pagination off
set confirm off
set print pretty off
set print array off
target remote | qemu-system-arm -M mps2-an505 -display none -monitor none -serial none -semihosting -kernel preuves/qemu_test-O0.elf -S -gdb stdio
break enc_fronts_vers_rpm_q16 if $r0 == 1870
continue
echo \n=== T2 / T3 : entree assembleur vitesse (CPU Cortex-M33 emule) ===\n
info registers r0 r1 sp lr pc
print /u ((unsigned int)$sp & 7)
x/8wx $sp
print /x preuve_volatile
echo Variable volatile partagee enc_count (valeur injectee par le banc) :\n
x/wd &enc_count
disassemble /r enc_fronts_vers_rpm_q16
finish
echo \n=== Retour Q16.16 pour 1870 fronts ===\n
print /u $r0
break motor_set_pwm if $r0 == 75
continue
echo \n=== L3-A : appel C vers motor_set_pwm, TIM1 redirige en RAM ===\n
info registers r0 r1 sp lr pc
print /u ((unsigned int)$sp & 7)
x/8wx $sp
disassemble /r motor_set_pwm
finish
print /u $r0
x/wu 0x30001034
break preuve_terminee
continue
echo \n=== Resultats complets CPU et memoire simulee ===\n
print /u resultats_vitesse
print /u ret_asm
print /u ret_c
print /u ccr_asm
print /u ccr_c
print /u echecs_vitesse
print /u echecs_evq
print /u echecs_pwm
print /u evq_test_resultats
continue
quit
