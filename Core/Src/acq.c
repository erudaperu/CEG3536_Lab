/* ---------------------------------------------------------------------------
 * acq.c — objet d'acquisition d'une voie analogique (CEG 3536, lab. 3, L3-C)
 *         — version 2 : filtrage et historique circulaire
 * Aucun registre : les échantillons viennent d'un tampon mémoire rempli par
 * le DMA. Toutes les opérations en entiers 32 bits.
 * Version 1 : acq_init, acq_brut, acq_mv, acq_valeur (relation linéaire).
 * Version 2 (changement d'exigence, énoncé 4.6) : acq_config_filtre et, dans
 * acq_valeur, zone morte puis hystérésis, sans toucher aux appelants.
 * ------------------------------------------------------------------------- */
#include "acq.h"

struct acq {
    /* --- privé : ne pas accéder hors de acq.c --- */
    const volatile uint16_t *src;   /* premier échantillon de la voie (tampon DMA) */
    uint32_t pas;                   /* nombre de voies entrelacées                */
    uint32_t n_moy;                 /* échantillons moyennés                      */
    int32_t  gain_num;              /* valeur = mv * gain_num / gain_den + decalage */
    int32_t  gain_den;
    int32_t  decalage;
    /* version 2 */
    int32_t  hysteresis;            /* 0 = désactivée                              */
    int32_t  zone_morte;            /* 0 = désactivée                              */
    int32_t  v_min, v_max;          /* bornes pour la zone morte                   */
    int32_t  derniere;              /* dernière valeur retournée (hystérésis)      */
    uint32_t capacite;
    uint32_t (*curseur)(void);
    uint32_t initialisee;
};
static acq_t instances[2];
acq_t *acq_instance(uint32_t index) { return index < 2u ? &instances[index] : (acq_t *)0; }
uint32_t acq_taille(void) { return (uint32_t)sizeof(acq_t); }


#define ACQ_PLEINE_ECHELLE 4095
#define ACQ_VREF_MV        3300

void acq_init(acq_t *a, const volatile uint16_t *src, uint32_t pas, uint32_t n_moy,
              int32_t gain_num, int32_t gain_den, int32_t decalage)
{
    a->src = src;
    a->pas = (pas == 0u) ? 1u : pas;
    a->n_moy = (n_moy == 0u) ? 1u : n_moy;
    a->capacite = a->n_moy;
    a->curseur = 0;
    a->gain_num = gain_num;
    a->gain_den = (gain_den == 0) ? 1 : gain_den;
    a->decalage = decalage;
    a->hysteresis = 0;
    a->zone_morte = 0;
    a->v_min = 0;
    a->v_max = 0;
    a->derniere = 0;
    a->initialisee = 0u;
}

void acq_config_filtre(acq_t *a, int32_t hysteresis, int32_t zone_morte,
                       int32_t v_min, int32_t v_max)
{
    a->hysteresis = hysteresis;
    a->zone_morte = zone_morte;
    a->v_min = v_min;
    a->v_max = v_max;
    a->initialisee = 0u;      /* la prochaine valeur est prise telle quelle   */
}

/* E4 : moyenne arrondie des n_moy échantillons src[i * pas]. */
uint32_t acq_brut(const acq_t *a)
{
    uint32_t somme = 0u;
    uint32_t fin = a->curseur ? a->curseur() % a->capacite : 0u;
    uint32_t index = (fin + a->capacite - a->n_moy) % a->capacite;
    for (uint32_t i = 0u; i < a->n_moy; ++i) {
        somme += a->src[index * a->pas];
        if (++index == a->capacite) index = 0u;
    }
    return (somme + a->n_moy / 2u) / a->n_moy;
}

uint32_t acq_mv(const acq_t *a)
{
    return (acq_brut(a) * ACQ_VREF_MV + ACQ_PLEINE_ECHELLE / 2) / ACQ_PLEINE_ECHELLE;
}

/* E5, E6 : v = mv x gain_num / gain_den + decalage ;
 * version 2 : si zone_morte > 0, v < v_min + zone_morte -> v_min et
 * v > v_max - zone_morte -> v_max ; si hysteresis > 0 et initialisee,
 * retourner derniere tant que |v - derniere| <= hysteresis ; sinon
 * derniere = v, initialisee = 1.                                            */
int32_t acq_valeur(acq_t *a)
{
    int32_t num = (int32_t)acq_mv(a) * a->gain_num;
    int32_t v = (num >= 0 ? num + a->gain_den / 2 : num - a->gain_den / 2)
                / a->gain_den + a->decalage;
    if (a->zone_morte > 0) {
        /* Comparer avant l'arrondi pour conserver les bornes 3 % / 97 %. */
        if (num < (a->v_min + a->zone_morte - a->decalage) * a->gain_den) v = a->v_min;
        else if (num > (a->v_max - a->zone_morte - a->decalage) * a->gain_den) v = a->v_max;
        if (v < a->v_min) v = a->v_min;
        if (v > a->v_max) v = a->v_max;
    }
    if (a->initialisee && a->hysteresis > 0 &&
        v - a->derniere <= a->hysteresis &&
        a->derniere - v <= a->hysteresis) return a->derniere;
    a->derniere = v;
    a->initialisee = 1u;
    return v;
}

/* Curseur : index de la prochaine paire complete dans le tampon circulaire.
 * Le fournisseur ne doit pas bloquer ; n_moy <= capacite, source valide. */
void acq_config_circulaire(acq_t *a, uint32_t capacite, uint32_t (*curseur)(void))
{
    if (capacite >= a->n_moy) { a->capacite = capacite; a->curseur = curseur; }
}
