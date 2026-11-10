/* V1 : deux objets encapsules, moyenne sur le tampon entier, gain propre. */
#include "acq.h"
struct acq { const volatile uint16_t *src; uint32_t pas,n; int32_t num,den,offset; };
static acq_t objets[2];
acq_t *acq_instance(uint32_t i) { return i<2 ? &objets[i] : (acq_t *)0; }
uint32_t acq_taille(void) { return (uint32_t)sizeof(acq_t); }
void acq_init(acq_t *a,const volatile uint16_t *s,uint32_t pas,uint32_t n,int32_t num,int32_t den,int32_t offset)
{ a->src=s; a->pas=pas?pas:1; a->n=n?n:1; a->num=num; a->den=den?den:1; a->offset=offset; }
uint32_t acq_brut(const acq_t *a)
{ uint32_t sum=0; for(uint32_t i=0;i<a->n;i++) sum+=a->src[i*a->pas]; return (sum+a->n/2)/a->n; }
uint32_t acq_mv(const acq_t *a) { return (acq_brut(a)*3300u+2047u)/4095u; }
int32_t acq_valeur(acq_t *a)
{ int32_t n=(int32_t)acq_mv(a)*a->num; return (n>=0?n+a->den/2:n-a->den/2)/a->den+a->offset; }
