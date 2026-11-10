/* ---------------------------------------------------------------------------
 * telem.c — télémétrie LPUART1 au niveau des registres (CMSIS, sans HAL)
 *           (CEG 3536, laboratoire 3, E10) — version complete
 *
 * LPUART1 : TX = PG7, RX = PG8 (AF8), 115 200 bauds, 8N1, vers le port COM
 * virtuel du ST-LINK (guide, p. 54-55). Le port G (broches 2 à 15) est alimenté
 * par VDDIO2 : PWR_CR2.IOSV doit être mis à 1 (RM0438, section PWR).
 * Horloge noyau = PCLK1 = 4 MHz (RCC_CCIPR1.LPUART1SEL = 00) :
 *   BRR = 256 x fck / bauds (vérifier fck >= 3 x bauds).
 * FIFO activée (CR1.FIFOEN, 8 octets) : telem_step remplit la FIFO tant que
 * ISR.TXFNF est à 1, sans jamais attendre.
 *
 * Horloges, IOSV, broches, file atomique par ligne, formatage entier,
 * en-tete, emission par FIFO et reception non bloquante.
 * ------------------------------------------------------------------------- */
#include "stm32l552xx.h"
#include "telem.h"

#define TX_TAILLE 512u
static char     tx_file[TX_TAILLE];
static uint32_t tx_tete, tx_queue, tx_nombre, pertes;

void telem_init(uint32_t bauds)
{


    RCC->APB1ENR1 |= RCC_APB1ENR1_PWREN;
    (void)RCC->APB1ENR1;
    PWR->CR2 |= PWR_CR2_IOSV;                         /* alimentation du port G */
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOGEN;
    RCC->APB1ENR2 |= RCC_APB1ENR2_LPUART1EN;
    RCC->CCIPR1 &= ~RCC_CCIPR1_LPUART1SEL;            /* 00 = PCLK1             */
    (void)RCC->APB1ENR2;

    /* PG7 (TX) : AFRL champ 7 = 8 ; PG8 (RX) : AFRH champ 0 = 8 ; MODER = 10 */
    GPIOG->AFR[0] = (GPIOG->AFR[0] & ~GPIO_AFRL_AFSEL7) | (8u << GPIO_AFRL_AFSEL7_Pos);
    GPIOG->AFR[1] = (GPIOG->AFR[1] & ~GPIO_AFRH_AFSEL8) | (8u << GPIO_AFRH_AFSEL8_Pos);
    GPIOG->MODER = (GPIOG->MODER & ~(GPIO_MODER_MODE7 | GPIO_MODER_MODE8))
                 | GPIO_MODER_MODE7_1 | GPIO_MODER_MODE8_1;
    GPIOG->OSPEEDR |= GPIO_OSPEEDR_OSPEED7_0;
    GPIOG->PUPDR = (GPIOG->PUPDR & ~GPIO_PUPDR_PUPD8) | GPIO_PUPDR_PUPD8_0; /* RX tiré à 1 */

    LPUART1->CR1 = 0u;
    LPUART1->CR2 = 0u;
    LPUART1->CR3 = 0u;
    LPUART1->BRR = (256u * HORLOGE_HZ_C + bauds / 2u) / bauds;
    LPUART1->CR1 = USART_CR1_FIFOEN | USART_CR1_TE | USART_CR1_RE;
    LPUART1->CR1 |= USART_CR1_UE;

    tx_tete = tx_queue = tx_nombre = pertes = 0u;
}

bool telem_put(const char *s)
{
    uint32_t n = 0u;
    while (s[n]) {
        if (++n > TX_TAILLE - tx_nombre) { pertes++; return false; }
    }
    /* Reservation de la ligne entiere : jamais de trame partielle. */
    while (*s) {
        tx_file[tx_queue] = *s++;
        tx_queue = (tx_queue + 1u) % TX_TAILLE;
        tx_nombre++;
    }
    return true;
}

/* E10 : tant que tx_nombre > 0 et que ISR.TXE_TXFNF est à 1,
 * écrire tx_file[tx_tete] dans TDR, avancer tx_tete modulo TX_TAILLE,
 * tx_nombre--. Jamais d'attente active.                                     */
void telem_step(void)
{
    /* Un appel remplit au plus 8 places ; aucune attente de transmission. */
    for (uint32_t i = 0u; i < 8u && tx_nombre &&
         (LPUART1->ISR & USART_ISR_TXE_TXFNF); ++i) {
        LPUART1->TDR = (uint8_t)tx_file[tx_tete];
        tx_tete = (tx_tete + 1u) % TX_TAILLE;
        tx_nombre--;
    }
}

/* Reception facultative : si ISR.RXNE_RXFNE, retourner RDR & 0xFF ;
 * si ISR.ORE, effacer par ICR = ORECF ; sinon -1.                           */
int telem_rx(void)
{
    if (LPUART1->ISR & USART_ISR_ORE) LPUART1->ICR = USART_ICR_ORECF;
    if (LPUART1->ISR & USART_ISR_RXNE_RXFNE) return (int)(LPUART1->RDR & 0xFFu);
    return -1;
}

uint32_t telem_pertes(void) { return pertes; }

/* ---- formatage entier [FOURNI] ---------------------------------------- */
char *telem_fmt_u32(char *p, uint32_t v)
{
    char tmp[11];
    int n = 0;
    do { tmp[n++] = (char)('0' + v % 10u); v /= 10u; } while (v);
    while (n) *p++ = tmp[--n];
    *p = '\0';
    return p;
}

char *telem_fmt_i32(char *p, int32_t v)
{
    uint32_t magnitude = (uint32_t)v;
    if (v < 0) { *p++ = '-'; magnitude = 0u - magnitude; }
    return telem_fmt_u32(p, magnitude);
}

/* ---- trames ------------------------------------------------------------ */
void telem_entete(void)
{
    telem_put("H,ticks_ms,etat,sens,consigne_pct,pwm_pct,temp_c_x10,vitesse_rpm_x100,nb_evenements,evq_debordements\r\n");
}

/* E10 : construire dans un tampon local la ligne
 * T,<ticks_ms>,<etat>,<sens>,<consigne_pct>,<pwm_pct>,<temp_c_x10>,
 * <vitesse_rpm_x100>,<nb_evenements>,<debordements>\r\n avec telem_fmt_u32 /
 * telem_fmt_i32, puis telem_put. Conversion Q16.16 -> centièmes :
 * ((uint64_t)q16 x 100 + 32768) >> 16.                                      */
void telem_trame(const etat_vehicule_t *v, int32_t temp_c_x10,
                 uint32_t nb_evenements, uint32_t debordements)
{
    char ligne[144], *p = ligne;
    *p++ = 'T'; *p++ = ',';
    p = telem_fmt_u32(p, ticks_ms); *p++ = ',';
    p = telem_fmt_u32(p, v->etat); *p++ = ',';
    p = telem_fmt_u32(p, v->sens); *p++ = ',';
    p = telem_fmt_u32(p, v->consigne_pct); *p++ = ',';
    p = telem_fmt_u32(p, v->pwm_pct); *p++ = ',';
    p = telem_fmt_i32(p, temp_c_x10); *p++ = ',';
    p = telem_fmt_u32(p, (uint32_t)(((uint64_t)v->vitesse_rpm_q16 * 100u + 32768u) >> 16));
    *p++ = ','; p = telem_fmt_u32(p, nb_evenements);
    *p++ = ','; p = telem_fmt_u32(p, debordements);
    *p++ = '\r'; *p++ = '\n'; *p = '\0';
    (void)telem_put(ligne);
}
