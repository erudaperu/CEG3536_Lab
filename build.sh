#!/usr/bin/env bash
# Construction locale, pas de programmation automatique de la carte.
set -euo pipefail
cd "$(dirname "$0")"
mode="${1:-O0}"
if [[ -z "${TOOLCHAIN:-}" ]]; then
  for candidate in /opt/st/stm32cubeide_*/plugins/*gnu-tools-for-stm32*/tools/bin/arm-none-eabi-gcc; do
    if [[ -x "$candidate" ]]; then TOOLCHAIN="${candidate%arm-none-eabi-gcc}"; break; fi
  done
fi
TOOLCHAIN="${TOOLCHAIN:-}"
case "$mode" in
  O0|O2) make -j4 "TOOLCHAIN=$TOOLCHAIN" "BUILD=build/$mode" "OPT=-$mode" ;;
  *) printf 'Usage: bash build.sh [O0|O2]\n' >&2; exit 2 ;;
esac
