/* ---------------------------------------------------------------------------
 * buzzer.s — avertisseur sonore sur PA0, commande GPIO (CEG 3536, lab. 2)
 *            — complété pour le laboratoire 2
 *
 * Routines exportées : buzzer_init, buzzer_set, buzzer_bip, buzzer_step
 * Variables (.bss)   : buzzer_continu, buzzer_phase, buzzer_restant, buzzer_bips
 *
 * Le module du guide (p. 36) produit un son constant quand PA0 = 1. Les bips
 * (E9) sont une petite machine à états cadencée par buzzer_step, appelée
 * toutes les 1 ms par fsm_step : rien ne bloque.
 *   phase 0 : silence (repos)
 *   phase 1 : son pendant buzzer_restant ms, puis phase 2 s'il reste des bips
 *   phase 2 : silence BIP_SILENCE_MS, puis phase 1 (buzzer_bips--)
 * buzzer_continu = 1 force le son quelle que soit la phase (ARRÊT_URGENCE) ;
 * il est positionné par EXTI2_IRQHandler et remis à 0 à l'acquittement.
 * Variante PWM (TIM2_CH1, AF1) admise si documentée.
 *
 * Fourni : buzzer_init, buzzer_set. Réalisées : buzzer_bip, buzzer_step.
 * ------------------------------------------------------------------------- */
#include "registres.inc"
#include "registres_lab2.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

    .bss
    .align  2
    .global buzzer_continu
buzzer_continu: .space  4   /* 1 = son continu forcé                           */
buzzer_phase:   .space  4   /* 0 repos, 1 son, 2 silence entre deux bips       */
buzzer_restant: .space  4   /* ms restantes dans la phase courante             */
buzzer_bips:    .space  4   /* bips restant à produire après le bip courant    */

    .text
    .align  2

/* void buzzer_init(void)
 * Horloge GPIOA, PA0 en sortie push-pull, niveau 0, variables à 0.
 * Registres modifiés : r0, r1 (routine feuille). FOURNIE.                   */
    .global buzzer_init
    .type   buzzer_init, %function
buzzer_init:
    ldr     r0, =RCC_BASE
    ldr     r1, [r0, #RCC_AHB2ENR]
    orr     r1, r1, #RCC_AHB2ENR_GPIOAEN
    str     r1, [r0, #RCC_AHB2ENR]
    ldr     r1, [r0, #RCC_AHB2ENR]
    ldr     r0, =GPIOA_BASE
    mov     r1, #(1 << (BUZZER_PIN + 16))
    str     r1, [r0, #GPIO_BSRR]        /* silence avant le passage en sortie */
    ldr     r1, [r0, #GPIO_MODER]
    bic     r1, r1, #(3 << (2 * BUZZER_PIN))
    orr     r1, r1, #(GPIO_MODE_SORTIE << (2 * BUZZER_PIN))
    str     r1, [r0, #GPIO_MODER]
    ldr     r1, [r0, #GPIO_OTYPER]
    bic     r1, r1, #(1 << BUZZER_PIN)
    str     r1, [r0, #GPIO_OTYPER]
    ldr     r1, [r0, #GPIO_PUPDR]
    bic     r1, r1, #(3 << (2 * BUZZER_PIN))
    str     r1, [r0, #GPIO_PUPDR]
    movs    r1, #0
    ldr     r0, =buzzer_continu
    str     r1, [r0]
    ldr     r0, =buzzer_phase
    str     r1, [r0]
    ldr     r0, =buzzer_restant
    str     r1, [r0]
    ldr     r0, =buzzer_bips
    str     r1, [r0]
    bx      lr
    .size   buzzer_init, .-buzzer_init

/* void buzzer_set(uint32_t on)
 * r0 = 0 silence, autre : son. Écriture BSRR atomique ; r0-r1 seulement :
 * appelable depuis EXTI2_IRQHandler.
 * Registres modifiés : r0, r1. FOURNIE.                                     */
    .global buzzer_set
    .type   buzzer_set, %function
buzzer_set:
    ldr     r1, =GPIOA_BASE
    cmp     r0, #0
    beq     buzzer_set_off
    mov     r0, #(1 << BUZZER_PIN)
    str     r0, [r1, #GPIO_BSRR]
    bx      lr
buzzer_set_off:
    mov     r0, #(1 << (BUZZER_PIN + 16))
    str     r0, [r1, #GPIO_BSRR]
    bx      lr
    .size   buzzer_set, .-buzzer_set

/* void buzzer_bip(uint32_t n)
 * Lance n bips de BIP_MS séparés de BIP_SILENCE_MS (n = 1 : bip court,
 * n = 2 : double bip). Une séquence en cours est remplacée. n = 0 : rien.
 *   buzzer_bips = n - 1 ; buzzer_restant = BIP_MS ; buzzer_phase = 1.
 * Le son commence au prochain buzzer_step (au plus 1 ms plus tard).
 * Registres modifiés : r0-r2 (routine feuille). Réalisée (E9).           */
    .global buzzer_bip
    .type   buzzer_bip, %function
buzzer_bip:
    /* Une nouvelle demande remplace la séquence courante. */
    cbz     r0, buzzer_bip_fin
    subs    r0, r0, #1
    ldr     r1, =buzzer_bips
    str     r0, [r1]
    ldr     r1, =buzzer_restant
    movs    r2, #BIP_MS
    str     r2, [r1]
    ldr     r1, =buzzer_phase
    movs    r2, #1
    str     r2, [r1]
buzzer_bip_fin:
    bx      lr
    .size   buzzer_bip, .-buzzer_bip

/* void buzzer_step(void)
 * À appeler toutes les 1 ms (depuis fsm_step). Calcule la sortie :
 *   - buzzer_continu != 0 : buzzer_set(1), fin ;
 *   - phase 0 : buzzer_set(0) ;
 *   - phase 1 ou 2 : buzzer_restant-- ; si 0 : fin de phase :
 *       phase 1 -> s'il reste des bips (buzzer_bips--), phase 2 avec
 *                  BIP_SILENCE_MS, sinon phase 0 ;
 *       phase 2 -> phase 1 avec BIP_MS ;
 *     puis sortie = 1 en phase 1, 0 sinon.
 * Appelle buzzer_set : sauvegarde r4-r6 et LR (alignement 8).
 * Réalisée (E9). La séquence progresse chaque milliseconde.       */
    .global buzzer_step
    .type   buzzer_step, %function
buzzer_step:
    push    {r4, r5, r6, lr}
    ldr     r0, =buzzer_continu
    ldr     r0, [r0]
    /* La phase courante détermine la sortie de ce tick. */
    cbnz    r0, buzzer_step_sortie
    ldr     r4, =buzzer_phase
    ldr     r1, [r4]
    cbz     r1, buzzer_step_silence
    cmp     r1, #1
    ite     eq
    moveq   r5, #1                    /* sortie de la phase courante */
    movne   r5, #0
    ldr     r2, =buzzer_restant
    ldr     r3, [r2]
    subs    r3, r3, #1
    str     r3, [r2]
    bne     buzzer_step_phase
    cmp     r1, #1
    bne     buzzer_step_fin_pause
    ldr     r0, =buzzer_bips
    ldr     r3, [r0]
    cbz     r3, buzzer_step_fin_sequence
    subs    r3, r3, #1
    str     r3, [r0]
    movs    r1, #2
    movs    r3, #BIP_SILENCE_MS
    str     r3, [r2]
    str     r1, [r4]
    b       buzzer_step_phase
buzzer_step_fin_pause:
    movs    r1, #1
    movs    r3, #BIP_MS
    str     r3, [r2]
    str     r1, [r4]
    b       buzzer_step_phase
buzzer_step_fin_sequence:
    movs    r1, #0
    str     r1, [r4]
buzzer_step_phase:
    mov     r0, r5                    /* le changement agit au tick suivant */
    b       buzzer_step_sortie
buzzer_step_silence:
    movs    r0, #0
buzzer_step_sortie:
    bl      buzzer_set
    pop     {r4, r5, r6, pc}
    .size   buzzer_step, .-buzzer_step
