# Tutorial 01 — GPIO Registers and Bit Manipulation

## GPIO Port 1 Registers

Port 1 (P1) has 8 pins (P1.0 through P1.7). Three registers control them:

| Register | Address | Purpose |
|----------|---------|---------|
| P1DIR | 0x0022 | Direction: 0=input, 1=output (reset=all inputs) |
| P1OUT | 0x0021 | Output value when pin is output; pull direction when input |
| P1IN | 0x0020 | Read-only: current voltage on each pin |

Each register is 8-bit, one bit per pin:
```
Bit:   7    6    5    4    3    2    1    0
Pin: P1.7 P1.6 P1.5 P1.4 P1.3 P1.2 P1.1 P1.0
```

After a reset, all P1DIR bits are 0 — all pins are inputs. This is a safe
default: input pins draw very little current and won't accidentally drive
anything.

---

## LaunchPad LED Connections

On the MSP-EXP430G2 LaunchPad:

- **P1.0** → 330Ω resistor → **LED1** (Red) → GND
- **P1.6** → 330Ω resistor → **LED2** (Green) → GND

The LEDs are connected between the GPIO pin and ground through a
current-limiting resistor. When the GPIO pin is HIGH (output 1), current flows
through the resistor and LED to ground, turning the LED on. When the GPIO pin is
LOW (output 0), no current flows and the LED is off.

The resistor is important — without it, setting the pin HIGH would short-circuit
the 3.3V supply through the LED to GND, potentially damaging the MSP430 or the
LED.

---

## Bit Manipulation Instructions

GPIO registers are 8-bit. You must use `.b` suffix instructions when accessing
them.

The three most important GPIO output instructions:

| Instruction | Effect | Example |
|------------|--------|---------|
| `bis.b #mask, &REG` | Set bits in mask (Bit Set) | `bis.b #BIT0, &P1OUT` sets P1.0 HIGH |
| `bic.b #mask, &REG` | Clear bits in mask (Bit Clear) | `bic.b #BIT0, &P1OUT` sets P1.0 LOW |
| `xor.b #mask, &REG` | Toggle bits in mask | `xor.b #BIT0, &P1OUT` flips P1.0 |
| `bit.b #mask, &REG` | Test bits, set flags (no change to REG) | Sets Z=1 if those bits are all 0 |

Why use BIS/BIC instead of MOV? Because `mov.b #0x01, &P1OUT` would force ALL 8
bits of P1OUT to specific values, potentially affecting other pins you don't
intend to change. BIS and BIC only affect the bits you specify, leaving all
other bits unchanged.

---

## Setting Up Output Pins

The complete sequence to drive an LED:

```asm
; Step 1: Configure the pin direction (make it an output)
bis.b   #BIT0, &P1DIR       ; P1.0 is now an output (bit 0 of P1DIR = 1)

; Step 2: Control the pin level
bis.b   #BIT0, &P1OUT       ; P1.0 HIGH → LED1 ON
bic.b   #BIT0, &P1OUT       ; P1.0 LOW  → LED1 OFF
xor.b   #BIT0, &P1OUT       ; Toggle P1.0 → LED1 flips state
```

Multiple pins at once:
```asm
; Configure both LED pins as outputs
bis.b   #(LED1|LED2), &P1DIR    ; bits 0 and 6 = outputs

; Turn on both LEDs
bis.b   #(LED1|LED2), &P1OUT

; Turn off LED1 only (LED2 unchanged)
bic.b   #LED1, &P1OUT

; Toggle LED2 (LED1 unchanged)
xor.b   #LED2, &P1OUT
```

The constants `LED1`, `LED2`, `BIT0`, `BIT6`, etc. are defined in
`msp430g2552-defs.s`:
- `BIT0` = 0x01 (bit 0)
- `BIT1` = 0x02 (bit 1)
- `BIT6` = 0x40 (bit 6)
- `LED1` = BIT0 (P1.0)
- `LED2` = BIT6 (P1.6)

---

## Writing Order: P1DIR Before or After P1OUT?

It is safe to write P1OUT before setting P1DIR. The output register value is
latched internally but only drives the pin when DIR=1. This means you can safely
set up the desired initial state in P1OUT, then configure the direction — the
pin will transition directly to the intended level without a transient glitch.

```asm
; Safe pattern: set output value first, then direction
bic.b   #LED1, &P1OUT       ; Ensure LED starts OFF
bis.b   #LED1, &P1DIR       ; Make it an output — drives LOW (LED OFF)
```

Alternatively, if the initial state doesn't matter, set direction first:
```asm
bis.b   #LED1, &P1DIR       ; Configure as output (drives LOW by default)
bis.b   #LED1, &P1OUT       ; Now turn on LED
```

Both approaches work on the MSP430G2552. Choose whichever makes your intent
clearer.

---

## The BIT Constants

Bit mask constants make code readable. The `msp430g2552-defs.s` file defines:

| Constant | Value | Binary |
|----------|-------|--------|
| BIT0 | 0x01 | 00000001 |
| BIT1 | 0x02 | 00000010 |
| BIT2 | 0x04 | 00000100 |
| BIT3 | 0x08 | 00001000 |
| BIT4 | 0x10 | 00010000 |
| BIT5 | 0x20 | 00100000 |
| BIT6 | 0x40 | 01000000 |
| BIT7 | 0x80 | 10000000 |

To control multiple bits simultaneously, combine them with the `|` operator
(bitwise OR) in the immediate value:
```asm
bis.b   #(BIT0|BIT6), &P1DIR   ; Set bits 0 and 6 — both LEDs as outputs
```

The `|` operator is evaluated by the C preprocessor (because we use `-x
assembler-with-cpp`), so `(BIT0|BIT6)` becomes `(0x01|0x40)` = `0x41` before the
assembler sees it.

---

## Example: Blinking LED1

A minimal working blink program structure:

```asm
#include "../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; Stop watchdog

        bis.b   #LED1, &P1DIR               ; P1.0 as output

loop:
        xor.b   #LED1, &P1OUT               ; Toggle LED1
        ; ... delay here (see Tutorial 02) ...
        jmp     loop

        .end
```

Without a delay, the toggle happens millions of times per second — the LED
appears constantly on (or off, depending on duty cycle) due to persistence of
vision. The next tutorial explains how to create appropriate delays.
