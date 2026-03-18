# Tutorial 01 — GPIO Output in Depth

## The Two Registers You Need

Every GPIO pin on Port 1 is controlled by exactly two registers:

```
P1DIR — Direction register (0 = input, 1 = output)
P1OUT — Output register   (0 = drive LOW, 1 = drive HIGH)
```

Both are 8-bit registers. Bit N in each register controls pin P1.N.

```
Bit position:  7     6     5     4     3     2     1     0
Pin:          P1.7  P1.6  P1.5  P1.4  P1.3  P1.2  P1.1  P1.0
Hardware:           LED2              BTN         RXD   LED1
```

To turn LED1 on:
1. Set bit 0 of P1DIR to 1 — makes P1.0 an output
2. Set bit 0 of P1OUT to 1 — drives P1.0 HIGH — LED lights up

```asm
bis.b   #LED1, &P1DIR       ; bit 0 of P1DIR → 1  (output)
bis.b   #LED1, &P1OUT       ; bit 0 of P1OUT → 1  (HIGH → LED on)
```

---

## The Four Bit-Manipulation Instructions

### `bis.b` — Bit Set (OR)

Forces named bits to 1. All other bits are untouched.

```
Before P1OUT:  0000 0000
bis.b #LED2:   0100 0000   (LED2 = BIT6 = 0x40 = 0100 0000)
After  P1OUT:  0100 0000
```

Use it to turn an LED **on**, or to configure a direction bit.

### `bic.b` — Bit Clear (AND NOT)

Forces named bits to 0. All other bits are untouched.

```
Before P1OUT:  0100 0001   (both LEDs on)
bic.b #LED1:   1111 1110   (mask = NOT BIT0 = NOT 0x01)
After  P1OUT:  0100 0000   (LED1 off, LED2 still on)
```

Use it to turn an LED **off**.

### `xor.b` — Exclusive OR (Toggle)

Flips named bits. All other bits are untouched.

```
Before P1OUT:  0100 0001   (both LEDs on)
xor.b #(LED1|LED2):  0100 0001  (mask)
After  P1OUT:  0000 0000   (both toggled → both off)
```

Use it to **toggle** without caring what the current state is — perfect for a
simple blink where you just want to flip. Avoid it when you need the LED to be
in a specific known state (use `bis.b`/`bic.b` instead).

### `bit.b` — Bit Test (AND, result in flags only)

ANDs the mask with the register and sets the Zero flag, but does NOT write
back. Used to read a pin.

```asm
bit.b   #BIT3, &P1IN        ; is P1.3 (button S2) low?
jz      button_pressed      ; Zero set means the bit was 0 = button pressed
```

You'll use this more in Lesson 03 (input). For now, just know it exists.

---

## Setting Multiple Bits at Once

`bis.b`, `bic.b`, and `xor.b` all accept a multi-bit mask. You can configure
or drive multiple LEDs in a single instruction:

```asm
; Configure both LED1 and LED2 as outputs in one instruction
bis.b   #(LED1|LED2), &P1DIR    ; sets bits 0 and 6

; Turn both off simultaneously
bic.b   #(LED1|LED2), &P1OUT    ; clears bits 0 and 6

; Toggle both at the same instant (no gap between them)
xor.b   #(LED1|LED2), &P1OUT
```

The `|` (OR) combines the masks:
```
LED1 = BIT0 = 0x01 = 0000 0001
LED2 = BIT6 = 0x40 = 0100 0000
                     ---------
LED1|LED2   = 0x41 = 0100 0001
```

---

## Always Set an Explicit Initial State

After reset, P1OUT holds whatever value was last written — either from a
previous flash or from the power-up latch state. It is **not guaranteed to be
zero**.

Always set your LEDs to a known state before entering the main loop:

```asm
bis.b   #(LED1|LED2), &P1DIR    ; both outputs
bic.b   #(LED1|LED2), &P1OUT    ; both off — known state
```

If you want to start with LED1 on and LED2 off:
```asm
bis.b   #(LED1|LED2), &P1DIR
bis.b   #LED1,        &P1OUT    ; LED1 on
bic.b   #LED2,        &P1OUT    ; LED2 off
```

---

## Counted Loops with `dec.w` / `jnz`

The MSP430 has no LOOP instruction, but `dec.w` (decrement) combined with
`jnz` (jump if not zero) gives you a counted loop:

```asm
    mov.w   #5, R7          ; R7 = loop counter
flash_loop:
    bis.b   #LED1, &P1OUT   ; LED on
    mov.w   #200, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT   ; LED off
    mov.w   #200, R12
    call    #delay_ms
    dec.w   R7              ; R7--; sets Zero flag when R7 reaches 0
    jnz     flash_loop      ; jump back if R7 != 0
    ; falls through here after 5 flashes
```

`dec.w` decrements a 16-bit register and sets the Zero and Negative flags
based on the result. `jnz` ("Jump if Not Zero") branches when the Zero flag
is clear — i.e., when the counter has not yet reached zero.

---

## Choosing Registers

The MSP430 has 12 general-purpose registers (R4–R15). By convention:

- **R12–R15**: scratch / function arguments. Can be clobbered by any call.
  `delay_ms` uses R12 and R13, so anything in those is destroyed by a call.
- **R4–R11**: "saved" registers. Subroutines are expected to preserve them
  (in the full ABI, via push/pop — Lesson 04). For now, use them as loop
  counters and state holders that survive across `delay_ms` calls.

Practical rule for this lesson: **keep counters in R4–R8, pass `delay_ms`
its argument in R12**.

```asm
    mov.w   #3, R7              ; R7 = flash counter (survives delay_ms calls)
loop:
    bis.b   #LED1, &P1OUT
    mov.w   #150, R12           ; R12 = ms for delay_ms
    call    #delay_ms           ; R12, R13 clobbered — but R7 is safe
    bic.b   #LED1, &P1OUT
    mov.w   #150, R12
    call    #delay_ms
    dec.w   R7
    jnz     loop
```

---

## Summary

| Task | Code |
|------|------|
| Set LED1 pin as output | `bis.b #LED1, &P1DIR` |
| Turn LED1 on | `bis.b #LED1, &P1OUT` |
| Turn LED1 off | `bic.b #LED1, &P1OUT` |
| Toggle LED1 | `xor.b #LED1, &P1OUT` |
| Both LEDs off | `bic.b #(LED1\|LED2), &P1OUT` |
| Loop N times | `mov.w #N, R7` / `dec.w R7` / `jnz label` |
| Safe counter register | R4–R8 (not clobbered by delay_ms) |

Next: Tutorial 02 shows how to sequence these into phases and build the `flash_leds` subroutine.
