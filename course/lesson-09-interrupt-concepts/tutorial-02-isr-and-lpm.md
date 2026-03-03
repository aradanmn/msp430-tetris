# Tutorial 09-2 · ISRs and Low Power Modes

## Low Power Modes (LPM)

The MSP430 has five low-power modes (LPM0–LPM4) that gate different clock
domains to save power:

| Mode | CPU | MCLK | SMCLK | ACLK | SR bits to set |
|------|-----|------|-------|------|----------------|
| Active | ON | ON | ON | ON | — |
| LPM0 | OFF | OFF | ON | ON | CPUOFF |
| LPM1 | OFF | OFF | OFF | ON | CPUOFF+SCG0 |
| LPM3 | OFF | OFF | OFF | ON(VLO) | CPUOFF+SCG0+SCG1 |
| LPM4 | OFF | OFF | OFF | OFF | CPUOFF+SCG0+SCG1+OSCOFF |

For Timer_A and WDT (which use SMCLK), **LPM0** is the right choice: CPU is off,
but SMCLK keeps running so the timer still counts.

---

## Entering LPM0

```asm
; Enter LPM0 — CPU off, SMCLK on, interrupts enabled
bis.w   #(GIE|CPUOFF), SR
nop                         ; required after mode entry
```

Writing CPUOFF into SR immediately suspends the CPU.  The `NOP` after the `BIS`
is executed as part of the mode-entry sequence (MSP430 family guide requires
it), but after that the CPU halts.

Alternatively in main loop:

```asm
main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; sleep here until ISR fires
        nop
        ; When ISR returns (RETI), execution resumes HERE
        jmp     main_loop           ; go back to sleep
```

---

## Waking from LPM Inside an ISR

When an ISR fires, the CPU wakes (SR is pushed with CPUOFF set, then SR is
loaded with CPUOFF cleared — the CPU runs).  On `RETI`, the **saved SR** (with
CPUOFF set) is restored → CPU goes back to sleep.

If you want the ISR to **permanently wake** the CPU (don't return to sleep),
clear CPUOFF in the saved SR on the stack:

```asm
MY_ISR:
        ; ... do work ...

        ; Wake main permanently:
        bic.w   #CPUOFF, 0(SP)     ; clear CPUOFF in saved SR
        reti                        ; main resumes after the BIS instruction
```

`0(SP)` is the saved SR on the stack (SP points to it during ISR).

Most interrupt-driven programs do NOT wake permanently — they let the ISR return
to sleep so the system keeps sleeping between interrupts.

---

## Complete Interrupt-Driven Template

```asm
#include "../../common/msp430g2552-defs.s"

        .data
flag:   .word 0             ; shared variable between ISR and main

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL  ; WDT interval
        bis.b   #LED1, &P1DIR
        bis.b   #0x01, &IE1         ; WDTIE
        bis.w   #GIE, SR            ; global interrupt enable

main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; LPM0 — sleep until ISR
        nop
        ; ISR returns here after reti
        ; Check flag set by ISR
        tst.w   &flag
        jz      main_loop           ; not set, back to sleep
        clr.w   &flag
        xor.b   #LED1, &P1OUT      ; do work
        jmp     main_loop

;----------------------------------------------------------------------
; WDT_ISR
;----------------------------------------------------------------------
WDT_ISR:
        mov.w   #1, &flag           ; signal main
        ; Do NOT wake main permanently — let it loop
        reti

        .section ".vectors","ax",@progbits
        .org    0xFFF6
        .word   WDT_ISR
        .org    0xFFFE
        .word   main
```

---

## Volatile Variables

In C, variables shared between an ISR and main are marked `volatile` to prevent
the compiler from caching them in registers.  In assembly, you always read/write
from memory directly (`mov.w &flag, R12`) so there is no caching issue.

---

## Key Rules for ISRs

1. **Always use `RETI`**, never `RET`
2. **Save and restore** any register your ISR uses (`PUSH`/`POP`)
3. **Clear the interrupt flag** if not auto-cleared (some flags are, some are
   not — check the peripheral reference)
4. **Keep ISRs short** — do minimal work, set a flag, return
5. **Place vector address** in `.vectors` section with correct `.org`

---

## Next

Open `examples/isr_intro.s` for a complete working program, then work through
the exercises.
