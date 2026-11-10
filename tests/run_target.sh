#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${ARM_GCC:=arm-none-eabi-gcc}"
: "${QEMU:=qemu-system-arm}"
mkdir -p preuves
# Seul le symbole d'adresse TIM1_BASE est redirige pour le banc CPU.
# Les sources de production et les instructions de motor_set_pwm restent intacts.
"$ARM_GCC" -E -P -x assembler-with-cpp Core/Src/motor.s > preuves/motor_qemu_preprocessed.s
sed -i 's/\.equ TIM1_BASE, *0x40012C00/.equ TIM1_BASE, 0x30001000/' preuves/motor_qemu_preprocessed.s
"$ARM_GCC" -mcpu=cortex-m33 -mthumb -std=gnu11 -Wall -Wextra -Werror "${OPT:--O0}" -g3 -ffreestanding -nostdlib -DSTM32L552xx -ICore/Inc -IDrivers/CMSIS/Include -IDrivers/CMSIS/Device/ST/STM32L5xx/Include tests/qemu/test_target.c tests/qemu/l3a_mock.c -x assembler-with-cpp tests/qemu/startup.s Core/Src/vitesse.s preuves/motor_qemu_preprocessed.s -x c Core/Src/evq.c Core/Src/evq_test.c -T tests/qemu/test.ld -Wl,-z,noexecstack -o "preuves/qemu_test${OPT:--O0}.elf"
"$QEMU" -M mps2-an505 -display none -monitor none -serial none -semihosting -kernel "preuves/qemu_test${OPT:--O0}.elf"
