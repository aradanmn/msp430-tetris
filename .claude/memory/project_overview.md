---
name: project_overview
description: MSP430 handheld gaming console — goals, hardware choices, current state
type: project
---

Single repo at github.com/aradanmn/msp430-tetris. 16-lesson assembly course building up to a playable Tetris on a custom handheld.

**Why:** educational platform for MSP430 assembly programming; hardware goal is a Game Boy-style device.

**MCU:** MSP430G2553 on MSP-EXP430G2ET LaunchPad (16KB flash, 512B RAM)

**Display:** Adafruit #2674 — 2.7" SSD1325 grayscale OLED (128×64, 16 gray levels, SPI). Chosen over SSD1309 because this is a multi-game platform, not just Tetris — grayscale matters for future games. PCB footprint irrelevant during prototype phase.

**External memory added to design:**
- 23LC1024-I/P (128KB SPI SRAM, DIP-8) — framebuffer + game state
- W25Q32JVDIQ (4MB SPI NOR Flash, DIP-8) — sprites, music, save data

**Course progress:** Lessons 01–04 complete + review-01-02. Lesson 04 = Timer_A.

**BOM state (Rev D):** 21 line items, total $115.85. W25Q32JVDAIQ (DIP-8) is obsolete — reverted to W25Q32JVSSIQ (SOIC-8) + SOIC-8→DIP-8 adapter (Adafruit #1212, item 005). All items renumbered accordingly. Potentiometer (Bourns PTV09A-4020F-A103, item 021) in Audio Module. CSV has Status column (In Hand / Order / Partial). Files: docs/bom-flat.md, docs/bom-structured.md, docs/bom-order.csv.

**Inventory (2026-03-21):** In hand: LaunchPad, breadboard, jumper wires, SN74HC165N, LM386N-1, SP-3605 speaker, Adafruit #4410 charger, Adafruit #2011 battery, 1kΩ resistors, 10kΩ pot (A+B taper). Partial: B3F-1000 ×10 (need 12), 10kΩ resistors ×10 (need 12), 0.1µF caps ×2 (need 4). Still to order: OLED display, SRAM, Flash, Samtec headers, 10Ω resistors, 10µF caps, 220µF cap. Remaining spend ~$78.

**How to apply:** When suggesting parts or hardware decisions, remember the platform goal (multi-game handheld) and prototype-first mindset (breadboard now, custom PCB later).
