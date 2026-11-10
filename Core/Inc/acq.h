/* ---------------------------------------------------------------------------
 * acq.h — objet d'acquisition d'une voie analogique (CEG 3536, lab. 3, L3-C)
 *
 * Une instance par voie. L'état est privé : les champs de acq_t ne sont lus
 * et écrits que par les fonctions de acq.c (type incomplet dans cet en-tete).
 * La source des échantillons est le tampon circulaire rempli par le DMA :
 * src pointe sur le premier échantillon de la voie, pas = nombre de voies
 * entrelacées, n_moy = nombre d'échantillons moyennés (<= échantillons par
 * voie dans le tampon).
 * Version 2 (changement d'exigence, section 4.6 de l'énoncé) :
 * acq_config_filtre ajoute hystérésis et zone morte à acq_valeur, sans
 * changer les appelants ailleurs qu'à l'initialisation.
 * ------------------------------------------------------------------------- */
#ifndef ACQ_H
#define ACQ_H

#include <stdint.h>

/* Deux instances statiques, pas d'allocation dynamique. Champs prives dans acq.c. */
typedef struct acq acq_t;
acq_t *acq_instance(uint32_t index); /* 0 = pot, 1 = temperature; sinon NULL */
uint32_t acq_taille(void);         /* cout memoire d'une instance sur la cible */


void     acq_init(acq_t *a, const volatile uint16_t *src, uint32_t pas, uint32_t n_moy,
                  int32_t gain_num, int32_t gain_den, int32_t decalage);
void     acq_config_filtre(acq_t *a, int32_t hysteresis, int32_t zone_morte,
                           int32_t v_min, int32_t v_max);           /* version 2 */
uint32_t acq_brut(const acq_t *a);      /* moyenne des n_moy échantillons (0..4095) */
uint32_t acq_mv(const acq_t *a);        /* tension en millivolts                     */
int32_t  acq_valeur(acq_t *a);          /* valeur étalonnée (%, dixièmes de °C, ...) */

void acq_config_circulaire(acq_t *a, uint32_t capacite, uint32_t (*curseur)(void));

#endif /* ACQ_H */
