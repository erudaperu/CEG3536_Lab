# JOURNAL.md — CEG 3536, laboratoire 2 (automne 2026)

Équipe du laboratoire 1 : Eren Arikan (300357356) et Antony Zuze (300221295) — A02 — dépôt : https://github.com/erudaperu/CEG3536_Lab, branche `lab2`.

## Suivi de J1 et rôles

Le dépôt du laboratoire 1 est conservé sur `main`; le travail du laboratoire 2 part du commit `07138bd` sur `lab2`. Le journal J1 du laboratoire 1 reste intact. La rotation des rôles et les mesures réalisées en séance sont à confirmer avec Antony; je ne les inscris pas comme faites sans relevé.

| Séance | Réalisation documentée | Validation encore requise |
|---|---|---|
| 13 octobre, séance 1 A02 | Aucun relevé matériel disponible dans ce dépôt | Configurations, broches et niveau des entrées à vérifier |
| 20 octobre, séance 2 A02 | Eren : intégration du complément, routines assembleur et compilation avec l'outil STM32CubeIDE 2.2.0 | Antony et Eren : T1 à T10 au débogueur et démonstration devant l'assistant |

## Calculs avant les mesures

| Grandeur | Calcul avec MSI à 4 MHz | Valeur programmée / attendue | Essai |
|---|---|---|---|
| PWM moteur | 4 000 000 / ((0 + 1)(199 + 1)) | 20 000 Hz; PSC 0, ARR 199 | T3 |
| CCR1 à 25 / 50 / 75 / 100 % | pourcentage × 200 / 100 | 50 / 100 / 150 / 200 | T3 |
| SysTick | 4 000 000 / 1 000 - 1 | LOAD 3999, soit 0xF9F | T10 |
| Rampe | 1 point / 10 ms | 0 à 100 % en 1 000 ms | T4 |
| Encodeur | 2 fronts × 11 impulsions × 34 | 748 fronts par tour de sortie | T5 |
| Vitesse | fronts × 120 / 748 | tr/min pour une fenêtre de 500 ms | T6 |
| Référence à 350 tr/min | 350 × 748 / 120 | environ 2 182 fronts / 500 ms | T6 |

Ces nombres sont calculés à partir de l'énoncé et des constantes du code; ce ne sont pas des mesures du banc. Le sens réel du moteur, `ENC_SENS_INVERSE` et les rappels des entrées PB0/PB1 restent à confirmer en T5.

## Travail et décisions consignés le 20 octobre

- J'ai gardé les fichiers et commentaires du laboratoire 1. L'ancienne `delay_ms` est désactivée dans `buttons.s`; la version sur SysTick garde son interface dans `systick.s`.
- J'ai ajouté les fichiers du complément, puis complété TIM1, la règle de direction, l'ISR de l'encodeur, la lecture par fenêtre, SysTick et les bips. La machine à états du laboratoire 1 reste présente comme référence désactivée dans `fsm.s`.
- L'E-Stop coupe d'abord CCR1, STB et AI1/AI2 dans son ISR. Les transitions et la rampe relisent `estop_flag` après leurs écritures, pour recouper la propulsion si l'interruption les a préemptées.
- La construction GNU ARM avec l'outil fourni dans STM32CubeIDE 2.2.0 a produit l'ELF et le BIN sans avertissement. Cela vérifie la compilation et l'édition de liens, pas le fonctionnement sur la carte.

## Essais T1 à T10

| Essai | État au 20 octobre | Relevé à inscrire en séance |
|---|---|---|
| T1 Réinitialisation | À mesurer | `etat`, CCR1, ODR B/E, DEL, buzzer et mouvement |
| T2 Cycle User et sens | À mesurer | quatre états, AI1/AI2/STB et `sens_mesure` |
| T3 PWM | Calculé, à mesurer | PSC, ARR, CCR1 aux quatre consignes; captures SFR |
| T4 Rampe | Calculé, à mesurer | `pwm_pct` et `ticks_ms` en montée et descente |
| T5 Encodeur | À mesurer | `enc_count` dans les deux sens; sens de comptage |
| T6 Vitesse | À mesurer | trois fenêtres de 500 ms à chaque palier et dans les deux sens |
| T7 E-Stop | À mesurer | CCR1, STB, `estop_flag`, point d'arrêt et estimation du délai |
| T8 Urgence et acquittement | À mesurer | User ignoré; Touch refusé puis accepté |
| T9 Buzzer | À mesurer | début/fin des bips avec `ticks_ms` |
| T10 SysTick et robustesse | À mesurer | LOAD/CTRL, ticks sur 10 s, appuis pendant la rampe |

## Routine conservée pour L3-A

`button_pressed(uint32_t id)` reste disponible sans changement d'interface. Les cas User, Touch En, appui maintenu et relâchement devront être relevés au débogueur pour la comparaison avec une version C au laboratoire 3.

## Sources et usage d'IA

Sources : projet du laboratoire 1 de l'équipe, énoncé Lab 2 v1.3, complément de démarrage Lab 2, RM0438 et PM0264 indiqués par l'énoncé. Je n'ai pas utilisé le corrigé du laboratoire 1. Outil d'IA : Codex (OpenAI, GPT-6), utilisé pour aider à écrire et relire l'assembleur, vérifier la construction et préparer ce journal. Le code et les résultats de la carte doivent être vérifiés et expliqués par les membres de l'équipe avant remise.
