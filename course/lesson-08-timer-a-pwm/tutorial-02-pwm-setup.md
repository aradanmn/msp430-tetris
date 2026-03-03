# Tutorial 08-2 · PWM Hardware Setup

## Pin Muxing — Connecting Timer_A to P1.6

P1.6 can be GPIO (LED2) or the **TA0.2** timer output.  To use it for PWM, you
must:

1. Set P1.6 as an **output** (P1DIR |= BIT6)
2. Enable **peripheral function** (P1SEL |= BIT6)
3. Enable **secondary peripheral** (P1SEL2 |= BIT6) — for TA0.2

```asm
; Route P1.6 to Timer_A output (TA0.2)
bis.b   #LED2, &P1DIR       ; P1.6 = output
bis.b   #LED2, &P1SEL       ; P1SEL[6] = 1
bis.b   #LED2, &P1SEL2      ; P1SEL2[6] = 1  → TA0.2
```

When both P1SEL and P1SEL2 are 1 for P1.6, the Timer_A CC2 output drives the pin
automatically.  LED2 is now controlled by TACCTL2/TACCR2, NOT by P1OUT.

---

## Complete PWM Setup Code

```asm
; === 1. Pin configuration ===
bis.b   #LED2, &P1DIR
bis.b   #LED2, &P1SEL
bis.b   #LED2, &P1SEL2      ; P1.6 → TA0.2

; === 2. Timer_A period (TACCR0) ===
; 1kHz PWM: SMCLK=1MHz, no divider (ID_0), TACCR0=999
mov.w   #999, &TACCR0

; === 3. Duty cycle (TACCR2) ===
; 50% duty: TACCR2 = 499
mov.w   #499, &TACCR2

; === 4. Output mode for CC2 ===
mov.w   #OUTMOD_7, &TACCTL2  ; Reset/Set PWM

; === 5. Start Timer_A ===
; SMCLK source, no divider, Up mode, clear counter
mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL
```

That's it — P1.6 now outputs a 1kHz PWM waveform at 50% duty cycle with zero CPU
involvement.

---

## Changing Duty Cycle at Runtime

Simply write a new value to TACCR2 while the timer is running:

```asm
; Ramp from 0% to 100% duty cycle
        clr.w   R12             ; R12 = duty cycle (0 to 999)
ramp_up:
        mov.w   R12, &TACCR2   ; update duty cycle
        ; small delay
        inc.w   R12
        cmp.w   #1000, R12
        jlo     ramp_up
        ; now at 100% (TACCR2 = 999 = TACCR0)
```

The timer hardware handles the waveform — you just change TACCR2.

---

## Breathing LED Pattern

```asm
; Breathing: ramp up then ramp down, repeat
breathe:
        ; Ramp up: TACCR2 from 0 to 999
        clr.w   R12
up:     mov.w   R12, &TACCR2
        call    #short_delay
        inc.w   R12
        cmp.w   #1000, R12
        jlo     up

        ; Ramp down: TACCR2 from 999 to 0
        mov.w   #999, R12
down:   mov.w   R12, &TACCR2
        call    #short_delay
        dec.w   R12
        cmp.w   #0xFFFF, R12   ; underflow check (dec 0 → 0xFFFF)
        jne     down

        jmp     breathe
```

---

## P1.6 Pin Mux Table

| P1SEL | P1SEL2 | Function |
|-------|--------|----------|
| 0 | 0 | GPIO (P1.6, LED2) |
| 1 | 0 | TA0.1 (CC1 output) |
| 0 | 1 | reserved |
| 1 | 1 | **TA0.2** (CC2 output) ← use this for PWM |

---

## Returning P1.6 to GPIO

If you want to stop PWM and control the LED manually again:

```asm
bic.b   #LED2, &P1SEL       ; clear SEL bits → back to GPIO
bic.b   #LED2, &P1SEL2
; Now P1OUT.6 controls the LED again
```

---

## Summary Checklist

- [ ] Set P1.6 as output (`P1DIR |= BIT6`)
- [ ] Both P1SEL and P1SEL2 bits 6 = 1 for TA0.2
- [ ] Set TACCR0 for desired period/frequency
- [ ] Set TACCR2 for desired duty cycle (0 to TACCR0)
- [ ] Set TACCTL2 = OUTMOD_7
- [ ] Start timer with TASSEL_2 | MC_1 | TACLR

Now open `examples/pwm_demo.s` to see the complete breathing LED program.
