/* ADC1 IN1/IN2, HCLK 4 MHz, DMA1 canal 1, DMAMUX requete ADC1=5.
 * Initialisation unique au demarrage, ADC desactive au reset. */
#include "stm32l552xx.h"
#include "lab3.h"
#include "adc_dma.h"
#define DMAMUX_REQUETE_ADC1 5u
static uint32_t tours, longueur;
void adc_dma_init(volatile uint16_t *tampon, uint32_t n_par_voie)
{
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN | RCC_AHB2ENR_ADCEN;
    RCC->AHB1ENR |= RCC_AHB1ENR_DMA1EN | RCC_AHB1ENR_DMAMUX1EN;
    (void)RCC->AHB1ENR;
    GPIOC->MODER |= GPIO_MODER_MODE0 | GPIO_MODER_MODE1;
    GPIOC->PUPDR &= ~(GPIO_PUPDR_PUPD0 | GPIO_PUPDR_PUPD1);
    ADC12_COMMON->CCR = (ADC12_COMMON->CCR & ~ADC_CCR_CKMODE) | ADC_CCR_CKMODE_0;
    ADC1->CR &= ~(ADC_CR_DEEPPWD | ADC_CR_ADCALDIF);
    ADC1->CR |= ADC_CR_ADVREGEN;
    delay_ms(1u); /* >20 us, SysTick deja initialise */
    ADC1->CR |= ADC_CR_ADCAL;
    while (ADC1->CR & ADC_CR_ADCAL) { }
    /* Au moins 4 cycles d'horloge ADC apres l'etalonnage. */
    __NOP(); __NOP(); __NOP(); __NOP();
    ADC1->CFGR = ADC_CFGR_CONT | ADC_CFGR_DMAEN | ADC_CFGR_DMACFG | ADC_CFGR_OVRMOD;
    ADC1->SMPR1 = ADC_SMPR1_SMP1 | ADC_SMPR1_SMP2;
    ADC1->SQR1 = (1u << ADC_SQR1_L_Pos) | (1u << ADC_SQR1_SQ1_Pos)
                 | (2u << ADC_SQR1_SQ2_Pos);
    DMA1_Channel1->CCR = 0u;
    longueur = ADC_N_VOIES * n_par_voie;
    DMAMUX1_Channel0->CCR = DMAMUX_REQUETE_ADC1;
    DMA1_Channel1->CPAR = (uint32_t)&ADC1->DR;
    DMA1_Channel1->CM0AR = (uint32_t)tampon;
    DMA1_Channel1->CNDTR = longueur;
    DMA1->IFCR = DMA_IFCR_CGIF1;
    DMA1_Channel1->CCR = DMA_CCR_MINC | DMA_CCR_PSIZE_0 | DMA_CCR_MSIZE_0 | DMA_CCR_CIRC | DMA_CCR_EN;
    tours = 0u;
    ADC1->ISR = ADC_ISR_ADRDY;
    ADC1->CR |= ADC_CR_ADEN;
    while (!(ADC1->ISR & ADC_ISR_ADRDY)) { }
    ADC1->CR |= ADC_CR_ADSTART;
}
void adc_dma_step(void)
{
    /* Appeler plus souvent qu'un tour (20,896 ms avec 64 paires).
     * Un drapeau TC est un bit : plusieurs tours non observes sont perdus. */
    if (DMA1->ISR & DMA_ISR_TCIF1) { DMA1->IFCR = DMA_IFCR_CTCIF1; tours++; }
}
uint32_t adc_dma_tours(void) { return tours; }
uint32_t adc_dma_position(void)
{
    /* Arrondir vers le bas pour ne publier que les paires IN1/IN2 completes. */
    return ((longueur - DMA1_Channel1->CNDTR) / ADC_N_VOIES) % (longueur / ADC_N_VOIES);
}
