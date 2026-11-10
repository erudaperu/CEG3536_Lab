set pagination off
set confirm off
target extended-remote localhost:61234
echo === Regression du sens encodeur sur STM32, entrees injectees, moteur arrete ===\n
set $ancien_count = *(unsigned int*)&enc_count
set $ancien_repere = *(unsigned int*)&enc_repere
set $ancien_sens = *(unsigned int*)&sens_mesure
set $anciens_fronts = *(unsigned int*)&vitesse_fronts
set *(unsigned int*)&enc_count = 0
set *(unsigned int*)&enc_repere = 0
p/u (unsigned int)encoder_read(0)
p sens_mesure
set *(unsigned int*)&enc_count = 748
p/u (unsigned int)encoder_read(0)
p sens_mesure
set *(unsigned int*)&enc_count = 0
p/u (unsigned int)encoder_read(0)
p sens_mesure
set *(unsigned int*)&enc_count = $ancien_count
set *(unsigned int*)&enc_repere = $ancien_repere
set *(unsigned int*)&sens_mesure = $ancien_sens
set *(unsigned int*)&vitesse_fronts = $anciens_fronts
disassemble /r encoder_read
x/2wx 0xe000ed28
detach
quit
