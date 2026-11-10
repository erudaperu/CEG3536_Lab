/* ---------------------------------------------------------------------------
 * systick.s — base de temps de 1 ms par SysTick (CEG 3536, laboratoire 2)
 *             — complété pour le laboratoire 2
 *
 * Routines exportées : systick_init, SysTick_Handler, delay_ms
 * Variables (.bss)   : ticks_ms, tick_1ms
 *
 * delay_ms remplace la boucle calibrée du laboratoire 1 : SUPPRIMER l'ancienne
 * version de buttons.s (sinon : symbole défini deux fois à l'édition de liens).
 * Même interface : r0 = durée en ms. Elle n'est plus appelée dans la boucle
 * principale, cadencée par tick_1ms (E10).
 *
 * Fourni : SysTick_Handler. Réalisées : systick_init et delay_ms.
 * systick_init doit être appelée avant la boucle principale pour produire tick_1ms.
 * ------------------------------------------------------------------------- */
#include "registres.inc"
#include "registres_lab2.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

    .bss
    .align  2
    .global ticks_ms
ticks_ms:       .space  4   /* millisecondes écoulées (déborde après 49,7 jours) */
    .global tick_1ms
tick_1ms:       .space  4   /* 1 à chaque interruption ; consommé par main      */

    .text
    .align  2

/* void systick_init(uint32_t periode_us)
 * r0 = période en microsecondes (1000 pour 1 ms).
 *   LOAD = periode_us * (HORLOGE_HZ / 1 000 000) - 1 = 4 * r0 - 1 (3999 à 1 ms)
 *   VAL  = 0 (le compteur repart de LOAD)
 *   ticks_ms = tick_1ms = 0
 *   priorité SysTick = PRIO_SYSTICK << PRIO_POS dans l'octet SCB_SHPR3_SYSTICK
 *   (strb : un seul octet, ne pas écraser PendSV)
 *   CTRL = SYSTICK_CTRL_CLKSOURCE | SYSTICK_CTRL_TICKINT | SYSTICK_CTRL_ENABLE
 * Vérifier au débogueur : SYSTICK_LOAD = 0xF9F, SYSTICK_CTRL = 0x7 (bit 16
 * COUNTFLAG peut apparaître), SCB_SHPR3 = 0x40000000, ticks_ms qui avance.
 * Registres modifiés : r0-r2 (routine feuille). Réalisée (E10).          */
    .global systick_init
    .type   systick_init, %function
systick_init:
    /* Horloge MSI : 4 cycles par microseconde. */
    lsls    r0, r0, #2                 /* 4 cycles par microseconde */
    subs    r0, r0, #1
    ldr     r1, =SYSTICK_CTRL
    movs    r2, #0
    str     r2, [r1]                   /* arrêt pendant la configuration */
    ldr     r1, =SYSTICK_LOAD
    str     r0, [r1]
    ldr     r1, =SYSTICK_VAL
    str     r2, [r1]
    ldr     r1, =ticks_ms
    str     r2, [r1]
    ldr     r1, =tick_1ms
    str     r2, [r1]
    ldr     r1, =SCB_SHPR3_SYSTICK
    movs    r2, #(PRIO_SYSTICK << PRIO_POS)
    strb    r2, [r1]
    ldr     r1, =SYSTICK_CTRL
    movs    r2, #(SYSTICK_CTRL_CLKSOURCE | SYSTICK_CTRL_TICKINT | SYSTICK_CTRL_ENABLE)
    str     r2, [r1]
    bx      lr
    .size   systick_init, .-systick_init

/* void SysTick_Handler(void)   — exception SysTick (toutes les 1 ms)
 * ticks_ms++ ; tick_1ms = 1 ; rien d'autre (E10). r0-r1 empilés par le
 * matériel. FOURNIE.                                                        */
    .global SysTick_Handler
    .type   SysTick_Handler, %function
SysTick_Handler:
    ldr     r0, =ticks_ms
    ldr     r1, [r0]
    adds    r1, r1, #1
    str     r1, [r0]
    ldr     r0, =tick_1ms
    movs    r1, #1
    str     r1, [r0]
    bx      lr
    .size   SysTick_Handler, .-SysTick_Handler

/* void delay_ms(uint32_t ms)
 * Attend que ticks_ms ait avancé de r0 : lire ticks_ms au départ (r1), puis
 * boucler tant que (ticks_ms - r1) < r0 en NON SIGNÉ (subs puis cmp/bhs) :
 * correct même si ticks_ms déborde. Précision : -1/+0 ms. Requiert
 * systick_init et interruptions activées (jamais depuis une ISR).
 * Registres modifiés : r1-r3 (r0 conservé ; routine feuille).
 * Réalisée (E10). La boucle attend une différence de ticks.                   */
    .global delay_ms
    .type   delay_ms, %function
delay_ms:
    /* Horloge MSI : 4 cycles par microseconde. */
    ldr     r1, =ticks_ms
    ldr     r2, [r1]
delay_ms_attendre:
    ldr     r3, [r1]
    subs    r3, r3, r2                 /* différence non signée, même au débordement */
    cmp     r3, r0
    blo     delay_ms_attendre
    bx      lr
    .size   delay_ms, .-delay_ms
