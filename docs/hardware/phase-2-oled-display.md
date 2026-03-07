# Phase 2 Hardware — SSD1306 OLED Display
*Added before Lesson 6*

## Parts to Order

| Part | Description | Source | ~Cost |
|------|-------------|--------|-------|
| SSD1306 OLED | 0.96" 128×64 SPI, 7-pin, 3.3V | Amazon, AliExpress, Adafruit | $4–8 |
| Breadboard | Full-size 830-tie | Amazon | $6 |
| Jumper wires | Male-to-male, 20+ | Amazon | $4 |

> **Important:** Buy the **7-pin SPI version** (has CS, DC, RST pins). The 4-pin I2C version will not work for this project. The board label usually says "SPI" or lists pins: GND VCC D0 D1 RES DC CS.

## Pin Connections

| OLED Pin | MSP430 Pin | Notes |
|----------|-----------|-------|
| GND | GND | |
| VCC | 3.3V | Do NOT use 5V — will damage OLED |
| D0 (SCLK) | P1.5 | USCI_B0 CLK |
| D1 (MOSI) | P1.7 | USCI_B0 SIMO |
| RES (RST) | P2.2 | GPIO — toggle on init |
| DC | P2.1 | GPIO — command (LOW) vs data (HIGH) |
| CS | P2.0 | GPIO — active LOW chip select |

## Breadboard Layout

```
LaunchPad 3.3V ─── breadboard +rail
LaunchPad GND  ─── breadboard -rail

OLED:
  VCC ─── +rail
  GND ─── -rail
  D0  ─── P1.5 (pin 8 on LaunchPad header)
  D1  ─── P1.7 (pin 10)
  RES ─── P2.2 (pin 19)
  DC  ─── P2.1 (pin 18)
  CS  ─── P2.0 (pin 17)
```

## Verification

After wiring, Lesson 9 will walk you through the SSD1306 init sequence. A successful connection shows a cleared (black) screen. If you see noise/garbage pixels, check VCC is 3.3V (not 5V) and that D0/D1 are not swapped.
