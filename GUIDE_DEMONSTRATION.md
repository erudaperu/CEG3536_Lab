# Démonstration Lab 3 - déroulement pratique

Énoncé v1.3, sections 6 et 8. Durée : 15 minutes d'essais, puis 5 minutes de questions individuelles. Les deux membres restent présents. Les valeurs ci-dessous sont des critères attendus, pas des mesures déjà obtenues.

## Avant le passage

1. Poser la plateforme à plat, dégager l'arbre et garder l'interrupteur général accessible. Speed à 0 %. Vérifier E-Stop à faible vitesse avant tout essai à 100 %. Ne modifier aucun branchement sous tension.
2. Alimenter la cible selon le montage du laboratoire. Le 10 novembre, le ST-LINK USB est reconnu, mais CubeProgrammer indique 0.00 V et « No STM32 target found », y compris sous reset. Vérifier l'alimentation et les cavaliers avec l'assistant selon le guide de la plateforme ; ne pas changer les options de protection ni effacer la carte pour résoudre ce symptôme.
3. Dès que le processeur est accessible, sauvegarder la flash existante, charger et vérifier le firmware -O0. Confirmer que ticks_ms avance et qu'aucune faute processeur n'apparaît avant les essais moteur.
4. Ouvrir STM32CubeIDE avec le projet, préparer Debug et le terminal /dev/ttyACM0 : 115200 bauds, 8N1, aucun contrôle de flux. Un seul programme ouvre le port à la fois. Préparer aussi les exécutables -O0/-O2, les résultats Linux/Windows et le thermomètre.
5. Préparer les fenêtres Watch : etat, consigne_pct, pwm_pct, estop_flag, ticks_ms, enc_count, tampon_adc, bench_ret_asm, bench_ret_c, bench_ccr_asm, bench_ccr_c, bench_cycles_asm, bench_cycles_c, bench_cycles_fsm. Un point d'arrêt immobilise le processeur : l'utiliser avec moteur désactivé.

## T1 à T3 : initialisation et interface (3 minutes)

T1. Ouvrir le terminal, puis Reset. Montrer ARRÊT, rouge seule, moteur immobile, ligne H et premières lignes T. Mesurer le délai depuis le reset avec un enregistrement horodaté : première trame au plus tard à 300 ms. Photographier la plateforme et capturer ADC1, DMA1, LPUART1. Une simple ligne H ne prouve pas le délai.

T2. Moteur arrêté, mettre un point d'arrêt à l'entrée de motor_set_pwm, puis enc_fronts_vers_rpm_q16. Montrer R0 (argument), SP, LR et la pile ; vérifier SP & 7 = 0 à l'interface. Faire Step Return et montrer R0 (retour). Lire enc_count directement en mémoire. Garder les captures avant/après. Retirer les points d'arrêt avant les mesures de cadence.

T3. Exécuter les cinq cas de vitesse sur cible avec le débogueur, moteur arrêté. Arguments : 0, 1, 748, 1870, 65535. Retours Q16.16 attendus : 0, 21028, 15728944, 39322360, 1378069980. Diviser par 65536 pour obtenir tr/min et comparer à fronts × 240 / 748, tolérance 0,05 %. Préciser que ces entrées de test sont injectées, distinctes de fronts réellement mesurés.

## T4 à T6 : acquisition et commande (5 minutes)

T4. En ARRÊT, placer Speed en bas, au milieu, en haut ; envoyer a et conserver pot_brut/pot_mv. Attendu : environ 0, 2048, 4095 à ±2 %. Observer le tampon entrelacé IN1/IN2. Mesurer les transferts sur une seconde sans point d'arrêt : environ 3062,8 échantillons/s par voie, tolérance ±10 %. Un tour contient 64 paires (environ 47,86 tours/s). Le compteur de tours seul a une incertitude aux bornes ; noter la durée exacte et, si possible, CNDTR aux deux bornes.

T5. Remettre Speed à 0. Appuyer User : marche avant. Monter progressivement la consigne, observer la rampe de PWM (1 point/10 ms), le moteur et la vitesse. User : arrêt. Speed à 0, User : marche arrière, puis répéter. User : arrêt ; déplacer Speed et montrer PWM et CCR1 à zéro. Observer la stabilité de la consigne près d'une position fixe (hystérésis >2 points et zones mortes aux extrémités). Conserver le journal série ; ne pas prétendre qu'une photo prouve la rotation ou la rampe.

T6. S2 en Int : relever le thermomètre et la tension temp_mv avec a. Mettre TEMP_MV_REF à la tension mesurée et TEMP_C10_REF à dix fois la température de référence, reconstruire et vérifier l'écart ≤2 °C. Tenir le capteur entre deux doigts 30 s, constater une hausse de plusieurs degrés. Couper l'alimentation, câbler le pont J5 OUT-IN, mettre S2 en Ext, réalimenter et comparer après stabilisation : différence ≤1 °C. Photographier les deux configurations et le thermomètre. La préparation de l'étalonnage doit être faite avant le passage.

## T7 à T10 : robustesse, trames et outils (7 minutes)

T7. Montrer les sorties test_evq sur Linux et Windows, puis envoyer q en ARRÊT : Q,echecs=0 attendu. Envoyer z, puis t : 40 insertions dans une file de 32, donc huit refus attendus si elle est vide. Montrer le compteur evq_debordements dans les trames et la poursuite du programme. Les tests Linux/QEMU existants ne prouvent pas Windows ou la cible STM32.

T8. Après une première vérification à faible vitesse, tester E-Stop à 100 % pendant l'émission. Montrer l'arrêt immédiat, CCR1=0, STB=0, estop_flag et les trames intactes. Relâcher E-Stop : aucune reprise. Touch En acquitte vers ARRÊT ; User seul permet ensuite un nouveau départ. Pour prouver <1 ms, utiliser une mesure temporelle de l'entrée E-Stop et de PWM/STB, ou une preuve Lab 2 valide du gestionnaire inchangé. Une capture Watch ou la télémétrie à 5 Hz ne prouve pas cette latence.

T9. Fermer le terminal et lancer la capture ci-dessous, puis appuyer Reset rapidement pour recevoir H. Ne pas envoyer q/b et ne pas arrêter le débogueur pendant la capture. Conserver le CSV et la sortie du validateur. Attendu : 135 à 165 trames sur 30 s, environ 5 Hz, neuf champs, CRLF et aucune trame tronquée. Vérifier séparément le nombre de trames : le script n'impose pas à lui seul la plage 135..165.

    python3 hote/telemetrie.py /dev/ttyACM0 --duree 30 --sauver preuves/materiel/serie_reelle.csv
    python3 hote/telemetrie.py preuves/materiel/serie_reelle.csv

T10. En ARRÊT et sans point d'arrêt, envoyer b pour -O0 puis pour -O2 après chargement/vérification de chaque image. Attendu : B,ecarts=0 ; conserver cycles_asm, cycles_c et cycles_fsm. Montrer les huit cas et CCR1 identiques, les tailles et le désassemblage annoté. 4294967295 signifie banc refusé/interrompu, pas un résultat valide. Des cycles nuls ne constituent pas une mesure valide : vérifier DWT. Recharger la version choisie et remettre ARRÊT à la fin.

## Preuves à conserver

- Captures réelles du terminal : démarrage, q, saturation t, deux bancs b, validation des 30 s.
- Captures du débogueur : paramètres/retours, SP/LR et pile, volatile en mémoire, ADC/DMA/UART, état d'urgence.
- Relevés : ADC aux trois positions, débit DMA, étalonnage thermique, comparaison Int/Ext, cycles -O0/-O2, latence E-Stop.
- Photos de contexte utiles (complément aux preuves exigées) : montage complet, Speed à trois positions, S2 Int puis pont J5 Ext hors tension, capteur et thermomètre. Une caméra doit voir le montage ; ne pas remplacer ces photos par des images générées.
- Chaque preuve porte le test, l'optimisation, la procédure, le résultat observé et le verdict. Conserver les logs bruts ; annoncer les échecs et les essais non exécutés.

## Questions à répéter à deux (5 minutes)

Expliquer chacun une routine assembleur et un module C : R0-R3/R0, registres préservés et pile AAPCS ; volatile ≠ atomicité ; ADC/DMA circulaire et ordre des voies ; PWR IOSV et BRR=8889 ; Q16.16 et coefficient 21028 ; file pleine et urgence prioritaire ; acq_t opaque et deux instances ; différences -O0/-O2. Savoir changer TELEM_PERIODE_MS ou ajouter un cas test_evq, reconstruire et expliquer l'effet. L'IA n'est pas utilisée pendant la démonstration.
