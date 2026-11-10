/* ---------------------------------------------------------------------------
 * main.s — point d'entrée et boucle principale (CEG 3536, laboratoire 1)
 *
 * Structure du laboratoire 2 : sorties sûres, interruptions, puis boucle
 * cadencée par tick_1ms qui appelle fsm_step.
 * Le fichier de démarrage (Core/Startup, généré par STM32CubeIDE) initialise
 * la pile, copie .data, efface .bss, appelle SystemInit puis main.
 * ------------------------------------------------------------------------- */
#include "registres.inc"
#include "registres_lab2.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

    .text
    .align  2

/* void SystemInit(void)
 * Appelé par le démarrage avant main. Au laboratoire 1, l'horloge reste
 * celle de la réinitialisation (MSI, 4 MHz) : rien à configurer.
 * Registres modifiés : aucun.                                               */
    .global SystemInit
    .type   SystemInit, %function
SystemInit:
    bx      lr
    .size   SystemInit, .-SystemInit

/* int main(void)
 * Ne retourne jamais.                                                       */
    .global main
    .type   main, %function
main:
    bl      gpio_init               /* horloges, DEL en sortie, boutons en entrée */
    bl      buzzer_init             /* PA0 éteint avant les interruptions */
    bl      motor_init              /* PWM à 0 %, STB à 0 */
    bl      encoder_init            /* EXTI0 sur les fronts de PB0 */
    bl      estop_init              /* EXTI2, priorité la plus haute */
    ldr     r0, =SYSTICK_PERIODE_US
    bl      systick_init            /* base de 1 ms */
    bl      fsm_init                /* état ARRÊT, DEL rouge seule (E1)     */

boucle_principale:
    ldr     r0, =tick_1ms
    ldr     r1, [r0]
    cmp     r1, #0
    beq     boucle_principale
    movs    r1, #0
    str     r1, [r0]
    bl      fsm_step                /* une mise à jour par tick SysTick */
    b       boucle_principale
    .size   main, .-main
