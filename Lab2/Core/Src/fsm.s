/* ---------------------------------------------------------------------------
 * fsm.s — machine à états du panneau de commande (CEG 3536, laboratoire 1)
 *
 * Routines exportées : fsm_init (fournie), fsm_step (À COMPLÉTER)
 * Variables (.bss)   : etat, touch_enabled, compteur_transitions,
 *                      clignote_compteur, clignote_phase, touch_signal_compteur
 *
 * États (section 3) : ETAT_ARRET (rouge fixe), ETAT_MARCHE_AVANT (verte),
 *                     ETAT_MARCHE_ARRIERE (bleue), ETAT_ARRET_URGENCE (rouge 2 Hz)
 * Un seul point de mise à jour des DEL : fsm_maj_del (critère B3).
 * ------------------------------------------------------------------------- */
#if 0 /* Laboratoire 1 conservé, avec ses commentaires, comme référence.
        * L'implantation active du laboratoire 2 suit plus bas. */
#include "registres.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

    .bss
    .align  2
    .global etat
etat:                   .space  4   /* état courant (ETAT_x)                     */
    .global touch_enabled
touch_enabled:          .space  4   /* autorisation TouchPad, 0/1 (E7)           */
    .global compteur_transitions
compteur_transitions:   .space  4   /* nombre de transitions validées (T3, watch) */
clignote_compteur:      .space  4   /* pas de scrutation écoulés dans la demi-période */
clignote_phase:         .space  4   /* 0 rouge éteinte, 1 rouge allumée (E5)     */
touch_signal_compteur:  .space  4   /* pas restants d'extinction brève (E7)      */

prochain_sens:         .space  4

/* ---- Table état -> DEL (un octet par état) ------------------------------ */
    .section .rodata
etat_vers_del:
    .byte   LED_ROUGE       /* ETAT_ARRET          */
    .byte   LED_VERTE       /* ETAT_MARCHE_AVANT   */
    .byte   LED_BLEUE       /* ETAT_MARCHE_ARRIERE */
    .byte   LED_ROUGE       /* ETAT_ARRET_URGENCE (clignotante, voir fsm_maj_del) */

    .text
    .align  2

/* void fsm_init(void)
 * État initial ARRÊT, variables à zéro, DEL rouge seule (E1).
 * Appelle fsm_maj_del : LR sauvegardé ; push {r4, lr} garde l'alignement 8. */
    .global fsm_init
    .type   fsm_init, %function
fsm_init:
    push    {r4, lr}
    movs    r1, #0
    ldr     r0, =etat
    movs    r2, #ETAT_ARRET
    str     r2, [r0]
    ldr     r0, =touch_enabled
    str     r1, [r0]
    ldr     r0, =compteur_transitions
    str     r1, [r0]
    ldr     r0, =clignote_compteur
    str     r1, [r0]
    ldr     r0, =clignote_phase
    str     r1, [r0]
    ldr     r0, =touch_signal_compteur
    str     r1, [r0]
    bl      fsm_maj_del
    pop     {r4, pc}
    .size   fsm_init, .-fsm_init

/* void fsm_step(void)
 * Un pas de la machine à états, appelé toutes les PERIODE_SCRUTATION_MS.
 * Lit les événements validés (button_pressed) et le drapeau estop_flag,
 * applique les transitions E2 à E7, puis met à jour les DEL (fsm_maj_del).
 *
 * À COMPLÉTER — ordre recommandé :
 *   A. E4/E5 : si estop_flag == 1 : estop_flag = 0 ; etat = ETAT_ARRET_URGENCE ;
 *      clignote_compteur = 0 ; clignote_phase = 1.
 *   B. si etat == ETAT_ARRET_URGENCE :
 *        - E5 : les appuis sur User sont ignorés (appeler quand même
 *          button_pressed(BTN_USER) pour entretenir l'anti-rebond) ;
 *        - E6 : si button_pressed(BTN_TOUCH) == 1 ET button_raw(BTN_ESTOP) == 0
 *          (E-Stop relâché) : etat = ETAT_ARRET (acquittement). Sinon rester.
 *      sinon :
 *        - E2 : si button_pressed(BTN_USER) == 1 :
 *              ARRET -> MARCHE_AVANT, MARCHE_AVANT -> ARRET (puis ARRET -> MARCHE_ARRIERE
 *              au prochain appui, MARCHE_ARRIERE -> ARRET). Une variable "prochain sens"
 *              en .bss permet d'alterner avant/arrière à partir d'ARRÊT.
 *              compteur_transitions++ à chaque transition.
 *        - E7 : si button_pressed(BTN_TOUCH) == 1 : touch_enabled ^= 1 ;
 *              touch_signal_compteur = TOUCH_SIGNAL_MS / PERIODE_SCRUTATION_MS.
 *   C. bl fsm_maj_del.
 * Invariants (E9) : jamais deux DEL allumées (garanti par led_set) ; jamais de
 * sortie d'ARRÊT_URGENCE sans acquittement.
 * AAPCS : appelle d'autres routines -> push {r4, lr}.                         */
    .global fsm_step
    .type   fsm_step, %function
fsm_step:
    push    {r4, lr}

    /* ----- À COMPLÉTER : étapes A et B ----- */

    ldr     r0, =estop_flag
    ldr     r1, [r0]
    cmp     r1, #0
    beq     fsm_boutons
    movs    r1, #0
    str     r1, [r0]
    ldr     r0, =clignote_compteur
    str     r1, [r0]
    ldr     r0, =touch_signal_compteur
    str     r1, [r0]
    ldr     r0, =clignote_phase
    movs    r1, #1
    str     r1, [r0]
    ldr     r0, =etat
    ldr     r1, [r0]
    cmp     r1, #ETAT_ARRET_URGENCE
    beq     fsm_boutons
    movs    r1, #ETAT_ARRET_URGENCE
    str     r1, [r0]
    ldr     r0, =compteur_transitions
    ldr     r1, [r0]
    adds    r1, r1, #1
    str     r1, [r0]

fsm_boutons:
    movs    r0, #BTN_USER
    bl      button_pressed
    mov     r4, r0
    movs    r0, #BTN_TOUCH
    bl      button_pressed
    ldr     r1, =etat
    ldr     r2, [r1]
    cmp     r2, #ETAT_ARRET_URGENCE
    bne     fsm_normal
    cmp     r0, #0
    beq     fsm_fin
    movs    r0, #BTN_ESTOP
    bl      button_raw
    cmp     r0, #0
    bne     fsm_fin
    ldr     r1, =etat
    movs    r4, #ETAT_ARRET
    b       fsm_transition

fsm_normal:
    cmp     r4, #0
    beq     fsm_touch
    cmp     r2, #ETAT_ARRET
    bne     fsm_arret
    ldr     r2, =prochain_sens
    ldr     r3, [r2]
    add     r4, r3, #ETAT_MARCHE_AVANT
    eor     r3, r3, #1
    str     r3, [r2]
    b       fsm_transition
fsm_arret:
    movs    r4, #ETAT_ARRET
fsm_transition:
    str     r4, [r1]
    ldr     r1, =compteur_transitions
    ldr     r2, [r1]
    adds    r2, r2, #1
    str     r2, [r1]
fsm_touch:
    cmp     r0, #0
    beq     fsm_fin
    ldr     r1, =touch_enabled
    ldr     r2, [r1]
    eor     r2, r2, #1
    str     r2, [r1]
    ldr     r1, =touch_signal_compteur
    movs    r2, #(TOUCH_SIGNAL_MS / PERIODE_SCRUTATION_MS)
    str     r2, [r1]
fsm_fin:
    bl      fsm_maj_del
    pop     {r4, pc}
    .size   fsm_step, .-fsm_step

/* static void fsm_maj_del(void)  — routine locale, seul point d'appel de led_set
 * ARRÊT, MARCHE_AVANT, MARCHE_ARRIÈRE : DEL fixe d'après etat_vers_del.
 * ARRÊT_URGENCE : À COMPLÉTER (E5) — alterner rouge / aucune toutes les
 *   CLIGNOTEMENT_DEMI_MS / PERIODE_SCRUTATION_MS appels (clignote_compteur,
 *   clignote_phase).
 * Hors urgence : À COMPLÉTER (E7) — tant que touch_signal_compteur > 0,
 *   décrémenter et afficher LED_AUCUNE au lieu de la DEL de l'état.          */
    .type   fsm_maj_del, %function
fsm_maj_del:
    push    {r4, lr}
    ldr     r0, =etat
    ldr     r4, [r0]
    cmp     r4, #ETAT_ARRET_URGENCE
    bhi     fsm_maj_del_fin             /* état invalide : ne rien changer */

    /* ----- À COMPLÉTER : clignotement (E5) et extinction brève (E7) ----- */

    beq     fsm_maj_del_urgence
    ldr     r1, =touch_signal_compteur
    ldr     r2, [r1]
    cbz     r2, fsm_maj_del_normale
    subs    r2, r2, #1
    str     r2, [r1]
    movs    r0, #LED_AUCUNE
    b       fsm_maj_del_ecrire

fsm_maj_del_urgence:
    ldr     r1, =clignote_compteur
    ldr     r2, [r1]
    cmp     r2, #(CLIGNOTEMENT_DEMI_MS / PERIODE_SCRUTATION_MS)
    blo     fsm_maj_del_phase
    movs    r2, #0
    ldr     r3, =clignote_phase
    ldr     r0, [r3]
    eor     r0, r0, #1
    str     r0, [r3]
fsm_maj_del_phase:
    adds    r2, r2, #1
    str     r2, [r1]
    ldr     r1, =clignote_phase
    ldr     r0, [r1]
    b       fsm_maj_del_ecrire

fsm_maj_del_normale:
    ldr     r1, =etat_vers_del
    ldrb    r0, [r1, r4]                /* r0 = DEL associée à l'état */
fsm_maj_del_ecrire:
    mrs     r4, PRIMASK
    cpsid   i
    ldr     r1, =estop_flag
    ldr     r1, [r1]
    cmp     r1, #0
    it      ne
    movne   r0, #LED_ROUGE
    bl      led_set
    msr     PRIMASK, r4
fsm_maj_del_fin:
    pop     {r4, pc}
    .size   fsm_maj_del, .-fsm_maj_del
#endif

/* Laboratoire 2 : un pas par milliseconde. Les transitions gardent le cycle
 * du laboratoire 1, mais les sorties moteur et buzzer suivent les états. */
#include "registres.inc"
#include "registres_lab2.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

    .bss
    .align  2
    .global etat
etat:                   .space 4
    .global touch_enabled
touch_enabled:          .space 4      /* conservé pour l'interface lab1.h */
    .global compteur_transitions
compteur_transitions:   .space 4
clignote_compteur:      .space 4
clignote_phase:         .space 4
prochain_sens:          .space 4      /* 0 : avant, 1 : arrière */
    .global consigne_pct
consigne_pct:           .space 4
    .global pwm_pct
pwm_pct:               .space 4
rampe_compteur:        .space 4
fenetre_compteur:      .space 4

    .section .rodata
etat_vers_del_lab2:
    .byte LED_ROUGE, LED_VERTE, LED_BLEUE, LED_ROUGE
etat_vers_dir_lab2:
    .byte MOTOR_ARRET, MOTOR_AVANT, MOTOR_ARRIERE
etat_vers_bips_lab2:
    .byte 1, 1, 2

    .text
    .align 2
    .global fsm_init
    .type fsm_init, %function
fsm_init:
    push    {r4, lr}
    movs    r1, #0
    ldr     r0, =etat
    str     r1, [r0]
    ldr     r0, =touch_enabled
    str     r1, [r0]
    ldr     r0, =compteur_transitions
    str     r1, [r0]
    ldr     r0, =clignote_compteur
    str     r1, [r0]
    ldr     r0, =clignote_phase
    str     r1, [r0]
    ldr     r0, =prochain_sens
    str     r1, [r0]
    ldr     r0, =pwm_pct
    str     r1, [r0]
    ldr     r0, =rampe_compteur
    str     r1, [r0]
    ldr     r0, =fenetre_compteur
    str     r1, [r0]
    ldr     r0, =consigne_pct
    movs    r1, #CONSIGNE_INITIALE
    str     r1, [r0]
    movs    r0, #LED_ROUGE
    bl      led_set                 /* à NRST : rouge fixe, buzzer muet */
    pop     {r4, pc}
    .size fsm_init, .-fsm_init

    .global fsm_step
    .type fsm_step, %function
fsm_step:
    push    {r4, r5, r6, lr}
    /* L'ISR a déjà coupé la propulsion. On termine la transition ici. */
    ldr     r0, =estop_flag
    ldr     r1, [r0]
    cbz     r1, fsm_lire_boutons
    movs    r1, #0
    str     r1, [r0]
    bl      motor_stop_now
    ldr     r0, =pwm_pct
    movs    r1, #0
    str     r1, [r0]
    ldr     r0, =buzzer_continu
    movs    r1, #1
    str     r1, [r0]
    ldr     r0, =etat
    ldr     r1, [r0]
    cmp     r1, #ETAT_ARRET_URGENCE
    beq     fsm_lire_boutons
    movs    r1, #ETAT_ARRET_URGENCE
    str     r1, [r0]
    ldr     r0, =compteur_transitions
    ldr     r1, [r0]
    adds    r1, r1, #1
    str     r1, [r0]
    ldr     r0, =clignote_compteur
    movs    r1, #0
    str     r1, [r0]
    ldr     r0, =clignote_phase
    movs    r1, #1
    str     r1, [r0]

fsm_lire_boutons:
    movs    r0, #BTN_USER
    bl      button_pressed
    mov     r5, r0
    movs    r0, #BTN_TOUCH
    bl      button_pressed
    mov     r4, r0
    ldr     r1, =etat
    ldr     r2, [r1]
    cmp     r2, #ETAT_ARRET_URGENCE
    bne     fsm_hors_urgence
    cbz     r4, fsm_compter_fenetre
    movs    r0, #BTN_ESTOP
    bl      button_raw
    cbnz    r0, fsm_compter_fenetre
    /* Acquittement seulement après relâchement : jamais de reprise directe. */
    ldr     r0, =buzzer_continu
    movs    r1, #0
    str     r1, [r0]
    movs    r0, #ETAT_ARRET
    bl      fsm_entree_etat
    b       fsm_compter_fenetre

fsm_hors_urgence:
    cbz     r5, fsm_traiter_touch
    cmp     r2, #ETAT_ARRET
    bne     fsm_user_arret
    ldr     r1, =prochain_sens
    ldr     r2, [r1]
    add     r0, r2, #ETAT_MARCHE_AVANT
    eor     r2, r2, #1
    str     r2, [r1]
    bl      fsm_entree_etat
    b       fsm_traiter_touch
fsm_user_arret:
    movs    r0, #ETAT_ARRET
    bl      fsm_entree_etat
fsm_traiter_touch:
    cbz     r4, fsm_compter_fenetre
    ldr     r0, =consigne_pct
    ldr     r1, [r0]
    adds    r1, r1, #CONSIGNE_PAS
    cmp     r1, #CONSIGNE_MAX
    bls     fsm_consigne_ecrire
    movs    r1, #CONSIGNE_MIN
fsm_consigne_ecrire:
    str     r1, [r0]
    movs    r0, #1
    bl      buzzer_bip

fsm_compter_fenetre:
    ldr     r0, =fenetre_compteur
    ldr     r1, [r0]
    adds    r1, r1, #1
    cmp     r1, #FENETRE_VITESSE_MS
    blo     fsm_fenetre_ecrire
    movs    r1, #0
    str     r1, [r0]
    ldr     r0, =sens_mesure
    bl      encoder_read
    b       fsm_maj_sorties
fsm_fenetre_ecrire:
    str     r1, [r0]
fsm_maj_sorties:
    bl      fsm_maj_sorties_lab2
    pop     {r4, r5, r6, pc}
    .size fsm_step, .-fsm_step

/* Entrée commune hors urgence : PWM à zéro avant toute nouvelle direction.
 * Le second contrôle du drapeau coupe STB si l'ISR a préempté la routine. */
    .type fsm_entree_etat, %function
fsm_entree_etat:
    push    {r4, r5, r6, lr}
    mov     r5, r0
    ldr     r0, =estop_flag
    ldr     r0, [r0]
    cbnz    r0, fsm_entree_fin
    movs    r0, #MOTOR_ARRET
    bl      motor_set_dir
    cmp     r5, #ETAT_ARRET
    beq     fsm_entree_commune
    ldr     r0, =etat_vers_dir_lab2
    ldrb    r0, [r0, r5]
    bl      motor_set_dir
fsm_entree_commune:
    ldr     r0, =estop_flag
    ldr     r0, [r0]
    cbz     r0, fsm_entree_maj_etat
    bl      motor_stop_now           /* l'ISR a pu arriver pendant le bl */
    b       fsm_entree_fin
fsm_entree_maj_etat:
    ldr     r0, =etat
    str     r5, [r0]
    ldr     r0, =compteur_transitions
    ldr     r1, [r0]
    adds    r1, r1, #1
    str     r1, [r0]
    ldr     r0, =pwm_pct
    movs    r1, #0
    str     r1, [r0]
    ldr     r0, =rampe_compteur
    str     r1, [r0]
    ldr     r0, =etat_vers_bips_lab2
    ldrb    r0, [r0, r5]
    bl      buzzer_bip
fsm_entree_fin:
    pop     {r4, r5, r6, pc}

/* Un seul point de mise à jour de la rampe, des DEL et du buzzer. */
    .type fsm_maj_sorties_lab2, %function
fsm_maj_sorties_lab2:
    push    {r4, r5, r6, lr}
    ldr     r0, =etat
    ldr     r4, [r0]
    cmp     r4, #ETAT_MARCHE_ARRIERE
    bhi     fsm_sorties_del
    cmp     r4, #ETAT_ARRET
    beq     fsm_sorties_del
    ldr     r0, =rampe_compteur
    ldr     r1, [r0]
    adds    r1, r1, #1
    cmp     r1, #RAMPE_PAS_MS
    blo     fsm_rampe_ecrire
    movs    r1, #0
    str     r1, [r0]
    ldr     r0, =pwm_pct
    ldr     r1, [r0]
    ldr     r2, =consigne_pct
    ldr     r2, [r2]
    cmp     r1, r2
    beq     fsm_sorties_del
    blo     fsm_rampe_monter
    subs    r1, r1, #1
    b       fsm_rampe_appliquer
fsm_rampe_monter:
    adds    r1, r1, #1
fsm_rampe_appliquer:
    str     r1, [r0]
    ldr     r0, =estop_flag
    ldr     r0, [r0]
    cbnz    r0, fsm_sorties_del
    mov     r0, r1
    bl      motor_set_pwm
    ldr     r0, =estop_flag
    ldr     r0, [r0]
    cbz     r0, fsm_sorties_del
    bl      motor_stop_now           /* E-Stop a interrompu motor_set_pwm */
    b       fsm_sorties_del
fsm_rampe_ecrire:
    str     r1, [r0]

fsm_sorties_del:
    cmp     r4, #ETAT_ARRET_URGENCE
    bne     fsm_del_normale
    ldr     r0, =clignote_compteur
    ldr     r1, [r0]
    adds    r1, r1, #1
    cmp     r1, #CLIGNOTEMENT_DEMI_MS
    blo     fsm_del_compteur
    movs    r1, #0
    ldr     r2, =clignote_phase
    ldr     r3, [r2]
    eor     r3, r3, #1
    str     r3, [r2]
fsm_del_compteur:
    str     r1, [r0]
    ldr     r0, =clignote_phase
    ldr     r0, [r0]
    cmp     r0, #0
    ite     ne
    movne   r0, #LED_ROUGE
    moveq   r0, #LED_AUCUNE
    b       fsm_del_ecrire
fsm_del_normale:
    ldr     r0, =etat_vers_del_lab2
    ldrb    r0, [r0, r4]
fsm_del_ecrire:
    ldr     r1, =estop_flag
    ldr     r1, [r1]
    cmp     r1, #0
    it      ne
    movne   r0, #LED_ROUGE
    bl      led_set
    ldr     r0, =estop_flag
    ldr     r0, [r0]
    cbz     r0, fsm_buzzer_passer
    movs    r0, #LED_ROUGE
    bl      led_set                 /* corrige une préemption pendant led_set */
    /* Même double contrôle pour le son : aucune attente bloquante. */
fsm_buzzer_passer:
    bl      buzzer_step
    ldr     r0, =estop_flag
    ldr     r0, [r0]
    cbz     r0, fsm_sorties_fin
    ldr     r1, =buzzer_continu
    movs    r0, #1
    str     r0, [r1]
    bl      buzzer_set
fsm_sorties_fin:
    pop     {r4, r5, r6, pc}
