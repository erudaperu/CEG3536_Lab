# Fiche périphérique — moteur, encodeurs et buzzer (Lab 2)

CEG 3536, A02 — Eren Arikan (300357356), équipe du Lab 1 avec Antony Zuze. À transférer dans le modèle PDF de Brightspace après les mesures.

| Périphérique | Broches | Registres et valeurs écrites | Rôle | Essais et traces à joindre |
|---|---|---|---|---|
| Moteur TIM1_CH1 | PE9 AF1; PB10 AI1; PB11 AI2; PE15 STB | PSC=0, ARR=199, CCMR1=0x68, CCER=0x1, BDTR=0x8000, CR1=0x81; CCR1=0..200 | PWM 20 kHz, direction sans inversion sous PWM, arrêt sûr | T1–T4, T7 : captures TIM1 et GPIOB/E |
| Encodeur E_A/E_B | PB0 EXTI0; PB1 IDR | EXTICR1 ligne 0 = port B; RTSR1/FTSR1/IMR1 bit 0; IPR IRQ11=0x20 | Compte les deux fronts de A et lit B pour le signe; 748 fronts/tour | T5–T6 : `enc_count`, `vitesse_fronts`, `sens_mesure` |
| SysTick | interne Cortex-M33 | LOAD=3999, CTRL=0x7, SHPR3 SysTick=0x40 | Base de 1 ms pour rampe, fenêtre et bips | T10 : SFR et `ticks_ms` |
| Buzzer | PA0 sortie GPIO | MODER=01 sur PA0; BSRR pour son/silence | Bip 100 ms, double bip, son continu d'urgence | T9 : `ticks_ms`, état de PA0 |
| E-Stop | PB2 EXTI2 | IPR IRQ13=0x00; ISR écrit CCR1=0 et BSRR STB/AI1/AI2 | Arrêt prioritaire de la propulsion | T7–T8 : point d'arrêt ISR et SFR |

**Résultats du banc :** à compléter après les essais. Les valeurs ci-dessus sont les consignes du programme, pas des captures ni des mesures. Joindre aussi la fiche « DEL et boutons » du laboratoire 1, avec les éventuelles corrections de brochage constatées.
