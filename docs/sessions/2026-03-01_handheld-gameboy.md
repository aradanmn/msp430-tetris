# Session: Handheld MSP430 Game Boy — Schematic Design
**Date:** 2026-03-01 / 2026-03-02
**Project:** `handheld-msp430/`

---

## Project Overview

Building a DIY handheld game console around the MSP430G2553 (20-pin DIP on LaunchPad). BOM ~$53 from DigiKey.

**Components:**
| Part | Role |
|------|------|
| MSP430G2553 LaunchPad | MCU |
| SN74HC165N | 8-button shift register (SPI) |
| LM386N-1 | Audio amplifier |
| 0.96" OLED SPI 128×64 | Display |
| Adafruit 4410 | USB-C LiPo charger |
| 3.7V 2Ah LiPo | Battery |
| 8× tactile buttons + 10kΩ pull-ups | Input |

---

## Session 1 — Breadboard Layout

Created `breadboard_layout.html` (SVG visual for Elenco 9440, 4-panel breadboard with power rails at top) and `breadboard_guide.md` (wiring reference table). MSP430 centred, peripherals arranged around outside.

---

## Session 2 — KiCad Schematic (initial)

User upgraded to KiCad 9.0.7. Researched KiCad 9 format changes (sch_file_versions.h): version `20250114`, bare `(hide)` boolean, `exclude_from_sim` and `dnp` required. Wrote `gen_kicad6.py` targeting KiCad 9. All 12 format compliance checks pass. Schematic opens in KiCad but component placement and labels were overlapping / not connected.

**Root cause:** All component positions (175, 125, etc.) were NOT multiples of 2.54 mm (KiCad's 100-mil grid). Off-grid positions → wire stubs can't snap to pin endpoints → dangling wires + ERC errors.

---

## Session 3 — Grid Fix + Final Schematic

**Fix applied in `gen_kicad7.py` (rev 4.0):** All positions as integer multiples of `G = 2.54`.

```python
G = 2.54
U1 = (69*G, 49*G)   # MSP430G2553
U2 = (24*G, 49*G)   # SN74HC165N
U3 = (110*G, 49*G)  # LM386N-1
```

**Validation results:**
- Grid check: all positions confirmed on-grid
- All 12 KiCad 9 format checks pass
- kiutils: libSymbols=11, symbols=63, labels=45, noConnects=17
- Paren balance: 0

**Key signal routing:**

| Net | MSP430 Pin | Destination |
|-----|-----------|-------------|
| SCK | P1.5 | U2 CLK + J1 OLED CLK |
| MISO | P1.6 | U2 QH |
| MOSI | P1.7 | J1 OLED MOSI |
| SH_LD | P2.4 | U2 SH/LD# (active LOW) |
| PWM_OUT | P1.2 | R1→C1→U3 IN− |
| ADC_POT | P1.3 | RV2 wiper |
| SPK_OUT | U3 OUT | LS1 (+) |

**Known conflict:** P1.7 dual-use (OLED MOSI + shift reg SOMI). Resolution: use software I2C for OLED if needed.

**Deliverables:**
- `schematic/msp430_gameboy.kicad_sch` — KiCad 9 schematic, all positions grid-aligned
- `breadboard/breadboard_layout.html` — SVG wiring diagram
- `breadboard/breadboard_guide.md` — wiring reference
- `scripts/gen_kicad7.py` — canonical generator (rev 4.0)
- `scripts/gen_kicad6.py` — prior version (reference)

---

## Status at End of Session

- [x] BOM (~$53 DigiKey)
- [x] Breadboard layout
- [x] KiCad 9 schematic rev 4.0 — grid-aligned, paren-balanced
- [ ] Open in KiCad and run ERC (should show 0 errors; text overlap may need visual check)
- [ ] PCB layout
- [ ] Firmware (MSP430 assembly, referencing the course patterns)
