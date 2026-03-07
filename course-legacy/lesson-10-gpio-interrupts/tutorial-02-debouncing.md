# Tutorial 10-2 · Button Debouncing

## The Bounce Problem

Mechanical buttons don't make clean transitions.  When pressed, the metal
contacts bounce several times over ~5–20ms before settling:

```
Ideal:     ────────╮_______________
                   ↑ press

Actual:    ────────╮╭╮╭╮╭__________
                    bouncing
```

Without debouncing, the ISR fires 3–10 times per press instead of once. Your LED
counter would jump by random amounts.

---

## Strategy 1 — Delay in ISR (Simple)

After detecting the first edge, disable the interrupt, wait for the bounce to
settle, re-enable:

```asm
PORT1_ISR:
        bic.b   #BTN, &P1IE         ; disable P1.3 interrupt
        bic.b   #BTN, &P1IFG        ; clear flag

        xor.b   #LED1, &P1OUT       ; do the action

        ; Wait ~20ms for bounce to settle
        ; (we're in an ISR — keep it short, but this is acceptable)
        mov.w   #20, R12
        call    #debounce_delay

        bic.b   #BTN, &P1IFG        ; clear any flags from bounce
        bis.b   #BTN, &P1IE         ; re-enable interrupt
        reti

debounce_delay:
        mov.w   #250, R15
_dly:   dec.w   R15
        jnz     _dly
        dec.w   R12
        jnz     debounce_delay
        ret
```

**Trade-off**: the ISR takes ~20ms.  Generally acceptable for UI buttons but bad
practice for time-critical systems.

---

## Strategy 2 — Timer-Based Debounce (Robust)

1. On button edge: disable P1IE, start a timer
2. When timer fires (20ms later): check if button is still pressed, if so, count
   it as a valid press; re-enable P1IE

This keeps the ISR short but requires a timer.  We'll see this pattern in the
capstone.

---

## Strategy 3 — Re-Check Before Acting

Inside the ISR, after clearing P1IFG, briefly spin-wait then re-read the pin to
confirm it's still in the pressed state:

```asm
PORT1_ISR:
        bic.b   #BTN, &P1IFG

        ; Quick re-check: spin 5ms then confirm button still pressed
        mov.w   #5, R12
        call    #debounce_delay
        bit.b   #BTN, &P1IN         ; still pressed?
        jnz     port1_done          ; no → bounced → ignore

        ; Confirmed press
        xor.b   #LED1, &P1OUT

port1_done:
        reti
```

---

## Which Strategy to Use?

| Situation | Strategy |
|-----------|----------|
| Simple UI, timing not critical | Delay in ISR (Strategy 1 or 3) |
| Time-critical with UI button | Timer-based (Strategy 2) |
| Hardware filter available | RC filter on button line (no software needed) |

For this course, **Strategy 1** (delay in ISR) is used.  It's simple, readable,
and reliable for the LaunchPad's S2 button.

---

## Important Notes

- Always clear **P1IFG** first, then debounce
- After debounce delay, clear P1IFG **again** (bounce may have set it)
- Re-enable P1IE only after both clears

See `examples/gpio_isr.s` for the complete implementation.
