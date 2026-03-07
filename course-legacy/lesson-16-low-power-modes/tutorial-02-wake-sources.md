# Tutorial 16-2 · Wake Sources and LPM Design Patterns

## Wake Source Summary

| Source | Min LPM | ISR Vector | Notes |
|--------|---------|------------|-------|
| WDT Interval | LPM3 | 0xFFF6 | ACLK or SMCLK source |
| Timer_A CC0 | LPM0 | 0xFFF4 | Needs SMCLK (LPM0 max) or ACLK (LPM3) |
| GPIO (P1) | LPM4 | 0xFFE4 | Any edge/level |
| UART RX | LPM0 | 0xFFEC | SMCLK must stay on |
| ADC10 | LPM0 | 0xFFEA | DCO must be on for conversion |

---

## Pattern 1: LPM3 + WDT Interval (1Hz blink)

This is the classic ultra-low-power periodic task pattern:

```asm
main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL     ; stop WDT

        ; Use VLO as ACLK (no crystal required)
        mov.b   #LFXT1S_2, &BCSCTL3

        ; WDT interval: ACLK/32768 ≈ 1s with 12kHz VLO
        mov.w   #(WDTPW|WDTTMSEL|WDTSSEL|WDTCNTCL), &WDTCTL
        bis.b   #WDTIE, &IE1

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

main_loop:
        bis.w   #(GIE|CPUOFF|SCG0|SCG1), SR    ; enter LPM3
        nop                                      ; executed after wake

        xor.b   #LED1, &P1OUT                   ; do work
        jmp     main_loop

WDT_ISR:
        bic.w   #(CPUOFF|SCG0|SCG1), 0(SP)     ; exit LPM3
        reti

        .section ".vectors","ax",@progbits
        .org    0xFFF6
        .word   WDT_ISR
        .org    0xFFFE
        .word   main
```

---

## Pattern 2: LPM4 + GPIO Wakeup

Deepest sleep, woken by button press:

```asm
main:
        ; Button setup (P1.3, falling edge, pull-up)
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES        ; falling edge
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE

        bis.w   #(GIE|CPUOFF|SCG0|SCG1|OSCOFF), SR   ; LPM4
        nop

        ; Woken by button — do work, then loop back to LPM4

PORT1_ISR:
        bic.b   #BTN, &P1IFG
        bic.w   #(CPUOFF|SCG0|SCG1|OSCOFF), 0(SP)    ; exit LPM4
        reti
```

---

## Pattern 3: LPM0 + Timer_A SMCLK Tick

Timer_A runs from SMCLK in LPM0.  Identical to Lesson 11 but CPU sleeps between
ticks instead of spinning:

```asm
main_loop:
        bis.w   #(GIE|CPUOFF), SR       ; LPM0 — SMCLK stays on
        nop

        ; ISR woke us — check if work is due
        mov.w   &ms_tick, R12
        sub.w   &t_last, R12
        cmp.w   #1000, R12
        jl      main_loop               ; not 1 second yet
        mov.w   &ms_tick, &t_last
        ; … do 1-second task …
        jmp     main_loop

TIMERA_CC0_ISR:
        inc.w   &ms_tick
        bic.w   #CPUOFF, 0(SP)          ; wake after every tick
        reti
```

---

## Timer_A from ACLK for LPM3

Source Timer_A from ACLK (32.768 kHz) to go deeper than LPM0:

```asm
        ; Timer_A: ACLK/1, Up mode, TACCR0 = 32767 → 1Hz
        mov.w   #32767, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_1|MC_1|TACLR), &TACTL   ; TASSEL_1 = ACLK
```

Now LPM3 is valid (SMCLK can stop, ACLK keeps Timer_A running).

---

## WDT Interval Periods at ACLK (VLO ≈ 12 kHz)

| WDTIS bits | Divisor | Period (VLO) | Period (32kHz xtal) |
|------------|---------|-------------|---------------------|
| 00         | 32768   | ~2.7 s      | 1 s |
| 01         | 8192    | ~0.68 s     | 0.25 s |
| 10         | 512     | ~42 ms      | 15.6 ms |
| 11         | 64      | ~5.3 ms     | 1.95 ms |

---

## Next

Exercises implement the three patterns: LPM3+WDT 1Hz blink, LPM4+button wakeup,
and LPM0+Timer tick scheduler.
