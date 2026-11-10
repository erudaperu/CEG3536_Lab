# Résultats matériels - session du 10 novembre 2026

- Connexion ST-LINK rétablie : 3,24 V, STM32L5 0x472 ; sauvegarde complète flash 512 Kio avant programmation.
- Firmware -O0 chargé et vérifié ; -O2 relu octet par octet, SHA256 identique. Le contrôle compare-sections GDB avait donné une alerte, résolue par la relecture binaire indépendante.
- AAPCS sur cible : appels C vers vitesse et PWM, SP aligné à 8 octets, R0 et LR capturés. Cas vitesse injectés 0/1/748/1870/65535 : tous exacts.
- Queue sur STM32 : Q,echecs=0. Saturation : huit refus, émission maintenue.
- PWM ASM/C : huit cas sans écart aux deux optimisations. Mesures DWT initiales : O0 32/50/44 cycles (ASM/C/fsm), O2 23/19/22. Mesures ponctuelles, interruptions actives, contexte de compilation différent.
- ADC : minimum 0, milieu 2053 (1654 mV), maximum 4093 (3298 mV). PWM reste 0 en ARRÊT. DMA : 96 tours de 64 paires en environ 2 s, soit 3072 échantillons/s/voie (+0,30 % du calcul). Ce relevé sur 2 s complète, sans prétendre être un comptage exact sur 1 s, le test demandé.
- UART nominal O0 : H + 149 trames en environ 30 s, intervalle ticks 201 ms, 4,98 Hz, format valide. Première trame datée ticks_ms=203. Horodatage USB conservé ; ne pas confondre avec une mesure électrique depuis le reset.
- Défaut découvert dans encoder_read hérité : MOVS détruisait NZ avant BEQ/BPL. Remplacement par MOV.W, avec conservation des interfaces. Régression sur vrai STM32 et QEMU : delta 0 -> sens 0 ; +748 -> sens 1 ; -748 -> magnitude748/sens2. Les traces de rotation avant correction ne valident pas le champ sens.
- Après correction, mouvement réel mesuré en état avant : environ 107 rpm à 30 % ; sens mesuré opposé à la commande, polarité à vérifier. L'utilisateur confirme une rotation et un arrêt.
- E-Stop : capture automatique après ISR avec PB2=1, estop_flag=1, CCR1=0 et STB=0, puis état3. Aucun délai inférieur à1ms mesuré. Les captures tardives après confirmation utilisateur montraient déjà ARRÊT ; elles ne sont pas présentées comme une urgence maintenue.
- Relâchement/acquittement : retour ARRÊT observé, mais pas encore distingué d'un appui Touch En. Vérification à poursuivre.
- Température ambiante indicative ~25°C ; thermomètre, chauffage30s et pont externe non encore vérifiés. Photos de plateforme non encore disponibles.
- Les fichiers initiaux contenant données série antérieures, pauses GDB ou fragments sont conservés ; seule serie_reelle_30s.csv est le relevé nominal validé T9.

Mise à jour : essai E-Stop isolé réussi. Aucun EV_TOUCH au relâchement, état3 conservé. Appui Touch En distinct : GDB capture EV_TOUCH, PB2=0/PB5=1, état3/flag1 avant, état0/flag0 après. Les essais antérieurs avaient des activités supplémentaires ; ne pas les utiliser pour conclure à un acquittement spontané.

Mise à jour finale moteur : ENC_SENS_INVERSE=1 calibré et revalidé. Avant21 % ~73rpm, état1/sens1 ; arrière36 % ~129rpm, état2/sens2. Les deux sens atteignent100 % dans le relevé. E-Stop depuis100 % (~374rpm), 26 trames entourant la coupure valides à5Hz. La mesure <1ms est laissée non réalisée à la demande explicite de l’utilisateur (pas de mesure oscilloscope).

Température : chauffage déclaré30s, courbe25,3→29,4°C. Pas de thermomètre connu de l’opérateur : calibration absolue non validée. Premier essai Ext : l’opérateur confirme avoir seulement déplacé S2, sans fil OUT-IN ; lectures~87-89°C donc entrée flottante, pas un essai de pont valide. Retour Int :~26°C/1820mV. Un vrai pont est demandé pour répéter.
