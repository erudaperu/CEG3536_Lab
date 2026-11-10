/* Test Linux des vrais fonctions C ; registres mappes en RAM du processus.
 * Ce banc ne simule ni les timings UART ni les effets physiques des registres. */
#define _GNU_SOURCE
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include "../Core/Src/telem.c"
volatile uint32_t ticks_ms;
static void vider_vers(FILE *f)
{
    while (tx_nombre) {
        if (f) fputc(tx_file[tx_tete], f);
        tx_tete=(tx_tete+1u)%TX_TAILLE; tx_nombre--;
    }
}
int main(void)
{
    assert(mmap((void *)0x40000000,0x1000000,PROT_READ|PROT_WRITE,
                MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED,-1,0)!=(void *)-1);
    assert(mmap((void *)0x42000000,0x1000000,PROT_READ|PROT_WRITE,
                MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED,-1,0)!=(void *)-1);
    telem_init(115200);
    assert(LPUART1->BRR==8889u);
    char full[501]; memset(full,'X',500); full[500]=0;
    assert(telem_put(full));
    assert(!telem_put("T,200,0,0,0,0,250,0,1,0\r\n"));
    assert(tx_nombre==500 && telem_pertes()==1 && tx_file[499]=='X');
    LPUART1->ISR=0;
    telem_step(); assert(tx_nombre==500);
    LPUART1->ISR=USART_ISR_TXE_TXFNF;
    telem_step(); assert(tx_nombre==492 && tx_tete==8);
    vider_vers(NULL);
    char number[16]; telem_fmt_i32(number,INT32_MIN);
    assert(!strcmp(number,"-2147483648"));
    FILE *f=fopen("preuves/telemetrie_synthetique.csv","wb"); assert(f);
    fputs("# Donnees synthetiques de test, pas une acquisition serie de la carte.\r\n",f);
    telem_entete(); vider_vers(f);
    etat_vehicule_t v={0};
    for(unsigned i=1;i<=150;i++) {
        ticks_ms=i*200u; v.etat=1; v.sens=1; v.consigne_pct=50; v.pwm_pct=50;
        v.vitesse_rpm_q16=748u*21028u;
        telem_trame(&v,250,i,0); vider_vers(f);
    }
    fclose(f);
    assert(tx_nombre==0);
    puts("TELEM: BRR=8889, rejet atomique, TX sans attente, INT32_MIN, enroulement OK");
    puts("TELEM: 150 trames generees par le vrai formateur C (donnees synthetiques)");
    return 0;
}
