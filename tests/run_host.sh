#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p preuves
make -C hote
cc -std=gnu11 -Wall -Wextra -Werror -O0 -g -ICore/Inc tests/test_modules.c Core/Src/acq.c Core/Src/fsm.c -o tests/test_modules
./tests/test_modules
cc -std=gnu11 -Wall -Wextra -Werror -Wno-int-to-pointer-cast -DSTM32L552xx -O0 -g -ICore/Inc -IDrivers/CMSIS/Include -IDrivers/CMSIS/Device/ST/STM32L5xx/Include tests/test_telem.c -o tests/test_telem
./tests/test_telem
python3 tests/test_validator.py
python3 hote/telemetrie.py preuves/telemetrie_synthetique.csv
