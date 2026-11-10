    .equ RCC_BASE, 0x40021000
    .equ RCC_AHB2ENR, 0x4C
    .equ RCC_APB2ENR, 0x60
    .equ RCC_AHB2ENR_GPIOAEN, (1 << 0)
    .equ RCC_AHB2ENR_GPIOBEN, (1 << 1)
    .equ RCC_AHB2ENR_GPIOCEN, (1 << 2)
    .equ RCC_APB2ENR_SYSCFGEN, (1 << 0)
    .equ GPIOA_BASE, 0x42020000
    .equ GPIOB_BASE, 0x42020400
    .equ GPIOC_BASE, 0x42020800
    .equ GPIO_MODER, 0x00
    .equ GPIO_OTYPER, 0x04
    .equ GPIO_OSPEEDR, 0x08
    .equ GPIO_PUPDR, 0x0C
    .equ GPIO_IDR, 0x10
    .equ GPIO_ODR, 0x14
    .equ GPIO_BSRR, 0x18
    .equ GPIO_BRR, 0x28
    .equ EXTI_BASE, 0x4002F400
    .equ EXTI_RTSR1, 0x00
    .equ EXTI_FTSR1, 0x04
    .equ EXTI_SWIER1, 0x08
    .equ EXTI_RPR1, 0x0C
    .equ EXTI_FPR1, 0x10
    .equ EXTI_EXTICR1, 0x60
    .equ EXTI_IMR1, 0x80
    .equ EXTI_EMR1, 0x84
    .equ EXTI_LIGNE2, (1 << 2)
    .equ EXTICR1_EXTI2_POS, 16
    .equ EXTICR_PORT_B, 0x01
    .equ NVIC_ISER0, 0xE000E100
    .equ NVIC_ICER0, 0xE000E180
    .equ NVIC_ICPR0, 0xE000E280
    .equ NVIC_IPR_BASE, 0xE000E400
    .equ EXTI2_IRQn, 13
    .equ NVIC_PRIO_MAX, 0x00
    .equ SYSTICK_CTRL, 0xE000E010
    .equ SYSTICK_LOAD, 0xE000E014
    .equ SYSTICK_VAL, 0xE000E018
    .equ LED_ROUGE_PIN, 9
    .equ LED_VERTE_PIN, 7
    .equ LED_BLEUE_PIN, 7
    .equ BTN_USER_PIN, 13
    .equ BTN_ESTOP_PIN, 2
    .equ BTN_TOUCH_PIN, 5
    .equ BTN_USER_ACTIF_HAUT, 1
    .equ BTN_ESTOP_ACTIF_HAUT, 1
    .equ BTN_TOUCH_ACTIF_HAUT, 1
    .equ BTN_USER_PUPDR, 0
    .equ BTN_ESTOP_PUPDR, 0
    .equ BTN_TOUCH_PUPDR, 0
    .equ LED_AUCUNE, 0
    .equ LED_ROUGE, 1
    .equ LED_VERTE, 2
    .equ LED_BLEUE, 3
    .equ BTN_USER, 0
    .equ BTN_ESTOP, 1
    .equ BTN_TOUCH, 2
    .equ ETAT_ARRET, 0
    .equ ETAT_MARCHE_AVANT, 1
    .equ ETAT_MARCHE_ARRIERE, 2
    .equ ETAT_ARRET_URGENCE, 3
    .equ PERIODE_SCRUTATION_MS, 1
    .equ ANTIREBOND_MS, 30
    .equ CLIGNOTEMENT_DEMI_MS, 250
    .equ TOUCH_SIGNAL_MS, 100
    .equ DELAY_BOUCLES_PAR_MS, 1000
    .equ HORLOGE_HZ, 4000000
    .equ RCC_APB1ENR1, 0x58
    .equ RCC_AHB2ENR_GPIOEEN, (1 << 4)
    .equ RCC_APB2ENR_TIM1EN, (1 << 11)
    .equ RCC_APB1ENR1_TIM2EN, (1 << 0)
    .equ GPIOE_BASE, 0x42021000
    .equ GPIO_AFRL, 0x20
    .equ GPIO_AFRH, 0x24
    .equ GPIO_MODE_ENTREE, 0
    .equ GPIO_MODE_SORTIE, 1
    .equ GPIO_MODE_AF, 2
    .equ GPIO_AF1, 1
    .equ TIM1_BASE, 0x30001000
    .equ TIM2_BASE, 0x40000000
    .equ TIM_CR1, 0x00
    .equ TIM_CR2, 0x04
    .equ TIM_SMCR, 0x08
    .equ TIM_DIER, 0x0C
    .equ TIM_SR, 0x10
    .equ TIM_EGR, 0x14
    .equ TIM_CCMR1, 0x18
    .equ TIM_CCMR2, 0x1C
    .equ TIM_CCER, 0x20
    .equ TIM_CNT, 0x24
    .equ TIM_PSC, 0x28
    .equ TIM_ARR, 0x2C
    .equ TIM_RCR, 0x30
    .equ TIM_CCR1, 0x34
    .equ TIM_CCR2, 0x38
    .equ TIM_BDTR, 0x44
    .equ TIM_CR1_CEN, (1 << 0)
    .equ TIM_CR1_ARPE, (1 << 7)
    .equ TIM_EGR_UG, (1 << 0)
    .equ TIM_SR_UIF, (1 << 0)
    .equ TIM_CCMR1_CC1S_MASK, (3 << 0)
    .equ TIM_CCMR1_OC1PE, (1 << 3)
    .equ TIM_CCMR1_OC1M_MASK, ((7 << 4) | (1 << 16))
    .equ TIM_CCMR1_OC1M_PWM1, (6 << 4)
    .equ TIM_CCER_CC1E, (1 << 0)
    .equ TIM_CCER_CC1P, (1 << 1)
    .equ TIM_BDTR_MOE, (1 << 15)
    .equ PWM_FREQ_HZ, 20000
    .equ PWM_PSC, 0
    .equ PWM_ARR, (HORLOGE_HZ / (PWM_PSC + 1) / PWM_FREQ_HZ - 1)
    .equ PWM_PLEINE, (PWM_ARR + 1)
    .equ SYSTICK_CTRL_ENABLE, (1 << 0)
    .equ SYSTICK_CTRL_TICKINT, (1 << 1)
    .equ SYSTICK_CTRL_CLKSOURCE,(1 << 2)
    .equ SYSTICK_PERIODE_US, 1000
    .equ SYSTICK_LOAD_1MS, (HORLOGE_HZ / 1000 - 1)
    .equ SCB_SHPR3, 0xE000ED20
    .equ SCB_SHPR3_SYSTICK, 0xE000ED23
    .equ PRIO_ESTOP, 0
    .equ PRIO_ENCODEUR, 1
    .equ PRIO_SYSTICK, 2
    .equ PRIO_POS, 5
    .equ EXTI_LIGNE0, (1 << 0)
    .equ EXTICR1_EXTI0_POS, 0
    .equ EXTI0_IRQn, 11
    .equ MOTOR_PWM_PIN, 9
    .equ MOTOR_AI1_PIN, 10
    .equ MOTOR_AI2_PIN, 11
    .equ MOTOR_STB_PIN, 15
    .equ ENC_A_PIN, 0
    .equ ENC_B_PIN, 1
    .equ BUZZER_PIN, 0
    .equ ENC_PUPDR, 0
    .equ ENC_SENS_INVERSE, 1
    .equ MOTOR_ARRET, 0
    .equ MOTOR_AVANT, 1
    .equ MOTOR_ARRIERE, 2
    .equ SENS_IMMOBILE, 0
    .equ SENS_AVANT, 1
    .equ SENS_ARRIERE, 2
    .equ RAMPE_PAS_MS, 10
    .equ FENETRE_VITESSE_MS, 500
    .equ BIP_MS, 100
    .equ BIP_SILENCE_MS, 100
    .equ CONSIGNE_INITIALE, 50
    .equ CONSIGNE_PAS, 25
    .equ CONSIGNE_MIN, 25
    .equ CONSIGNE_MAX, 100
    .syntax unified
    .cpu cortex-m33
    .thumb
    .text
    .align 2
    .global motor_init
    .type motor_init, %function
motor_init:
    ldr r0, =RCC_BASE
    ldr r1, [r0, #RCC_AHB2ENR]
    orr r1, r1, #(RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOEEN)
    str r1, [r0, #RCC_AHB2ENR]
    ldr r1, [r0, #RCC_APB2ENR]
    orr r1, r1, #RCC_APB2ENR_TIM1EN
    str r1, [r0, #RCC_APB2ENR]
    ldr r1, [r0, #RCC_APB2ENR]
    ldr r0, =GPIOB_BASE
    mov r1, #((1 << (MOTOR_AI1_PIN + 16)) | (1 << (MOTOR_AI2_PIN + 16)))
    str r1, [r0, #GPIO_BSRR]
    ldr r1, [r0, #GPIO_MODER]
    bic r1, r1, #(3 << (2 * MOTOR_AI1_PIN))
    bic r1, r1, #(3 << (2 * MOTOR_AI2_PIN))
    orr r1, r1, #(GPIO_MODE_SORTIE << (2 * MOTOR_AI1_PIN))
    orr r1, r1, #(GPIO_MODE_SORTIE << (2 * MOTOR_AI2_PIN))
    str r1, [r0, #GPIO_MODER]
    ldr r1, [r0, #GPIO_OTYPER]
    bic r1, r1, #((1 << MOTOR_AI1_PIN) | (1 << MOTOR_AI2_PIN))
    str r1, [r0, #GPIO_OTYPER]
    ldr r1, [r0, #GPIO_PUPDR]
    bic r1, r1, #(3 << (2 * MOTOR_AI1_PIN))
    bic r1, r1, #(3 << (2 * MOTOR_AI2_PIN))
    str r1, [r0, #GPIO_PUPDR]
    ldr r0, =GPIOE_BASE
    mov r1, #(1 << (MOTOR_STB_PIN + 16))
    str r1, [r0, #GPIO_BSRR]
    ldr r1, [r0, #GPIO_AFRH]
    bic r1, r1, #(0xF << (4 * (MOTOR_PWM_PIN - 8)))
    orr r1, r1, #(GPIO_AF1 << (4 * (MOTOR_PWM_PIN - 8)))
    str r1, [r0, #GPIO_AFRH]
    ldr r1, [r0, #GPIO_MODER]
    bic r1, r1, #(3 << (2 * MOTOR_STB_PIN))
    orr r1, r1, #(GPIO_MODE_SORTIE << (2 * MOTOR_STB_PIN))
    bic r1, r1, #(3 << (2 * MOTOR_PWM_PIN))
    orr r1, r1, #(GPIO_MODE_AF << (2 * MOTOR_PWM_PIN))
    str r1, [r0, #GPIO_MODER]
    ldr r1, [r0, #GPIO_OTYPER]
    bic r1, r1, #((1 << MOTOR_STB_PIN) | (1 << MOTOR_PWM_PIN))
    str r1, [r0, #GPIO_OTYPER]
    ldr r1, [r0, #GPIO_OSPEEDR]
    bic r1, r1, #(3 << (2 * MOTOR_PWM_PIN))
    orr r1, r1, #(1 << (2 * MOTOR_PWM_PIN))
    bic r1, r1, #(3 << (2 * MOTOR_STB_PIN))
    str r1, [r0, #GPIO_OSPEEDR]
    ldr r1, [r0, #GPIO_PUPDR]
    bic r1, r1, #(3 << (2 * MOTOR_PWM_PIN))
    bic r1, r1, #(3 << (2 * MOTOR_STB_PIN))
    str r1, [r0, #GPIO_PUPDR]
    ldr r0, =TIM1_BASE
    movs r1, #PWM_PSC
    str r1, [r0, #TIM_PSC]
    ldr r1, =PWM_ARR
    str r1, [r0, #TIM_ARR]
    movs r1, #0
    str r1, [r0, #TIM_CCR1]
    ldr r1, [r0, #TIM_CCMR1]
    bic r1, r1, #TIM_CCMR1_CC1S_MASK
    ldr r2, =TIM_CCMR1_OC1M_MASK
    bic r1, r1, r2
    orr r1, r1, #(TIM_CCMR1_OC1M_PWM1 | TIM_CCMR1_OC1PE)
    str r1, [r0, #TIM_CCMR1]
    ldr r1, [r0, #TIM_CCER]
    bic r1, r1, #TIM_CCER_CC1P
    orr r1, r1, #TIM_CCER_CC1E
    str r1, [r0, #TIM_CCER]
    ldr r1, [r0, #TIM_CR1]
    orr r1, r1, #TIM_CR1_ARPE
    str r1, [r0, #TIM_CR1]
    ldr r1, [r0, #TIM_BDTR]
    orr r1, r1, #TIM_BDTR_MOE
    str r1, [r0, #TIM_BDTR]
    movs r1, #TIM_EGR_UG
    str r1, [r0, #TIM_EGR]
    movs r1, #0
    str r1, [r0, #TIM_SR]
    ldr r1, [r0, #TIM_CR1]
    orr r1, r1, #TIM_CR1_CEN
    str r1, [r0, #TIM_CR1]
    bx lr
    .size motor_init, .-motor_init
    .global motor_set_pwm
    .type motor_set_pwm, %function
motor_set_pwm:
    cmp r0, #100
    it hi
    movhi r0, #100
    movs r1, #PWM_PLEINE
    mul r0, r0, r1
    movs r1, #100
    udiv r0, r0, r1
    ldr r2, =TIM1_BASE
    str r0, [r2, #TIM_CCR1]
    bx lr
    .size motor_set_pwm, .-motor_set_pwm
    .global motor_set_dir
    .type motor_set_dir, %function
motor_set_dir:
    cmp r0, #MOTOR_ARRET
    beq motor_set_dir_arret
    cmp r0, #MOTOR_ARRIERE
    bhi motor_set_dir_refus
    ldr r1, =TIM1_BASE
    ldr r1, [r1, #TIM_CCR1]
    cbnz r1, motor_set_dir_refus
    ldr r1, =GPIOB_BASE
    ldr r3, [r1, #GPIO_ODR]
    cmp r0, #MOTOR_ARRIERE
    beq motor_set_dir_arriere
    tst r3, #(1 << MOTOR_AI2_PIN)
    bne motor_set_dir_refus
    ldr r2, =((1 << MOTOR_AI1_PIN) | (1 << (MOTOR_AI2_PIN + 16)))
    b motor_set_dir_ecrire
motor_set_dir_arriere:
    tst r3, #(1 << MOTOR_AI1_PIN)
    bne motor_set_dir_refus
    ldr r2, =((1 << (MOTOR_AI1_PIN + 16)) | (1 << MOTOR_AI2_PIN))
motor_set_dir_ecrire:
    str r2, [r1, #GPIO_BSRR]
    ldr r1, =GPIOE_BASE
    mov r2, #(1 << MOTOR_STB_PIN)
    str r2, [r1, #GPIO_BSRR]
    movs r0, #0
    bx lr
motor_set_dir_arret:
    ldr r1, =TIM1_BASE
    movs r2, #0
    str r2, [r1, #TIM_CCR1]
    ldr r1, =GPIOE_BASE
    mov r2, #(1 << (MOTOR_STB_PIN + 16))
    str r2, [r1, #GPIO_BSRR]
    ldr r1, =GPIOB_BASE
    mov r2, #((1 << (MOTOR_AI1_PIN + 16)) | (1 << (MOTOR_AI2_PIN + 16)))
    str r2, [r1, #GPIO_BSRR]
    movs r0, #0
    bx lr
motor_set_dir_refus:
    movs r0, #1
    bx lr
    .size motor_set_dir, .-motor_set_dir
    .global motor_stop_now
    .type motor_stop_now, %function
motor_stop_now:
    ldr r0, =TIM1_BASE
    movs r1, #0
    str r1, [r0, #TIM_CCR1]
    ldr r0, =GPIOE_BASE
    mov r1, #(1 << (MOTOR_STB_PIN + 16))
    str r1, [r0, #GPIO_BSRR]
    ldr r0, =GPIOB_BASE
    mov r1, #((1 << (MOTOR_AI1_PIN + 16)) | (1 << (MOTOR_AI2_PIN + 16)))
    str r1, [r0, #GPIO_BSRR]
    bx lr
    .size motor_stop_now, .-motor_stop_now
