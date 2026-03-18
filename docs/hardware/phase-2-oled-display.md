# Phase 2 Hardware — SSD1309 OLED Display
*Added before Lesson 6*

## Parts to Order

| Part | Description | Source | Part # | ~Cost |
|------|-------------|--------|--------|-------|
| SSD1309 2.42" OLED | 128×64 SPI, 3.3V | Adafruit | #2719 | $18 |
| Samtec headers | Long-pin breakaway, 40-pos | DigiKey | SAM1029-40-ND | $3.50 |
| Breadboard | Full-size 830-tie (Elenco 9440) | Amazon | — | $10 |
| Jumper wires | Male-to-male, 20+ | Amazon | — | $4 |

## Pin Connections

| OLED Pin | MSP430 Pin | Notes |
|----------|-----------|-------|
| GND | GND | |
| VCC | 3.3V | Do NOT use 5V |
| SCLK (D0) | P1.5 | USCI_B0 CLK |
| MOSI (D1) | P1.7 | USCI_B0 SIMO |
| RST | P2.2 | GPIO — toggle on init |
| DC | P2.1 | LOW = command, HIGH = data |
| CS | P2.0 | Active LOW chip select |

## Breadboard Layout

```
LaunchPad 3.3V ─── breadboard +rail
LaunchPad GND  ─── breadboard -rail

OLED:
  VCC  ─── +rail
  GND  ─── -rail
  SCLK ─── P1.5
  MOSI ─── P1.7
  RST  ─── P2.2
  DC   ─── P2.1
  CS   ─── P2.0
```

## SSD1309 Init Sequence Notes

The SSD1309 uses an **external charge pump** — unlike the SSD1306, it does NOT need a charge pump enable command. Do not send `CMD_CHARGE_PUMP, 0x14` (that is SSD1306-only and will break the SSD1309 init).

Minimal init sequence (covered in Lesson 9):
1. RST pulse (toggle P2.2 low → delay → high)
2. CS low, DC low (command mode)
3. Send display off (`0xAE`)
4. Set clock divide / oscillator frequency
5. Set multiplex ratio (63 for 64-row display)
6. Set display offset, start line
7. Set segment remap, COM scan direction
8. Set contrast
9. Set memory addressing mode
10. Send display on (`0xAF`)
