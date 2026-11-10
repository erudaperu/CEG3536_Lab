set pagination off
set confirm off
set remotetimeout 10
target extended-remote localhost:61234
echo === T3 cinq appels de test sur STM32, arguments injectes ===\n
p/u (unsigned int) enc_fronts_vers_rpm_q16(0)
p/u (unsigned int) enc_fronts_vers_rpm_q16(1)
p/u (unsigned int) enc_fronts_vers_rpm_q16(748)
p/u (unsigned int) enc_fronts_vers_rpm_q16(1870)
p/u (unsigned int) enc_fronts_vers_rpm_q16(65535)
echo === Registres peripheriques ADC1 DMA1 LPUART1 ===\n
x/6wx 0x42028000
x/4wx 0x40020008
x/12wx 0x40008000
x/wx 0x42021014
x/2wx 0xe000ed28
detach
quit
