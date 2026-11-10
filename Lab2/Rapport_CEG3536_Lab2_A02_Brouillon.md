# Laboratoire 2 — Propulsion et mesure de vitesse

CEG 3536 | Architecture d'ordinateurs II | Section A02 | Automne 2026  
Équipe du laboratoire 1 : Eren Arikan (300357356) et Antony Zuze (300221295)  
Dépôt : https://github.com/erudaperu/CEG3536_Lab — branche `lab2`

**État du rapport, 20 octobre 2026 :** calculs et code compilé; mesures T1 à T10, captures et démonstration sur la plateforme encore à faire. Les valeurs attendues ci-dessous ne sont pas présentées comme des mesures.

## 1. Introduction et exigences

J'ai repris le panneau de commande du laboratoire 1 et ajouté le moteur, l'encodeur, la base de temps SysTick et le buzzer. L'état ARRÊT garde la PWM et STB à zéro. User suit ARRÊT → AVANT → ARRÊT → ARRIÈRE → ARRÊT. Touch En fait avancer la consigne 25, 50, 75, 100 %. E-Stop a la priorité : son ISR coupe la propulsion avant que la machine à états passe en ARRÊT_URGENCE. Les exigences E1 à E12 couvrent l'initialisation, la PWM, la direction, la rampe, le comptage et la vitesse, l'E-Stop, l'acquittement, le buzzer, SysTick, les mesures et la robustesse. L'hypothèse d'horloge est MSI = 4 MHz, sans changement de `SystemInit`.

## 2. Conception

| État | DEL | PWM | AI1/AI2/STB | Son |
|---|---|---|---|---|
| ARRÊT | rouge fixe | 0 % | 0/0/0 | bip à l'entrée, silence au reset |
| MARCHE_AVANT | verte | rampe vers consigne | 1/0/1 | bip court |
| MARCHE_ARRIÈRE | bleue | rampe vers consigne | 0/1/1 | double bip |
| ARRÊT_URGENCE | rouge à 2 Hz | 0 % | 0/0/0 | continu jusqu'à l'acquittement |

`prochain_sens` alterne AVANT et ARRIÈRE uniquement quand User quitte ARRÊT. Le retour vers ARRÊT remet CCR1 à zéro avant de changer AI1/AI2. Un démarrage direct avec CCR1 non nul est refusé par `motor_set_dir`.

| Périphérique | Configuration écrite | Calcul / raison |
|---|---|---|
| TIM1_CH1, PE9 AF1 | PSC=0, ARR=199, CCMR1=0x68, CCER=0x1, BDTR=0x8000, CR1=0x81 | 4 MHz / 200 = 20 kHz; PWM mode 1 avec préchargement et MOE |
| CCR1 | 50, 100, 150, 200 à 25, 50, 75, 100 % | CCR1 = pourcentage × (ARR+1) / 100 |
| EXTI0, PB0/PB1 | deux fronts de A, B lu dans IDR, IRQ11 priorité 1 | 2 × 11 × 34 = 748 fronts/tour de sortie |
| EXTI2, PB2 | front d'appui, IRQ13 priorité 0 | coupe CCR1, STB, AI1/AI2 dans l'ISR |
| SysTick | LOAD=3999, CTRL=0x7, priorité 2 | 4 MHz / 1000 − 1 = 3999, période 1 ms |
| PA0 | sortie GPIO | un bip de 100 ms; pas de variante TIM2 |

Les adresses et champs sont nommés dans `registres.inc` et `registres_lab2.inc`, d'après RM0438 et PM0264. Le sens réel A/B et `ENC_SENS_INVERSE` doivent être confirmés au débogueur sur le banc.

## 3. Réalisation

`main.s` initialise d'abord les GPIO et les sorties sûres, puis EXTI0, EXTI2 et SysTick. La boucle attend `tick_1ms` et appelle `fsm_step` une fois par tick. La version du laboratoire 1 de `delay_ms` est gardée désactivée dans `buttons.s`; `systick.s` expose la même interface basée sur `ticks_ms`. `motor.s` programme TIM1 et impose la règle de direction. `encoder.s` compte les fronts signés en interruption et calcule la variation absolue par fenêtre de 500 ms. `buzzer.s` avance la séquence des bips sans boucle d'attente. `fsm.s` gère la rampe d'un point par 10 ms, l'affichage et les sons. Le code du laboratoire 1 y reste visible comme référence désactivée.

Les trois interruptions ont les priorités 0 (E-Stop), 1 (encodeur), 2 (SysTick). `EXTI0_IRQHandler` ne fait qu'une lecture IDR, un comptage et l'effacement de l'EXTI. `SysTick_Handler` incrémente `ticks_ms` et positionne le drapeau. `EXTI2_IRQHandler` appelle les deux routines feuilles de sécurité, met les DEL en état sûr, écrit `estop_flag`, puis acquitte EXTI. Elle sauvegarde LR pour ces appels. Les fonctions non feuilles préservent leurs registres R4–R11 modifiés; les variables partagées sont des mots alignés en `.bss`. Le démarrage, l'édition de liens, `syscalls.c` et `sysmem.c` proviennent du projet STM32CubeIDE initial; aucun pilote HAL n'est utilisé.

La compilation complète avec le compilateur GNU ARM livré avec STM32CubeIDE 2.2.0 a produit `CEG3536_Lab2.elf` et `.bin` sans avertissement. Cette vérification ne valide pas le comportement électrique, la fréquence réellement observée ou le sens de rotation.

## 4. Essais à réaliser au débogueur

| Essai | Méthode et preuve attendue | Résultat observé |
|---|---|---|
| T1 Reset | SFR TIM1/GPIO, LED et moteur après NRST | À relever |
| T2 User | quatre appuis, `etat`, ODR B/E, `sens_mesure` | À relever |
| T3 PWM | PSC, ARR, CCR1 pour 25/50/75/100 % | À relever |
| T4 Rampe | `pwm_pct` et `ticks_ms` de 0 à 100 puis de 100 à 25 | À relever |
| T5 Encodeur | `enc_count` dans chaque sens; confirmer `ENC_SENS_INVERSE` | À relever |
| T6 Vitesse | trois fenêtres par consigne et par sens; calcul tr/min | À relever |
| T7 E-Stop | point d'arrêt ISR, CCR1 et ODR après coupure, délai estimé | À relever |
| T8 Acquittement | User ignoré, Touch refusé puis accepté selon PB2 | À relever |
| T9 Buzzer | début et fin de bip dans `ticks_ms`, double bip | À relever |
| T10 SysTick/robustesse | LOAD/CTRL; ticks sur 10 s; appuis pendant rampe | À relever |

## 5. Mesures et confrontation aux exigences (L2-A)

| Grandeur | Exigence ou référence calculée | Mesure, incertitude et écart |
|---|---|---|
| PWM | 20 kHz ± 5 %; rapport à ± 2 points | À relever sur TIM1 SFR aux quatre paliers |
| Vitesse avant/arrière | croissante; environ 2 182 fronts/500 ms vers 350 tr/min à 100 % sans charge | Trois fenêtres par palier et par sens à relever |
| Conversion | tr/min = `vitesse_fronts × 120 / 748` | Calculer à partir des fronts mesurés |
| Rampe | 1 000 ms de 0 à 100 %; 750 ms de 100 à 25 % | Relever `ticks_ms` et l'écart |
| E-Stop | PWM nulle et STB=0 en moins de 1 ms | Estimer à partir du point d'arrêt et des instructions; relever SFR |
| Bip | 100 ms ± 10 % | Relever les deux instants `ticks_ms` |
| SysTick | 1 ms ± 1 % | Comparer 10 s à un chronomètre |

Le débogueur permet de constater les registres et variables malgré l'inaccessibilité des broches indiquée dans la version 1.3 de l'énoncé. L'incertitude vient notamment de la résolution d'un tick (1 ms), de la fenêtre de vitesse (500 ms) et de la vitesse réelle du moteur sans charge. La conclusion de conformité à E1–E12 doit attendre ces relevés.

## 6. Routine conservée pour L3-A

`button_pressed(uint32_t id)` garde l'interface du laboratoire 1. Le cas à comparer avec une version C est un appui maintenu, puis relâché : un seul événement doit être retourné après 30 échantillons stables. Le code n'a pas changé; les résultats sur la carte restent à relever.

## 7. Travail d'équipe

Le dépôt du laboratoire 1 est conservé dans l'historique; Lab 2 est sur `lab2`. Eren a préparé l'intégration et la compilation le 20 octobre. Les rôles de mesure, la rotation et la validation par Antony doivent être consignés après la séance dans `JOURNAL_LAB2.md`, sans attribution inventée.

## 8. Sources et déclaration d'IA

Sources : énoncé CEG3536 Lab 2 v1.3; complément de démarrage Lab 2; projet Lab 1 de l'équipe; RM0438 et PM0264 cités par l'énoncé. Aucun corrigé Lab 1 n'a été utilisé. Codex (OpenAI, GPT-6) a aidé à écrire et relire l'assembleur, à vérifier la construction et à préparer ce brouillon. Chaque membre doit pouvoir expliquer et justifier le code pendant la démonstration; l'outil n'y sera pas utilisé.
