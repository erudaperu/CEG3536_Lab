/* ---------------------------------------------------------------------------
 * main.c — programme principal en C (CEG 3536, laboratoire 3)
 *          — remplace main.s et appelle les pilotes assembleur conserves
 *
 * Initialise la couche assembleur (laboratoires 1 et 2), puis les pilotes C
 * (ADC/DMA, LPUART1, DWT), et exécute une boucle cadencée par tick_1ms (E1) :
 *   production d'événements (boutons, E-Stop, encodeur, consigne, télémétrie)
 *   -> consommation par la machine à états -> sorties -> émission série.
 * Commandes série facultatives (un caractère) : z = remise à zéro des
 * compteurs ; t = 40 événements de test (saturation de la file, E12) ;
 * q = autotest de la file (E11) ; b = banc de comparaison L3-A (en ARRÊT) ;
 * a = lectures brutes de l'ADC.
 * ------------------------------------------------------------------------- */
#include "stm32l552xx.h"
#include "lab3.h"
#include "evq.h"
#include "evq_test.h"
#include "acq.h"
#include "adc_dma.h"
#include "telem.h"
#include "fsm.h"
#include "bench_l3a.h"

/* tampon DMA : ADC_N_TAMPON échantillons par voie, entrelacés IN1, IN2, ... */
static volatile uint16_t tampon_adc[ADC_N_VOIES * ADC_N_TAMPON];
static acq_t *acq_pot;  /* consigne en pourcentage */
static acq_t *acq_temp; /* temperature en dixiemes de degre */

volatile uint32_t compteur_pas;          /* passages dans la boucle (watch)    */

void SystemInit(void)
{
    /* horloge MSI 4 MHz de la réinitialisation : rien à faire (HORLOGE_HZ_C) */
}

static void dwt_init(void)
{
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
    DWT->CYCCNT = 0u;
    DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;
}

static void reponse_u32(const char *etiquette, uint32_t v)
{
    char ligne[48];
    char *p = ligne;
    while (*etiquette) *p++ = *etiquette++;
    p = telem_fmt_u32(p, v);
    *p++ = '\r'; *p++ = '\n'; *p = '\0';
    telem_put(ligne);
}

int main(void)
{
    uint32_t fenetre = 0u, periode_telem = 0u;
    int32_t  derniere_consigne = -1;
    evq_event_t e;
    bool transmettre = false;
    bool estop_notifie = false;
    uint32_t dernier_tick = 0u;

    /* couche assembleur (sorties en état sûr avant les interruptions) */
    gpio_init();
    buzzer_init();
    motor_init();
    encoder_init();
    estop_init();
    systick_init(1000u);
    /* couche C */
    dwt_init();
    evq_init();
    adc_dma_init(tampon_adc, ADC_N_TAMPON);
    acq_pot = acq_instance(0u);
    acq_temp = acq_instance(1u);
    /* potentiomètre : % = mv x 100 / 3300 ; version 2 : zone morte, hystérésis */
    acq_init(acq_pot, &tampon_adc[0], ADC_N_VOIES, ADC_N_MOY, 100, (int32_t)ADC_VREF_MV, 0);
    /* température (dixièmes de °C) : t10 = mv x (-10000) / 10900 + C
     * avec C = TEMP_C10_REF + TEMP_MV_REF x 10000 / 10900 (relation linéaire
     * étalonnée, E6) — À VÉRIFIER avec les constantes de lab3.h relevées.    */
    acq_init(acq_temp, &tampon_adc[1], ADC_N_VOIES, ADC_N_TEMP,
             -10000, -TEMP_PENTE_UV_PAR_C,
             TEMP_C10_REF + (TEMP_MV_REF * 10000) / (-TEMP_PENTE_UV_PAR_C));
    telem_init(TELEM_BAUDS);
    fsm_init();
    telem_entete();

    for (;;) {
        telem_step(); /* vider la FIFO aussi entre les ticks */
        if (tick_1ms == 0u) {
            continue;                                   /* attente du tick    */
        }
        tick_1ms = 0u;
        uint32_t t = ticks_ms;
        if (t == dernier_tick) continue;
        dernier_tick = t;
        compteur_pas++;

        /* --- producteurs d'événements --- */
        /* E-Stop prioritaire sur les boutons et sur une file saturee.
         * Ne pas effacer estop_flag ici : acquittement dans fsm uniquement. */
        if (!estop_flag) estop_notifie = false;
        bool nouvel_estop = estop_flag && !estop_notifie;
        if (nouvel_estop) {
            estop_notifie = true;
            evq_event_t urgence = {EV_ESTOP, 0u, t};
            (void)evq_push(EV_ESTOP, 0u, t); /* debordement compte si necessaire */
            fsm_traiter(&urgence); /* voie prioritaire meme si push refuse */
        }
        uint32_t user = button_pressed(BTN_USER);
        uint32_t touch = button_pressed(BTN_TOUCH);
        if (!nouvel_estop) {
            if (user) (void)evq_push(EV_USER, 0u, t);
            if (touch) (void)evq_push(EV_TOUCH, 0u, t);
        }
        if (++fenetre >= FENETRE_VITESSE_MS) {
            fenetre = 0u;
            uint32_t fronts = encoder_read(&sens_mesure);
            (void)evq_push(EV_VITESSE, fronts, t);
        }
        adc_dma_step();
        /* Attendre un premier remplissage : pas de temperature issue de zeros. */
        if (adc_dma_tours()) {
            int32_t c = acq_valeur(acq_pot);
            if (c != derniere_consigne && evq_push(EV_CONSIGNE, (uint32_t)c, t))
                derniere_consigne = c;
        }
        if (++periode_telem >= TELEM_PERIODE_MS) {
            periode_telem = 0u;
            evq_push(EV_TELEM, 0u, t);
        }

        /* --- consommateur : machine à états --- */
        while (evq_pop(&e)) {
            if (e.type == EV_TELEM) {
                transmettre = true;
            } else {
                fsm_traiter(&e);
            }
        }
        fsm_sorties();
        if (transmettre) {
            telem_trame(fsm_etat(), acq_valeur(acq_temp), evq_total(), evq_debordements());
            transmettre = false;
        }
        /* --- commandes série facultatives [FOURNI] --- */
        int rx = telem_rx();
        if (rx == 'z' && etat == ETAT_ARRET) {
            evq_init();
            derniere_consigne = -1;
            telem_put("Z,ok\r\n");
        } else if (rx == 't') {
            for (uint32_t i = 0u; i < 40u; i++) { evq_push(EV_TEST, i, t); }
        } else if (rx == 'q' && etat == ETAT_ARRET) {
            reponse_u32("Q,echecs=", evq_autotest());
        } else if (rx == 'b') {
            if (etat == ETAT_ARRET) {
                reponse_u32("B,ecarts=", bench_l3a());
                reponse_u32("B,cycles_asm=", bench_cycles_asm);
                reponse_u32("B,cycles_c=", bench_cycles_c);
                reponse_u32("B,cycles_fsm=", bench_cycles_fsm);
            } else {
                telem_put("B,refuse (ARRET requis)\r\n");
            }
        } else if (rx == 'a') {
            reponse_u32("A,pot_brut=", acq_brut(acq_pot));
            reponse_u32("A,pot_mv=", acq_mv(acq_pot));
            reponse_u32("A,temp_brut=", acq_brut(acq_temp));
            reponse_u32("A,temp_mv=", acq_mv(acq_temp));
            reponse_u32("A,tours_dma=", adc_dma_tours());
            reponse_u32("A,pertes_tx=", telem_pertes());
        }

        telem_step();
    }
}
