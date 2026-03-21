# MSP430 Handheld Gaming Console — Flat BOM (Single-Level)
_Revision: C — 2026-03-21_

A flat (single-level) BOM lists every component needed to build the complete assembly in one table at equal hierarchy depth. Quantities are **aggregate totals** across all uses. No parent-child relationships are expressed here — see `bom-structured.md` for the product breakdown hierarchy.

---

| Item # | Manufacturer | MPN | Description | Pkg | Qty | UOM | Unit Price (USD) | Ext Price (USD) | Preferred Vendor | Vendor Part # | Lifecycle | Notes |
|--------|-------------|-----|-------------|-----|-----|-----|-----------------|-----------------|-----------------|---------------|-----------|-------|
| 001 | Texas Instruments | MSP-EXP430G2ET | MSP430G2553 LaunchPad dev board | — | 1 | EA | $10.00 | $10.00 | Mouser | 595-MSP-EXP430G2ET | Active | Includes eZ-FET lite debugger, LED1/LED2, button S2 |
| 002 | Adafruit | #2674 | 2.7" 128×64 SSD1325 grayscale OLED SPI 3.3V | — | 1 | EA | $49.95 | $49.95 | Adafruit | 2674 | Active | adafruit.com only |
| 003 | Microchip | 23LC1024-I/P | 128KB SPI SRAM | DIP-8 | 1 | EA | $2.50 | $2.50 | DigiKey | 23LC1024-I/P-ND | Active | External framebuffer + game-state RAM |
| 004 | Winbond | W25Q32JVDIQ | 4MB SPI NOR Flash | DIP-8 | 1 | EA | $0.75 | $0.75 | DigiKey | search MPN | Active | Sprite/audio/save-data asset store. DIP-8 breadboard-compatible. Verify stock before ordering — limited US distributor availability. Note: final PCB may require a different package. |
| 005 | Texas Instruments | SN74HC165N | 8-bit parallel-in serial-out shift register | DIP-16 | 1 | EA | $0.80 | $0.80 | DigiKey | 296-8251-5-ND | Active | Button input latch |
| 006 | Omron | B3F-1000 | 6mm momentary tactile button, 4-pin, 160gf | Through-hole | 12 | EA | $0.20 | $2.40 | DigiKey | B3F-1000-ND | Active | 8 used, 4 spares. Tactile switches wear — order extra. |
| 007 | Texas Instruments | LM386N-1/NOPB | Low-voltage audio power amplifier | DIP-8 | 1 | EA | $1.00 | $1.00 | DigiKey | LM386N-1/NOPB-ND | Active | 20× gain default; 200× with external network |
| 008 | CUI Devices | CSS-04008 | Speaker, 8Ω, 0.5W, 40mm | — | 1 | EA | $2.00 | $2.00 | DigiKey | 102-SP-3605-ND | Active | 8Ω load for LM386 |
| 009 | Samtec | TSW-140-07-G-S | Long-pin breakaway header, 40-pos, 2.54mm | Through-hole | 2 | EA | $3.50 | $7.00 | DigiKey | SAM1029-40-ND | Active | LaunchPad stacking headers |
| 010 | Adafruit | #4410 | USB-C LiPo charger, 3.3V/5V output | — | 1 | EA | $7.50 | $7.50 | Adafruit | 4410 | Active | adafruit.com only |
| 011 | Adafruit | #2011 | 3.7V 2000mAh LiPo battery, JST-PH | — | 1 | EA | $12.50 | $12.50 | Adafruit | 2011 | Active | adafruit.com only |
| 012 | Yageo | CFR-25JB-52-10K | Resistor, 10kΩ, 1/4W, 5%, carbon film | Axial | 12 | EA | $0.05 | $0.60 | DigiKey | 10KEBK-ND | Active | Button pull-ups (8 used) + spares |
| 013 | Yageo | CFR-25JB-52-1K0 | Resistor, 1kΩ, 1/4W, 5%, carbon film | Axial | 2 | EA | $0.05 | $0.10 | DigiKey | 1.0KEBK-ND | Active | PWM RC filter |
| 014 | Yageo | CFR-25JB-52-10R | Resistor, 10Ω, 1/4W, 5%, carbon film | Axial | 2 | EA | $0.05 | $0.10 | DigiKey | 10EBK-ND | Active | Speaker series resistor |
| 015 | Kemet | C320C104M5R5TA | Capacitor, 0.1µF, 50V, ceramic | Axial | 4 | EA | $0.10 | $0.40 | DigiKey | 399-4151-ND | Active | Bypass caps: SRAM, Flash, shift reg, spare |
| 016 | Nichicon | UVR1C100MDD | Capacitor, 10µF, 16V, electrolytic | Radial 2.5mm | 3 | EA | $0.25 | $0.75 | DigiKey | 493-1081-ND | Active | Audio input coupling + VCC bypass |
| 017 | Nichicon | UVR1C221MHD | Capacitor, 220µF, 16V, electrolytic | Radial 5mm | 1 | EA | $0.50 | $0.50 | DigiKey | 493-1377-ND | Active | LM386 output coupling |
| 018 | — | — | Full-size solderless breadboard, 830 tie-points | — | 1 | EA | $10.00 | $10.00 | Amazon | — | — | Any brand (Elenco 9440 or equivalent) |
| 019 | — | — | Jumper wire kit M-M 20cm, assorted colours | — | 1 | PK | $4.00 | $4.00 | Amazon | — | — | |
| 020 | Bourns | PTV09A-4020F-A103 | Potentiometer, 10kΩ, audio/log taper, 9mm, 20mm shaft | Through-hole | 1 | EA | $1.50 | $1.50 | DigiKey | PTV09A-4020F-A103-ND | Active | Volume control; RC filter output → wiper → LM386 pin 3. Use A (audio) taper, not B (linear). |

---

## Cost Summary

| Category | Ext Price |
|----------|-----------|
| MCU & LaunchPad | $10.00 |
| Display | $49.95 |
| Memory (SRAM + Flash) | $3.25 |
| Input (shift reg + buttons) | $3.20 |
| Audio (amp + speaker + pot) | $4.50 |
| Power (charger + battery) | $20.00 |
| Passives (R + C) | $1.95 |
| Prototyping (headers + breadboard + wire) | $21.00 |
| **Total (est., excl. shipping)** | **$113.85** |

---

## Vendor Split

| Vendor | Items | Est. Subtotal |
|--------|-------|--------------|
| Adafruit (adafruit.com) | 002, 010, 011 | $69.95 |
| DigiKey (digikey.com) | 003, 004, 005, 006, 007, 008, 009, 012–017, 020 | $18.90 |
| Mouser (mouser.com) | 001 | $10.00 |
| Amazon / generic | 018, 019 | $14.00 |

> DigiKey part numbers are catalog references — search the MPN directly if a number returns no result (catalog IDs change more often than MPNs).
> Items 002, 010, 011 are available from Adafruit only. No DigiKey/Mouser equivalent.
> Item 004 (W25Q32JVDIQ DIP-8): use "search MPN" on DigiKey/Mouser — this variant has limited US distributor stocking; verify availability before ordering.
