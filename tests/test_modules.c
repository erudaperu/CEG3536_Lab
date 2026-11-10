#include <assert.h>
#include <stdio.h>
#include "fsm.h"
#include "acq.h"
volatile uint32_t estop_flag, buzzer_continu, ticks_ms, sens_mesure;
static uint32_t ccr, dir, led, raw_estop, refus, bip, inject_pwm_estop;
uint32_t button_raw(uint32_t b) { return b == BTN_ESTOP ? raw_estop : 0u; }
uint32_t motor_set_dir(uint32_t d) { if (ccr) { refus++; return 1u; } dir=d; return 0u; }
uint32_t motor_set_pwm(uint32_t p) { if(inject_pwm_estop) { estop_flag=raw_estop=1; inject_pwm_estop=0; } ccr = (p > 100u ? 100u : p)*2u; return ccr; }
void motor_stop_now(void) { ccr=0u; dir=MOTOR_ARRET; }
void led_set(uint32_t l) { assert(l <= LED_BLEUE); led=l; }
void buzzer_bip(uint32_t n) { bip=n; }
void buzzer_step(void) { }
/* Speed arithmetic surrogate here; real assembly tested separately in QEMU. */
uint32_t enc_fronts_vers_rpm_q16(uint32_t f) { return f*21028u; }
static void event(evq_type_t t, uint32_t v) { evq_event_t e={t,v,0u}; fsm_traiter(&e); }
static uint32_t cursor;
static uint32_t position(void) { return cursor; }
int main(void)
{
    volatile uint16_t samples[128];
    acq_t *pot = acq_instance(0u), *temp = acq_instance(1u);
    assert(!acq_instance(2u));
    for (unsigned i=0;i<64;i++) { samples[2*i]=2048; samples[2*i+1]=2272; }
    acq_init(pot,samples,2,16,100,3300,0);
    acq_config_circulaire(pot,64,position);
    acq_init(temp,samples+1,2,64,-10000,10900,1930);
    acq_config_circulaire(temp,64,position);
    assert(acq_brut(pot)==2048 && acq_valeur(pot)==50);
    for(unsigned i=0;i<64;i++) samples[2*i+1]=(uint16_t)i;
    assert(acq_brut(temp)==32); /* moyenne arrondie de 0..63, pas de 0..15 */
    for(unsigned i=0;i<64;i++) samples[2*i+1]=2272;
    int before=acq_valeur(temp);
    acq_init(pot,samples,2,16,50,3300,0);
    assert(acq_valeur(pot)==25 && acq_valeur(temp)==before);
    acq_init(pot,samples,2,16,100,3300,0);
    acq_config_circulaire(pot,64,position);
    acq_config_filtre(pot,2,3,0,100);
    unsigned edges[]={0,122,123,3972,3973,4095};
    int results[]={0,0,3,97,100,100};
    for(unsigned j=0;j<6;j++) {
        for(unsigned i=0;i<64;i++) samples[2*i]=edges[j];
        acq_config_filtre(pot,2,3,0,100);
        assert(acq_valeur(pot)==results[j]);
    }
    assert(acq_valeur(temp)==before);
    /* Ring wraps: last 16 of 64, not first 16. */
    for(unsigned i=0;i<64;i++) samples[2*i]=(uint16_t)i;
    cursor=4;
    assert(acq_brut(pot)==44); /* indices 52..63,0..3 => 43.5 */
    for(unsigned i=0;i<64;i++) samples[2*i]=2048;
    acq_config_filtre(pot,2,3,0,100);
    assert(acq_valeur(pot)==50);
    for(unsigned i=0;i<64;i++) samples[2*i]=2129; /* 52 % */
    assert(acq_valeur(pot)==50);
    for(unsigned i=0;i<64;i++) samples[2*i]=2170; /* 53 % */
    assert(acq_valeur(pot)==53);
    puts("ACQ: moyennes 16/64, independance, bornes, enroulement, hysteresis OK");
    fsm_init(); assert(etat==ETAT_ARRET && ccr==0 && dir==MOTOR_ARRET && led==LED_ROUGE);
    event(EV_CONSIGNE,100); fsm_sorties(); assert(ccr==0 && consigne_pct==0);
    event(EV_USER,0); fsm_sorties(); assert(etat==ETAT_MARCHE_AVANT && dir==MOTOR_AVANT);
    for(unsigned i=0;i<999;i++) fsm_sorties();
    assert(pwm_pct==100 && ccr==200);
    event(EV_USER,0); fsm_sorties(); assert(etat==ETAT_ARRET && ccr==0 && dir==MOTOR_ARRET);
    event(EV_USER,0); fsm_sorties(); assert(etat==ETAT_MARCHE_ARRIERE && dir==MOTOR_ARRIERE && bip==2);
    for(unsigned i=0;i<20;i++) fsm_sorties();
    raw_estop=estop_flag=1; fsm_sorties();
    assert(etat==ETAT_ARRET_URGENCE && ccr==0 && dir==MOTOR_ARRET && buzzer_continu);
    event(EV_USER,0); event(EV_CONSIGNE,100); event(EV_TOUCH,0); fsm_sorties();
    assert(etat==ETAT_ARRET_URGENCE && ccr==0);
    raw_estop=0; event(EV_TOUCH,0); fsm_sorties();
    assert(etat==ETAT_ARRET && ccr==0 && !buzzer_continu && !estop_flag);
    event(EV_TOUCH,0); fsm_sorties(); assert(touch_enabled==1 && bip==1);
    event(EV_VITESSE,1870); assert(fsm_etat()->vitesse_rpm_q16==39322360u);
    event(EV_USER,0); fsm_sorties();
    inject_pwm_estop=1;
    for(unsigned i=0;i<10;i++) fsm_sorties();
    assert(etat==ETAT_ARRET_URGENCE && ccr==0 && dir==MOTOR_ARRET);
    raw_estop=0; event(EV_TOUCH,0); fsm_sorties();
    uint32_t rng=12345u;
    for(unsigned i=0;i<10000;i++) {
        rng=rng*1664525u+1013904223u;
        if((rng&31u)==0u) { estop_flag=raw_estop=1; }
        if((rng&31u)==1u) raw_estop=0;
        event((evq_type_t)(1u+(rng%6u)),(rng>>8)%120u);
        fsm_sorties();
        assert(etat<=ETAT_ARRET_URGENCE && ccr<=200 && consigne_pct<=100);
        if(etat==ETAT_ARRET || etat==ETAT_ARRET_URGENCE) assert(ccr==0 && dir==MOTOR_ARRET);
    }
    assert(refus==0);
    puts("FSM: cycle, rampe, arret sous PWM, urgence/acquittement, Touch, vitesse, interruption injectee et 10000 evenements OK");
    return 0;
}
