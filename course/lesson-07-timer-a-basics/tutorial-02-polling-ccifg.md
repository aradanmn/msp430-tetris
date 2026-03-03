# Tutorial 07-2 · Polling CCIFG

## The CCIFG Flag

Each capture/compare unit has a flag in its TACCTL register:

- `TACCTL0` bit 0 = `CCIFG` — set when TAR reaches TACCR0 (in Up mode)
- `TACCTL1` bit 0 = `CCIFG` — set when TAR reaches TACCR1
- `TACCTL2` bit 0 = `CCIFG` — set when TAR reaches TACCR2

These flags must be **cleared manually** when polling (unlike interrupt mode
where they clear on ISR entry or TAIV read).

---

## Polling CCIFG — Wait for a Timer Period

```asm
; Wait for one timer period to complete
wait_ccifg:
        bit.w   #CCIFG, &TACCTL0    ; test CCIFG bit (bit 0)
        jz      wait_ccifg          ; loop if not yet set

        bic.w   #CCIFG, &TACCTL0    ; clear the flag (IMPORTANT!)
        ; ← exactly one period has elapsed
```

This is a **busy-wait**: the CPU does nothing but test the flag. It works well
for simple timing, but wastes power.  In Lesson 11 you will use an ISR instead.

---

## Complete Polling Example — 500ms Blink

```asm
main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; 1MHz DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR

        ; Timer_A: SMCLK/8 = 125kHz, Up mode, period = 62500 ticks = 500ms
        mov.w   #62499, &TACCR0
        mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL

loop:
        ; Wait for timer period
        bit.w   #CCIFG, &TACCTL0
        jz      loop

        bic.w   #CCIFG, &TACCTL0    ; clear flag
        xor.b   #LED1, &P1OUT       ; toggle LED every 500ms
        jmp     loop
```

LED1 toggles every 500ms → **1Hz blink rate**.

---

## Multiple Periods Without Restarting the Timer

You can wait multiple periods in a row without stopping the timer:

```asm
; Wait 4 periods (4 × 500ms = 2 seconds)
        mov.w   #4, R13
wait4:
        bit.w   #CCIFG, &TACCTL0
        jz      wait4
        bic.w   #CCIFG, &TACCTL0
        dec.w   R13
        jnz     wait4
```

The timer keeps running continuously; you just consume each CCIFG as it arrives.

---

## Two LEDs, Different Rates (Continuous Mode)

In **Continuous mode** (MC_2), TAR runs freely from 0 to 0xFFFF. You schedule
the next event by adding a fixed offset to the current TACCR value:

```asm
; Set up SMCLK continuous mode
mov.w   #(TASSEL_2|MC_2|TACLR), &TACTL

; Schedule first LED1 event (31250 ticks = 250ms at 125kHz... but we're
; at 1MHz here so 62500 ticks = 62.5ms — adjust divisor as needed)
mov.w   &TAR, R12
add.w   #62500, R12
mov.w   R12, &TACCR0    ; next LED1 event

; Main loop: check CCIFG0 and CCIFG1 alternately
loop:
        bit.w   #CCIFG, &TACCTL0
        jz      check1
        bic.w   #CCIFG, &TACCTL0
        xor.b   #LED1, &P1OUT
        ; re-arm: TACCR0 += period
        add.w   #62500, &TACCR0

check1:
        bit.w   #CCIFG, &TACCTL1
        jz      loop
        bic.w   #CCIFG, &TACCTL1
        xor.b   #LED2, &P1OUT
        add.w   #31250, &TACCR1     ; half the period
        jmp     loop
```

---

## Key Rules for Polling

1. **Always clear CCIFG** after detecting it — or it stays set forever
2. **Timer keeps running** even while you're doing work between polls
3. If your work takes longer than one period, you'll **miss a tick** (CCIFG
   stays set, you see one flag for two periods)
4. For precise timing in production, use interrupts (Lesson 11)

---

## Next

Now try `examples/timer_basic.s` and then the exercises.
