# MSP430 Game Boy — Bill of Materials (Structured)
_Last updated: 2026-03-18_

**Display updated:** SSD1306 0.96" → SSD1309 2.42" (Adafruit #2719)
**Headers updated:** Samtec TSW-140-07-G-S long-pin breakaway
**Total estimated cost:** ~$70–80 shipped

---

## Phase 1 — Lessons 1–5 (LaunchPad only)

| Part | Description | Source | Part # | Qty | ~Unit Cost |
|------|-------------|--------|--------|-----|-----------|
| MSP-EXP430G2 | LaunchPad with MSP430G2553 MCU | TI / Mouser | MSP-EXP430G2 | 1 | $10.00 |

> Nothing else required for Phase 1. The LaunchPad has LED1 (P1.0), LED2 (P1.6), and button S2 (P1.3) onboard.

---

## Phase 2 — Lessons 6–10 (Add OLED Display)

| Part | Description | Source | Part # | Qty | ~Unit Cost |
|------|-------------|--------|--------|-----|-----------|
| SSD1309 2.42" OLED | 128×64, SPI, 3.3V | Adafruit | #2719 | 1 | $18.00 |
| Samtec TSW-140-07-G-S | Long-pin breakaway header, 40-pos | DigiKey / Samtec | SAM1029-40-ND | 2 | $3.50 |
| Elenco 9440 (or equiv) | Full-size 830-tie breadboard | Amazon / DigiKey | — | 1 | $10.00 |
| Jumper wires M-M | 20cm, assorted colours, pack | Amazon | — | 1 pk | $4.00 |

> **SPI wiring (SSD1309):** SCLK→P1.5, MOSI→P1.7, CS→P2.0, DC→P2.1, RST→P2.2, VCC→3.3V, GND→GND.
> **Charge pump note:** SSD1309 uses an external charge pump — do NOT send `CMD_CHARGE_PUMP, 0x14` in the init sequence (that's SSD1306-only). The SSD1309 init enables the display directly.

---

## Phase 3 — Lessons 11–13 (Add 8-Button Input)

| Part | Description | Source | Part # | Qty | ~Unit Cost |
|------|-------------|--------|--------|-----|-----------|
| SN74HC165N | 8-bit parallel-in serial-out shift register, DIP-16 | DigiKey / Mouser | SN74HC165N | 1 | $0.80 |
| Omron B3F-1000 | 6mm momentary tactile button, 4-pin | DigiKey | B3F-1000-CT-ND | 8 | $0.20 |
| 10kΩ 1/4W resistor | Button pull-ups (one per button) | Any | — | 10 | $0.05 |
| 0.1µF ceramic cap | Bypass cap for SN74HC165N VCC | Any | — | 1 | $0.10 |

> **Button wiring:** 3.3V → 10kΩ → SR pin (A–H) → button → GND. Pressed = LOW. SR reads 0=pressed, 1=released. Invert in firmware with `xor.b #0xFF`.
> **SH/LD** (pin 1) → P2.3. **CLK** (pin 2) → P1.5 (shared SPI). **QH** (pin 9) → P1.6 (MISO). **CLK INH** (pin 10) → GND.

---

## Phase 4 — Lessons 14–16 (Add Audio)

| Part | Description | Source | Part # | Qty | ~Unit Cost |
|------|-------------|--------|--------|-----|-----------|
| LM386N-1 | Audio power amplifier, DIP-8 | DigiKey / Amazon | LM386N-1/NOPB | 1 | $1.00 |
| SP-3605 | 8Ω 0.5W speaker | DigiKey | 102-SP-3605-ND | 1 | $2.00 |
| 250µF 10V electrolytic | Output coupling cap (LM386 pin 5 → speaker) | Any | — | 1 | $0.50 |
| 10µF 10V electrolytic | Input coupling cap (PWM → LM386 pin 3) | Any | — | 1 | $0.25 |
| 10µF 10V electrolytic | VCC bypass cap (LM386 pin 7 → GND) | Any | — | 1 | $0.25 |
| 1kΩ 1/4W resistor | RC filter in series with P1.2 PWM output | Any | — | 1 | $0.05 |
| 10Ω 1/4W resistor | Series resistor on speaker output | Any | — | 1 | $0.05 |

> **PWM pin:** P1.2 → 1kΩ → 10µF cap → LM386 pin 3. LM386 pin 5 → 250µF cap → 10Ω → speaker+. Speaker− → GND.
> **Gain:** Pins 1 and 8 unconnected = 20× gain (default). Connect 1.2kΩ + 10µF between pins 1–8 for 200× if needed.
> **Tone formula at 1 MHz SMCLK:** CCR0 = 1,000,000 / frequency − 1. A4 (440 Hz) → CCR0 = 2271.

---

## Phase 5 — Final Assembly (Add Power)

| Part | Description | Source | Part # | Qty | ~Unit Cost |
|------|-------------|--------|--------|-----|-----------|
| Adafruit 4410 | USB-C LiPo charger, 3.3V/5V output | Adafruit | #4410 | 1 | $7.50 |
| Adafruit 2011 | 3.7V 2Ah LiPo battery, JST-PH connector | Adafruit | #2011 | 1 | $12.50 |

> **Power routing:** Charger VCC out → breadboard VCC rail. LaunchPad powered from same rail. Remove USB cable from LaunchPad once battery is connected to avoid backfeeding.

---

## Optional / Spare Parts

| Part | Description | Notes |
|------|-------------|-------|
| 0.047µF + 1.2kΩ | Zobel network (LM386 output stability) | Not needed in most cases; add if speaker oscillates |
| 10kΩ log pot | Volume control (wiper → LM386 pin 3) | Nice to have for adjustable audio level |
| Extra B3F-1000 ×4 | Spare buttons | Tactile buttons wear out; order a few extra |
