# Tutorial 01 — GPIO Input in Depth

## The Three Registers for Input

Reading a button requires three registers working together:

```
P1DIR — Direction   (0 = input, 1 = output)
P1REN — Resistor Enable (1 = enable internal resistor on this pin)
P1OUT — Resistor Direction (1 = pull-up, 0 = pull-down) when pin is input
P1IN  — Input register (read-only: reflects the actual voltage on each pin)
```

You already know `P1DIR` and `P1OUT` from output work. When a pin is configured
as an input (`P1DIR` bit = 0), `P1OUT` takes on a new role: it selects whether
the internal resistor pulls the pin HIGH or LOW.

---

## Button S2 on the LaunchPad

The LaunchPad has one user button: **S2** on **P1.3**, active LOW.

```
Bit position:  7     6     5     4     3     2     1     0
Pin:          P1.7  P1.6  P1.5  P1.4  P1.3  P1.2  P1.1  P1.0
Hardware:           LED2              BTN         RXD   LED1
                                      ^^^
                                    P1.3 = S2
```

"Active LOW" means:
- Button **released** → pin reads HIGH (1)
- Button **pressed**  → pin reads LOW  (0)

Why? The button connects P1.3 to GND. When pressed, it pulls the pin to 0 V.
When released, nothing drives the pin — it would float without a pull-up resistor.

---

## Configuring a Pin as Input with Pull-Up

The full three-step setup for P1.3:

```asm
; Step 1: make P1.3 an input (clear the direction bit)
bic.b   #BIT3, &P1DIR       ; P1.3 = input

; Step 2: enable the internal resistor on P1.3
bis.b   #BIT3, &P1REN       ; turn on the resistor

; Step 3: set P1OUT bit to select pull-UP (not pull-down)
bis.b   #BIT3, &P1OUT       ; pull-up: pin reads HIGH when button released
```

In code we use the named constant `BTN` (defined in `msp430g2553-defs.s` as
`BIT3 = 0x08`) instead of the raw bit number:

```asm
bic.b   #BTN, &P1DIR        ; input
bis.b   #BTN, &P1REN        ; enable resistor
bis.b   #BTN, &P1OUT        ; pull-up (HIGH when released, LOW when pressed)
```

---

## Reading a Pin with `bit.b`

`bit.b` ANDs a mask with a register and sets the Zero flag, **without modifying
the register**. It's a non-destructive read.

```asm
bit.b   #BTN, &P1IN         ; AND P1IN with BTN mask → sets Zero flag
```

- If P1.3 is **HIGH** (button released): bit 3 of P1IN = 1 → AND result ≠ 0 → **Zero clear**
- If P1.3 is **LOW**  (button pressed):  bit 3 of P1IN = 0 → AND result = 0 → **Zero set**

This is the opposite of what you might expect — Zero set means the pin is 0
(button pressed). Keep that in mind.

---

## Branching on Button State

```asm
bit.b   #BTN, &P1IN
jz      button_pressed      ; Zero set  → bit was 0 → button is pressed
jnz     button_released     ; Zero clear → bit was 1 → button is released
```

Or equivalently, to loop while the button is NOT pressed:

```asm
wait_for_press:
    bit.b   #BTN, &P1IN
    jnz     wait_for_press  ; bit = 1 → released → keep waiting
; falls through when bit = 0 → pressed
```

And to wait while the button IS pressed (wait for release):

```asm
wait_for_release:
    bit.b   #BTN, &P1IN
    jz      wait_for_release ; bit = 0 → still pressed → keep waiting
; falls through when bit = 1 → released
```

---

## Level vs. Edge Detection

### Level detection — "is the button currently held down?"

Check the pin on every pass through the loop. The LED tracks the button
state continuously.

```asm
main_loop:
    bit.b   #BTN, &P1IN
    jnz     led_off             ; released → turn LED off
    bis.b   #LED1, &P1OUT      ; pressed  → LED on
    jmp     main_loop
led_off:
    bic.b   #LED1, &P1OUT
    jmp     main_loop
```

### Edge detection — "did the button just get pressed?"

You want to react once per press, not continuously. Poll for the press,
react once, then wait for the release before accepting another press.

```asm
wait_press:
    bit.b   #BTN, &P1IN
    jnz     wait_press          ; released → wait

    ; --- button just pressed ---
    xor.b   #LED1, &P1OUT      ; toggle LED once

wait_release:
    bit.b   #BTN, &P1IN
    jz      wait_release        ; still pressed → wait

    ; --- button released → ready for next press ---
    jmp     wait_press
```

This is the pattern you'll use most often in a game: advance state on each
button press, not on each polling loop.

---

## Summary

| Task | Code |
|------|------|
| Configure P1.3 as input with pull-up | `bic.b #BTN, &P1DIR` / `bis.b #BTN, &P1REN` / `bis.b #BTN, &P1OUT` |
| Read pin state | `bit.b #BTN, &P1IN` |
| Branch if pressed (bit = 0) | `jz pressed_label` |
| Branch if released (bit = 1) | `jnz released_label` |
| Wait for press | `bit.b #BTN, &P1IN` / `jnz wait` |
| Wait for release | `bit.b #BTN, &P1IN` / `jz wait` |

Next: Tutorial 02 covers why buttons don't register cleanly and what to do about it.
