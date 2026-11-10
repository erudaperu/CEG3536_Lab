/* Banc CPU : seul TIM1 est redirige vers une zone RAM reservee.
 * Le source de motor_set_pwm_c est inclus sans modification. */
#include "stm32l552xx.h"
#undef TIM1
#define TIM1 ((TIM_TypeDef *)0x30001000u)
#include "../../Core/Src/l3a_c.c"
