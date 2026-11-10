/* Cortex-M33 AN505 : tests CPU uniquement, aucun modele STM32L552. */
#include "lab3.h"
#include "evq_test.h"
#include "bench_l3a.h"
#define CCR1_SIM (*(volatile uint32_t *)0x30001034u)
volatile uint32_t echecs_pwm, ret_asm[8], ret_c[8], ccr_asm[8], ccr_c[8];
volatile uint32_t resultats_vitesse[5], echecs_vitesse, echecs_evq;
volatile uint32_t preuve_volatile, echecs_encodeur;
static void sortie(const char *s)
{
    register uint32_t r0 __asm("r0") = 4u;
    register const char *r1 __asm("r1") = s;
    __asm volatile("bkpt 0xab" : "+r"(r0) : "r"(r1) : "memory");
}
__attribute__((noinline)) void preuve_terminee(void) { __asm volatile("nop"); }
int main(void)
{
    const uint32_t fronts[] = {0u,1u,748u,1870u,65535u};
    const uint32_t attendu[] = {0u,21028u,15728944u,39322360u,1378069980u};
    preuve_volatile = 0x12345678u;
    enc_count = 0;
    if (encoder_read(0) != 0u || sens_mesure != SENS_IMMOBILE) echecs_encodeur++;
    enc_count = 748;
    if (encoder_read(0) != 748u || sens_mesure != SENS_AVANT) echecs_encodeur++;
    enc_count = 0;
    if (encoder_read(0) != 748u || sens_mesure != SENS_ARRIERE) echecs_encodeur++;

    enc_count = 1870; /* variable partagee reelle du pilote, valeur injectee par le banc */
    for (unsigned i=0;i<5;i++) {
        resultats_vitesse[i]=enc_fronts_vers_rpm_q16(fronts[i]);
        if(resultats_vitesse[i]!=attendu[i]) echecs_vitesse++;
    }
    const uint32_t cas_pwm[] = {0u,1u,25u,50u,75u,99u,100u,UINT32_MAX};
    for (unsigned i=0;i<8;i++) {
        CCR1_SIM=0u; ret_asm[i]=motor_set_pwm(cas_pwm[i]); ccr_asm[i]=CCR1_SIM;
        CCR1_SIM=0u; ret_c[i]=motor_set_pwm_c(cas_pwm[i]); ccr_c[i]=CCR1_SIM;
        uint32_t attendu_pwm = (cas_pwm[i]>100u ? 100u : cas_pwm[i])*2u;
        if (ret_asm[i]!=attendu_pwm || ret_c[i]!=attendu_pwm ||
            ccr_asm[i]!=attendu_pwm || ccr_c[i]!=attendu_pwm) echecs_pwm++;
    }
    echecs_evq=evq_autotest();
    sortie(echecs_evq || echecs_vitesse || echecs_pwm || echecs_encodeur ? "QEMU Cortex-M33: ECHEC\n" : "QEMU Cortex-M33: encodeur signe 3/3, vitesse 5/5, evq 12/12, PWM ASM/C 8/8 OK (TIM1 simule en RAM)\n");
    preuve_terminee();
    register uint32_t r0 __asm("r0") = 0x18u;
    register uint32_t r1 __asm("r1") = 0x20026u;
    __asm volatile("bkpt 0xab" : "+r"(r0) : "r"(r1) : "memory");
    for(;;) { }
}
