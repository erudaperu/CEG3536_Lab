/* Annexe comparative, exclue du firmware. Une seule paire de voies globale.
 * Ajouter un capteur oblige a dupliquer etat, configuration et fonctions. */
#include <stdint.h>
volatile uint16_t echantillons[128];
uint32_t fin_paire;
int32_t consigne_precedente;
uint32_t consigne_initialisee;
int32_t temperature_offset = 1929;
static uint32_t moyenne(uint32_t voie, uint32_t n)
{
 uint32_t sum=0, k=(fin_paire+64u-n)%64u;
 for(uint32_t j=0;j<n;j++) { sum+=echantillons[2*k+voie]; k=(k+1)%64u; }
 return (sum+n/2)/n;
}
int32_t lire_consigne(void)
{
 uint32_t brut=moyenne(0,16);
 int32_t c=(int32_t)((brut*100u+2047u)/4095u);
 if(brut<123u)c=0; else if(brut>3972u)c=100;
 if(consigne_initialisee && c-consigne_precedente<=2 && consigne_precedente-c<=2)
   return consigne_precedente;
 consigne_initialisee=1; consigne_precedente=c; return c;
}
int32_t lire_temperature(void)
{
 int32_t mv=(int32_t)((moyenne(1,64)*3300u+2047u)/4095u);
 return temperature_offset-(mv*10000+5450)/10900;
}
