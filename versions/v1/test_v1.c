#include "acq.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
 volatile uint16_t b[32];
 for(unsigned i=0;i<16;i++) { b[2*i]=2048; b[2*i+1]=2272; }
 acq_t *p=acq_instance(0),*t=acq_instance(1);
 acq_init(p,b,2,16,100,3300,0); acq_init(t,b+1,2,16,-10000,10900,1929);
 int before=acq_valeur(t); assert(acq_valeur(p)==50);
 acq_init(p,b,2,16,50,3300,0); assert(acq_valeur(p)==25 && acq_valeur(t)==before);
 puts("ACQ V1: deux instances, moyenne 16 et gains independants OK");
}
