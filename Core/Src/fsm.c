/* Machine a etats : evenements en entree, sorties assembleur centralisees.
 * fsm_sorties est appelee une fois par milliseconde. */
#include "fsm.h"
volatile uint32_t etat, touch_enabled, compteur_transitions, consigne_pct, pwm_pct;
static uint32_t consigne_pot, prochain_sens, rampe_compteur, clignote_compteur;
static uint32_t clignote_phase, sortie_etat, bips;
static etat_vehicule_t expose;
static const uint32_t dirs[] = {MOTOR_ARRET, MOTOR_AVANT, MOTOR_ARRIERE, MOTOR_ARRET};
static const uint32_t dels[] = {LED_ROUGE, LED_VERTE, LED_BLEUE, LED_ROUGE};
static void entree(uint32_t nouveau)
{
    if (etat != nouveau) compteur_transitions++;
    etat = nouveau;
    pwm_pct = rampe_compteur = 0u;
    consigne_pct = (nouveau == ETAT_MARCHE_AVANT || nouveau == ETAT_MARCHE_ARRIERE) ? consigne_pot : 0u;
    bips = nouveau == ETAT_MARCHE_ARRIERE ? 2u : 1u;
}
void fsm_init(void)
{
    etat = ETAT_ARRET;
    touch_enabled = compteur_transitions = consigne_pct = pwm_pct = 0u;
    consigne_pot = prochain_sens = rampe_compteur = clignote_compteur = 0u;
    clignote_phase = 1u; sortie_etat = UINT32_MAX; bips = 0u;
    expose = (etat_vehicule_t){0};
    expose.sens = SENS_IMMOBILE;
    fsm_sorties();
}
void fsm_traiter(const evq_event_t *e)
{
    if (!e) return;
    switch (e->type) {
    case EV_ESTOP:
        if (etat != ETAT_ARRET_URGENCE) {
            entree(ETAT_ARRET_URGENCE);
            clignote_compteur = 0u; clignote_phase = 1u;
        }
        bips = 0u;
        break;
    case EV_USER:
        if (estop_flag || button_raw(BTN_ESTOP)) break;
        if (etat == ETAT_ARRET) {
            entree(prochain_sens ? ETAT_MARCHE_ARRIERE : ETAT_MARCHE_AVANT);
            prochain_sens ^= 1u;
        } else if (etat == ETAT_MARCHE_AVANT || etat == ETAT_MARCHE_ARRIERE) entree(ETAT_ARRET);
        break;
    case EV_TOUCH:
        if (etat == ETAT_ARRET_URGENCE) {
            if (!button_raw(BTN_ESTOP)) {
                estop_flag = 0u;
                entree(ETAT_ARRET);
            }
        } else { touch_enabled ^= 1u; bips = 1u; }
        break;
    case EV_CONSIGNE:
        consigne_pot = e->valeur > 100u ? 100u : e->valeur;
        if (etat == ETAT_MARCHE_AVANT || etat == ETAT_MARCHE_ARRIERE) consigne_pct = consigne_pot;
        break;
    case EV_VITESSE:
        expose.vitesse_rpm_q16 = enc_fronts_vers_rpm_q16(e->valeur);
        expose.sens = sens_mesure;
        break;
    default: break;
    }
}
void fsm_sorties(void)
{
    /* Le drapeau reste verrouille jusqu'a l'acquittement. L'ISR coupe deja
     * materiellement la propulsion ; ce controle evite la reprise par C. */
    if (estop_flag && etat != ETAT_ARRET_URGENCE) {
        const evq_event_t e = {EV_ESTOP, 0u, ticks_ms};
        fsm_traiter(&e);
    }
    if (sortie_etat != etat) {
        motor_stop_now(); /* CCR1 nul AVANT de changer AI1/AI2/STB */
        if (etat != ETAT_ARRET_URGENCE && !estop_flag) (void)motor_set_dir(dirs[etat]);
        sortie_etat = etat;
    }
    if (etat == ETAT_ARRET_URGENCE || estop_flag) {
        motor_stop_now(); pwm_pct = consigne_pct = 0u;
        buzzer_continu = 1u;
        if (++clignote_compteur >= CLIGNOTEMENT_DEMI_MS) {
            clignote_compteur = 0u; clignote_phase ^= 1u;
        }
        led_set(clignote_phase ? LED_ROUGE : LED_AUCUNE);
    } else {
        buzzer_continu = 0u;
        if (etat == ETAT_MARCHE_AVANT || etat == ETAT_MARCHE_ARRIERE) {
            if (++rampe_compteur >= RAMPE_PAS_MS) {
                rampe_compteur = 0u;
                if (pwm_pct < consigne_pct) pwm_pct++;
                else if (pwm_pct > consigne_pct) pwm_pct--;
                (void)motor_set_pwm(pwm_pct);
            }
        } else { pwm_pct = consigne_pct = 0u; (void)motor_set_pwm(0u); }
        led_set(dels[etat]);
        if (bips) buzzer_bip(bips);
    }
    bips = 0u;
    /* L'ISR peut avoir preempte un appel assembleur : reaffirmer la coupure.
     * La latence exacte et les interleavings restent a verifier sur cible. */
    if (estop_flag && etat != ETAT_ARRET_URGENCE) {
        const evq_event_t e = {EV_ESTOP, 0u, ticks_ms};
        fsm_traiter(&e);
        motor_stop_now(); buzzer_continu = 1u; led_set(LED_ROUGE);
    }
    buzzer_step();
}
const etat_vehicule_t *fsm_etat(void)
{
    expose.etat = etat; expose.consigne_pct = consigne_pct;
    expose.pwm_pct = pwm_pct; expose.transitions = compteur_transitions;
    return &expose;
}
