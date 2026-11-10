/* Q16.16 : round(240 * 65536 / 748) = 21028.
 * Erreur relative +0,00193278 %, fronts <= 204249 sans debordement.
 * AAPCS : r0 entree/retour, r1 temporaire ; SP et r4-r11 inchanges. */
.syntax unified
.cpu cortex-m33
.thumb
.text
.align 2
.global enc_fronts_vers_rpm_q16
.type enc_fronts_vers_rpm_q16, %function
.thumb_func
enc_fronts_vers_rpm_q16:
    movw r1, #21028
    mul r0, r0, r1
    bx lr
.size enc_fronts_vers_rpm_q16, .-enc_fronts_vers_rpm_q16
.section .note.GNU-stack,"",%progbits
