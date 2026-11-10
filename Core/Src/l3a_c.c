/* Version C du motor_set_pwm conserve dans le projet Lab2 retrouve.
 * Saturation a 100 %, PWM_PLEINE=200, meme valeur ecrite et retour.
 * Seul le banc de comparaison appelle cette version ; production en assembleur. */
#include "stm32l552xx.h"
#include "bench_l3a.h"
uint32_t motor_set_pwm_c(uint32_t pct)
{
    if (pct > 100u) pct = 100u;
    uint32_t ccr = (pct * 200u) / 100u;
    TIM1->CCR1 = ccr;
    return ccr;
}
