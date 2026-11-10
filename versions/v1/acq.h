/* Baseline V1 : acquisition lineaire, sans filtre ni curseur circulaire. */
#ifndef ACQ_H
#define ACQ_H
#include <stdint.h>
typedef struct acq acq_t;
acq_t *acq_instance(uint32_t index);
uint32_t acq_taille(void);
void acq_init(acq_t *, const volatile uint16_t *, uint32_t, uint32_t, int32_t, int32_t, int32_t);
uint32_t acq_brut(const acq_t *);
uint32_t acq_mv(const acq_t *);
int32_t acq_valeur(acq_t *);
#endif
