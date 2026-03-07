# Tutorial 01 — Reading Buttons

## GPIO Input Configuration

By default after reset, all GPIO pins are inputs (P1DIR = 0x00). To read a
button, you need three things:

1. **Direction = input** (`P1DIR` bit = 0) — the pin is in high-impedance mode
2. **Pull resistor enabled** (`P1REN` bit = 1) — connects an internal resistor
3. **Pull direction selected** (`P1OUT` bit = 1 for pull-up, 0 for pull-down) —
   selects which way the resistor pulls

| Register | Address | Purpose |
|----------|---------|---------|
| P1DIR | 0x0022 | 0 = input (default), 1 = output |
| P1REN | 0x0027 | 0 = no pull resistor, 1 = enable pull resistor |
| P1OUT | 0x0021 | When DIR=0 and REN=1: 1 = pull-up, 0 = pull-down |
| P1IN | 0x0020 | Read-only: current pin voltage (1 = HIGH, 0 = LOW) |

---

## The LaunchPad Button Circuit

The MSP-EXP430G2 LaunchPad has a button labeled S2 connected to P1.3:

```
3.3V ──[internal pull-up resistor]──── P1.3 ──┐
                                               │
                                            [S2 button]
                                               │
                                             GND
```

When the button is **not pressed**: P1.3 is pulled HIGH through the internal
resistor. P1IN bit 3 reads 1.

When the button **is pressed**: the button connects P1.3 directly to GND. P1IN
bit 3 reads 0.

This is called **active-low**: the signal is "active" (button pressed) when the
pin reads LOW. This is the standard design in embedded systems because it
requires no external resistor — the internal pull-up does the job.

---

## Configuring P1.3 as an Input with Pull-Up

```asm
; Make P1.3 an input (clear the direction bit)
bic.b   #BIT3, &P1DIR       ; P1.3 = input (this is already the default)

; Enable the internal pull resistor on P1.3
bis.b   #BIT3, &P1REN       ; Enable pull resistor

; Select pull-UP (not pull-down)
; When DIR=0 and REN=1, P1OUT selects pull direction
bis.b   #BIT3, &P1OUT       ; P1OUT bit 3 = 1 → pull-UP selected
```

After these three lines, P1.3 will read HIGH (~3.3V) when the button is not
pressed, and LOW (~0V) when the button is pressed.

The `BTN` constant defined in `msp430g2552-defs.s` equals `BIT3` (0x08), so you
can write:
```asm
bic.b   #BTN, &P1DIR
bis.b   #BTN, &P1REN
bis.b   #BTN, &P1OUT
```

---

## Reading the Button: BIT.B

The `bit.b` instruction performs a bitwise AND between a mask and a register,
setting the Zero flag based on the result, without modifying the register:

```asm
bit.b   #BTN, &P1IN         ; Test bit 3 of P1IN
                             ; Z=1 if P1IN bit 3 is 0 (button pressed)
                             ; Z=0 if P1IN bit 3 is 1 (button not pressed)
```

Remember: button pressed = pin LOW = bit is 0 = Zero flag SET.

This seems counterintuitive but is easy to remember: "zero flag set means zero
volts on the pin means the button is pressed."

---

## Polling for a Button Press

The simplest way to detect a button press is a tight polling loop:

```asm
wait_press:
        bit.b   #BTN, &P1IN     ; Test button bit
        jnz     wait_press      ; Jump if NOT zero (pin HIGH = not pressed)
                                ; Falls through when Z=1 (pin LOW = pressed)
; Button is now pressed — do something here
```

And to wait for release:
```asm
wait_release:
        bit.b   #BTN, &P1IN     ; Test button bit
        jz      wait_release    ; Jump if zero (pin LOW = still pressed)
                                ; Falls through when Z=0 (pin HIGH = released)
; Button is now released
```

---

## Active-Low Logic and jz/jnz

The active-low convention causes a common confusion with `jz` and `jnz`. Here is
a memory aid:

| Button state | P1.3 voltage | P1IN bit 3 | BIT.B result | Zero flag | Action |
|--------------|-------------|------------|--------------|-----------|--------|
| Not pressed | HIGH (3.3V) | 1 | 1 & 1 = 1 (nonzero) | Z = 0 | `jnz` taken |
| Pressed | LOW (0V) | 0 | 1 & 0 = 0 (zero) | Z = 1 | `jz` taken |

So: `jz pressed_handler` means "jump if zero, which means the pin is LOW, which
means the button IS pressed."

---

## Software Debouncing

Mechanical buttons don't have a clean transition. When you press or release a
button, the contacts "bounce" — rapidly making and breaking contact several
times over 5–20 milliseconds before settling. Without debouncing, the CPU sees
dozens of rapid press/release events from a single press.

The simplest software debounce: when a press (or release) is detected, wait for
the bouncing to settle before taking action:

```asm
; Detect press
wait_press:
        bit.b   #BTN, &P1IN
        jnz     wait_press              ; Wait until pin goes LOW

        ; Debounce: wait 20ms for bouncing to stop
        call    #debounce_delay         ; ~20ms at 1MHz

        ; Now the button is stably pressed
        ; (Optional: re-read to confirm it's still pressed)
        bit.b   #BTN, &P1IN
        jnz     wait_press              ; Bounced HIGH — false press, retry

        ; Genuine press confirmed — take action here
```

The debounce delay just needs to be longer than the worst-case bounce time
(~20ms is typical):

```asm
; ~20ms debounce delay at 1MHz: 20000 µs / 3 cycles = 6667 iterations
debounce_delay:
        push    R15
        mov.w   #6667, R15
dbl:    dec.w   R15
        jnz     dbl
        pop     R15
        ret
```

Applying the same debounce to the release event prevents false "re-press"
detections immediately after the button is released.
