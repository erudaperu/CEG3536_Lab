# CEG3536 - Laboratoire 3 - Arikan / Zuze

Projet C + assembleur intégré au projet Lab 2 local, préparé le 10 novembre 2026.

## Résultat et portée

- Projet STM32CubeIDE importé et construit : **0 erreur, 0 avertissement**.
- Firmware GNU ARM complet fourni à `build/O0/CEG3536_Lab3.elf` et `build/O2/CEG3536_Lab3.elf`, avec les BIN correspondants.
- File : 12/12 cas sous Linux et QEMU Cortex-M33.
- Vitesse assembleur : 5/5 cas sous QEMU, aux deux optimisations.
- PWM assembleur/C : 8/8 cas aux deux optimisations avec le registre TIM1 simulé en RAM.
- Acquisition, commande, interruption injectée, saturation et formateur : tests Linux réussis.
- Rapport de 10 pages, 7 pages d'annexes et 2 fiches périphériques dans `rapport/`.

**Aucune carte STM32/ST-LINK n'était connectée.** Les mesures ADC/DMA, température, moteur, UART réel, latence E-Stop et cycles DWT restent à réaliser sur la plateforme. Les essais Windows et la démonstration ne sont pas attestés. Le fichier `telemetrie_synthetique.csv` contient des données de test, pas un relevé série.

## Ouvrir et construire

Dans STM32CubeIDE : **File > Import > Existing Projects into Workspace**, sélectionner ce dossier, puis construire `CEG3536_Lab3_Arikan_Zuze` en Debug. Les répertoires CMSIS, `STM32L552xx`, GNU11 et `-Wextra` sont configurés. Seul `Core/` est compilé par l'IDE ; les tests et exemples sont exclus.

Sous Linux avec STM32CubeIDE installé :

```sh
bash build.sh O0
bash build.sh O2
```

Le script recherche la chaîne GNU de STM32CubeIDE sous `/opt/st/`. Pour une autre installation, passer le préfixe de répertoire, terminé par `/` :

```sh
TOOLCHAIN=/chemin/vers/tools/bin/ bash build.sh O0
```

Ces commandes construisent les fichiers ; elles ne programment pas la carte. L'outil système `/usr/bin/arm-none-eabi-gcc` de l'ordinateur utilisé manquait de sa bibliothèque C ; la chaîne complète fournie avec STM32CubeIDE a été utilisée.

## Reproduire les essais

```sh
bash tests/run_host.sh
ARM_GCC=/chemin/vers/arm-none-eabi-gcc QEMU=qemu-system-arm OPT=-O0 bash tests/run_target.sh
ARM_GCC=/chemin/vers/arm-none-eabi-gcc QEMU=qemu-system-arm OPT=-O2 bash tests/run_target.sh
arm-none-eabi-gdb -q -batch -x tests/qemu/debugger.gdb preuves/qemu_test-O0.elf
```

`run_host.sh` est un banc Linux : il utilise un mappage mémoire de test pour les registres UART. Le module portable à vérifier sous Windows est `hote/test_evq.c` avec `Core/Src/evq.c` et `Core/Src/evq_test.c` ; exécuter `make` dans `hote/` avec MinGW/MSYS2. Le source de la file est identique sur les hôtes et sur la cible.

Le banc QEMU utilise la machine **MPS2 AN505 Cortex-M33**, qui ne reproduit pas les périphériques STM32L552. Il redirige uniquement l'adresse TIM1 vers de la RAM pour comparer les deux routines PWM. Le fichier assembleur de production n'est pas modifié. `enc_count` est le symbole du pilote conservé, avec une valeur injectée par le banc. Les temps QEMU ne sont pas des mesures DWT sur STM32.

## Commandes série sur carte

Terminal : 115200 bauds, 8N1, sans contrôle de flux.

| Commande | Fonction |
|---|---|
| `a` | Brut/mV des voies, tours DMA, pertes de transmission |
| `t` | 40 événements de test ; file de 32 : huit refus si elle est vide au départ |
| `q` | Autotest de la file, en ARRÊT ; remet les compteurs de la file à zéro |
| `b` | Comparaison PWM ASM/C et cycles DWT ASM/C/fsm_etat, en ARRÊT |
| `z` | Remise à zéro des compteurs de la file, en ARRÊT |

`q` et `b` sont des diagnostics : leurs durées peuvent perturber la cadence pendant leur exécution. Pour le relevé nominal de 30 s, les exécuter avant la capture. `B,ecarts=4294967295` indique un banc refusé ou interrompu par l'urgence, pas un nombre normal d'écarts.

```sh
python3 hote/telemetrie.py /dev/ttyACM0 --duree 30 --sauver preuves/serie_reelle.csv
```

Ouvrir le port puis redémarrer la carte pendant la capture afin de recevoir la ligne H. Sur Windows, remplacer le périphérique par le port COM réel. Ne pas remplacer le relevé réel par le fichier synthétique fourni.

## Étalonnage et vérifications restantes

Les constantes `TEMP_MV_REF=1831` et `TEMP_C10_REF=250` sont des valeurs de départ du complément. Les remplacer par le relevé de la commande `a` et celui d'un thermomètre. Le rapport contient la procédure T1-T10 et les calculs attendus ; les résultats matériels y sont explicitement non mesurés.

Le tampon physique comporte 64 paires. Le potentiomètre utilise les 16 dernières, la température les 64 dernières. `acq_t` est opaque et possède deux instances statiques. Aucun champ n'est accessible depuis main/fsm.

## Preuves et versions

- `preuves/index.html` : index des vues de preuves ; `preuves/captures/` : 7 captures PNG et leur HTML.
- `preuves/*.log` : sorties brutes ; `*_O0.txt` / `*_O2.txt` : désassemblages.
- `preuves/preservation_lab2.txt` : comparaison des pilotes assembleur avec le Lab 2 retrouvé.
- `versions/v1/` : acquisition initiale et son essai ; `versions/imperative/` : comparaison à variables globales.
- Tags Git locaux `acq-v1` / `acq-v2` ; le bundle `historique_lab3.bundle` permet de consulter l'historique : `git clone historique_lab3.bundle lab3_historique`.

Les checkpoints ont été créés durant cette session avec l'auteur **Codex (OpenAI)**. Ils ne représentent pas des contributions humaines ou des séances antérieures. Le dépôt distant de l'équipe n'a pas été modifié.

## Sources et assistance

Énoncé Lab 3 v1.3 et complément fournis ; projet Lab 2 retrouvé dans `Documents/Codex/2026-10-20/g/work/CEG3536_Lab` ; en-têtes CMSIS/ST fournis. Les fichiers assembleur bas niveau et leurs constantes ont été conservés octet pour octet. Les documents antérieurs joints dans `references/` restent dans leur état d'origine.

Assistance Codex/OpenAI (famille GPT-6) pour l'implémentation, les essais, les traces et la rédaction. Le rapport décrit l'usage et les limites. Chaque membre doit comprendre et pouvoir modifier les modules avant la démonstration.
