# Journal - CEG3536 Lab 3

Équipe reprise du projet Lab 2 : Eren Arikan (300357356), Antony Zuze (300221295), section A02.
Dépôt d'origine : https://github.com/erudaperu/CEG3536_Lab. Travail Lab 3 conservé localement ; aucune publication distante.

## 10 novembre 2026 - préparation logicielle assistée

- Retrouvé le projet Lab 2 local du 20 octobre dans `Documents/Codex/2026-10-20/g/work/CEG3536_Lab`.
- Intégré les fichiers du complément Lab 3 dans une nouvelle copie. Conservé les sept pilotes assembleur, leurs constantes, le démarrage et le script de liens. Comparaisons enregistrées dans `preuves/preservation_lab2.txt`.
- Complété la file de 32 événements, l'objet d'acquisition opaque, le DMA circulaire, LPUART1, le formateur CSV, la FSM, la routine Q16.16 et le banc C/assembleur.
- Réservé des lignes complètes dans la file TX ; priorisé l'urgence même si evq est pleine ; contrôlé de nouveau le drapeau après les appels de sortie.
- Conservé aussi l’historique Git original via une fusion locale de provenance, sans modifier le dépôt d’origine.
- Créé les baselines `acq-v1` et `acq-v2` pendant la session. La V1 est un checkpoint de comparaison créé maintenant, sans reconstitution fictive d'un ancien historique étudiant.
- Compilé le projet complet à -O0 et -O2 avec GNU Tools for STM32 14.3.1. Importé et construit le projet dans STM32CubeIDE 2.2.0 : zéro erreur et zéro avertissement.
- Exécuté les tests Linux et le banc Cortex-M33 QEMU ; enregistré GDB, les registres, la pile, la variable volatile et les valeurs retournées.
- Produit les captures des vues de journaux, puis le rapport, les annexes et les fiches après les tests.

## Résultats observés

| Vérification | Résultat | Preuve |
|---|---|---|
| FIFO minimale et extensions | 12/12, Linux et QEMU | `tests_linux.log`, `qemu_O0.log`, `qemu_O2.log` |
| Saturation volontaire | 32 acceptés, 8 refusés sur 40 push | cas 10 de l'autotest |
| Enroulements répétés | 10 000 cycles push/pop sans corruption | cas 12 de l'autotest |
| Objet V1 | Deux instances et gains indépendants | `acq_v1.log` |
| Objet V2 | Moyennes 16/64, bornes, hystérésis, curseur et indépendance | `tests_linux.log` |
| FSM | Cycle des états, rampe, arrêt, acquittement, urgence injectée pendant PWM, 10 000 événements | `tests_linux.log` |
| UART / formatage | BRR, rejet de ligne entière, FIFO sans attente, entier signé minimal, enroulement | `tests_linux.log` |
| Vérificateur Python | Refuse cadence, en-tête, CRLF et troncature incorrects ; accepte rollover | `tests_linux.log` |
| Vitesse assembleur | 5/5 cas à -O0 et -O2 | logs QEMU, GDB |
| PWM assembleur/C | 8/8 cas, retours et effets sur registre simulé | logs QEMU, GDB |
| Télémétrie synthétique | 150 trames valides, horodatages espacés de 200 ms | `telemetrie_synthetique.csv` |

Versions : GCC hôte 16.2.1 ; GNU ARM 14.3.1 ; QEMU 10.2.2 ; GDB 15.2.90. Le journal `outils.txt` contient les chaînes complètes. Sur Linux, int = 32 bits et long = 64 bits ; evq_event_t = 12 octets. Les données transportées utilisent uint32_t pour éviter une dépendance à long.

## État des essais matériels et de J2

Aucun STM32/ST-LINK ni port ttyACM/ttyUSB n'était connecté lors de la vérification du matériel. Aucun chargement ni essai moteur n'a été réalisé.

T1, T4, T5 matériel, T6, T8 matériel, T9 port réel et les cycles DWT T10 restent non mesurés. Les portions CPU/logiciel de T2, T3, T7 et T10 sont attestées uniquement dans les environnements indiqués. L'essai Windows de la file reste à exécuter. Le jalon J2 est donc préparé, mais sa validation complète sur les plateformes demandées n'est pas déclarée.

Les relevés des séances des 3 et 10 novembre, la présence à la démonstration, la rotation des rôles et les contributions individuelles ne sont pas connus dans cette session. Aucun rôle ni résultat de séance n'est inventé. Les commits locaux de préparation sont attribués à Codex (OpenAI), sans antidatage.

## Mesures à enregistrer sur la plateforme

- Reset : état, DEL, CCR1, STB, en-tête et délai de démarrage.
- ADC : bas/milieu/haut, CNDTR, compteur de tours pendant une seconde.
- Consigne : montée et descente, deux sens, effet nul à l'arrêt.
- Température : thermomètre, tension de référence, doigts 30 s, comparaison S2 interne/pont externe.
- E-Stop : pendant rampe et émission ; coupure, latence, acquittement et intégrité série.
- Série : 30 s de trames réelles, vérification par le script.
- DWT : commande b à -O0 et -O2, plusieurs répétitions ; conserver captures et cycles.
- Windows et STM32 physique : les 12 résultats de la file.

## Assistance et provenance

Codex (OpenAI, famille GPT-6) a aidé à coder, vérifier, instrumenter et rédiger. Les sorties des outils sont réelles ; les données d'essai artificielles et les registres simulés sont étiquetés. Les captures montrent une mise en page HTML des journaux bruts, pas l'interface d'un débogueur connecté à la carte.

## 10 novembre 2026 - connexion matérielle

ST-LINK/V2.1 0672FF555187534867211326 détecté, NUCLEO-L552ZE-Q et /dev/ttyACM0 présents. CubeProgrammer rapporte 0,00 V puis « Unable to get core ID / No STM32 target found », en HOTPLUG et sous reset. Aucun effacement, chargement ni modification des options. Un aperçu webcam ne montrait pas la plateforme ; il n’est pas conservé dans les livrables. Guide T1-T10 préparé, preuves matérielles toujours ouvertes.
