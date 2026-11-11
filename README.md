# STM32 Motor Control & Telemetry

**C + ARM assembly · STM32L552 / Cortex-M33 · Embedded systems**

An embedded motor controller that connects analog acquisition, encoder feedback, an event-driven state machine and serial telemetry. The project combines C application logic with ARM assembly peripheral drivers, then checks the behavior through Linux tests, a Cortex-M33 test harness and recorded STM32 measurements.

**[Architecture](#architecture) · [Run the tests](#run-the-tests) · [Validation evidence](#validation-evidence) · [French documentation](LISEZMOI.md) · [Demonstration guide](GUIDE_DEMONSTRATION.md)**

## Architecture

![System architecture: analog inputs pass through ADC/DMA acquisition into the main-loop event queue and state machine; digital inputs feed the queue; the state machine calls assembly drivers and exposes state for UART telemetry and host validation. Emergency-stop handling directly cuts motor output and latches a flag consumed by the state machine.](docs/assets/architecture.svg)

## What the system does

- **Controls motion:** forward, reverse and stopped states; PWM ramps; an emergency-stop state with a separate acknowledgement.
- **Acquires sensor data:** two ADC channels with circular DMA, independent acquisition objects, moving averages, a potentiometer dead zone and hysteresis.
- **Processes events:** a bounded 32-entry FIFO with overflow counters. Producers and the consumer run in the main-loop context.
- **Reports its state:** nonblocking UART transmission at 115200 baud, with a configured 200 ms telemetry period and a Python frame validator.
- **Bridges C and assembly:** existing motor, encoder, button, SysTick and buzzer routines remain callable through C interfaces; diagnostics compare C/assembly PWM routines and inspect calling conventions.

### Engineering decisions

The acquisition layer keeps its state behind an opaque C interface with two static instances. Filtering can change without exposing those fields to the state machine. The emergency-stop interrupt cuts motor output directly; a latched flag and a priority path keep handling independent of a full event queue. The telemetry buffer accepts or rejects complete messages so a full buffer does not enqueue a partial frame.

A documented debugging case traces an encoder-direction error to condition flags overwritten before a branch. The correction preserves those flags, followed by regression checks and calibration of encoder polarity. See the [hardware-results record](preuves/materiel/BILAN_PROVISOIRE.md).

## Run the tests

On **Linux**, install a C compiler, GNU Make and Python 3, then run from the repository root:

```bash
bash tests/run_host.sh
```

No board or Python packages are required for this suite. It runs the existing FIFO, acquisition, state-machine, telemetry and parser checks. The telemetry harness maps peripheral addresses into process memory and writes `preuves/telemetrie_synthetique.csv` as an explicitly synthetic fixture.

The [Host tests workflow](.github/workflows/host-tests.yml) runs the same command on Ubuntu for pushes and pull requests to `main`. It checks software behavior; electrical timing and physical motor behavior require the board.

## Build the firmware

Import the repository into **STM32CubeIDE** as an existing project, or use the supplied GNU Arm toolchain through the Linux build script:

```bash
bash build.sh O0
bash build.sh O2
```

The script searches STM32CubeIDE installations under `/opt/st/`. For another installation:

```bash
TOOLCHAIN=/path/to/arm-toolchain/bin/ bash build.sh O0
```

These commands build firmware. Board setup, programming, wiring and serial commands are covered in the [French build guide](LISEZMOI.md#ouvrir-et-construire) and [demonstration guide](GUIDE_DEMONSTRATION.md).

## Validation evidence

| Layer | What it checks | Evidence and boundary |
| --- | --- | --- |
| Linux host | 12 FIFO cases; acquisition boundaries and filtering; state transitions and injected emergency-stop conditions; 10,000-event sequence; telemetry formatting and parser rejection cases | [Test runner](tests/run_host.sh). Peripherals are mocked or mapped into process memory. |
| Cortex-M33 / QEMU | Assembly arithmetic, calling behavior and PWM comparisons | [Target harness](tests/run_target.sh). MPS2 AN505 does not emulate STM32L552 peripherals; the harness redirects selected addresses. |
| STM32 hardware | Recorded firmware/readback checks, encoder calibration, motor directions, PWM comparisons, ADC/DMA and serial captures | [Recorded results](preuves/materiel/BILAN_PROVISOIRE.md), [platform photograph](preuves/materiel/photo_plateforme.jpg) and [motor traces](preuves/materiel/courbes_moteur_final.png), dated November 10, 2026. |

The final recorded serial run contains **150 frames over 30 seconds at 5.00 Hz**; see the [test summary and its limits](LISEZMOI.md#résultat-et-portée). These are recorded board results, separate from the synthetic host fixture.

**Open measurement work:** electrical emergency-stop latency below 1 ms has not been measured, absolute temperature accuracy and the internal/external temperature comparison remain unvalidated, and the Windows host procedure has not been executed. The existing documentation retains these limits.

## Repository guide

| Path | Purpose |
| --- | --- |
| [`Core/`](Core/) | C application modules, ARM assembly drivers and interfaces |
| [`tests/`](tests/) | Host tests, QEMU harness and board-debug scripts |
| [`hote/`](hote/) | Portable queue test entry point and Python serial validator |
| [`preuves/`](preuves/) | Recorded logs, captures and explicitly labelled synthetic evidence |
| [`Lab1/`](Lab1/) · [`Lab2/`](Lab2/) | Earlier project stages and reports |
| [`Drivers/CMSIS/`](Drivers/CMSIS/) | Supplied CMSIS/ST support; existing vendor notices apply |

## Team and provenance

University of Ottawa **CEG 3536**, Arikan / Zuze team. Course-provided scaffolding, inherited drivers, tool assistance and session provenance are documented in [Sources et assistance](LISEZMOI.md#sources-et-assistance) and [Preuves et versions](LISEZMOI.md#preuves-et-versions). The French reports and original notices remain the detailed reference.
