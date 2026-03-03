# Tutorial 06-2 · WDT Interval Timer Mode

## Interval vs Watchdog Mode

| Feature | Watchdog Mode | Interval Timer Mode |
|---------|--------------|---------------------|
| WDTTMSEL bit | 0 (default) | **1** |
| On timeout | Resets CPU | Sets WDTIFG flag |
| ISR possible | No | **Yes** |
| Resets system | Yes | No |

In **interval mode**, the WDT becomes a simple periodic interrupt source. It's
not as flexible as Timer_A, but it uses almost no configuration.

---

## Enabling Interval Mode

```asm
; WDT interval mode, SMCLK/32768, ≈32ms period
mov.w   #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL
```

Key bits:
- `WDTTMSEL` = 1 → interval timer (not watchdog)
- `WDTCNTCL` = 1 → clear counter (start fresh)
- No `WDTHOLD` → counter runs

---

## Enabling the WDT Interrupt

The WDT interval interrupt is controlled through `IE1` (Interrupt Enable 1) and
`IFG1` (Interrupt Flag 1):

```asm
; IE1 is an 8-bit register at 0x0000
; Bit 0 = WDTIE (WDT interval interrupt enable)
bis.b   #0x01, &IE1             ; enable WDT interrupt
```

Or using the predefined bit (you can define it yourself or add to defs):

```asm
.equ    WDTIE,  0x01
bis.b   #WDTIE, &IE1
```

Then enable global interrupts:

```asm
bis.w   #GIE, SR                ; or EINT instruction
```

---

## Writing the WDT ISR

The WDT interrupt vector is at address **0xFFF6**.

```asm
;----------------------------------------------------------------------
; WDT_ISR — fires every ~32ms in interval mode
;----------------------------------------------------------------------
WDT_ISR:
        xor.b   #LED1, &P1OUT   ; toggle LED every 32ms

        ; No need to clear WDTIFG — hardware clears it automatically
        ; when the ISR vector is acknowledged (for IE1/IFG1 based flags)
        reti                    ; return from interrupt

        ; Interrupt vector table
        .section ".vectors","ax",@progbits
        .org    0xFFF6
        .word   WDT_ISR         ; WDT interval interrupt
        .org    0xFFFE
        .word   main            ; Reset vector
```

---

## Main Loop with WDT ISR

Once the ISR is set up, `main` can do nothing (or sleep):

```asm
main:
        mov.w   #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL  ; interval mode
        bis.b   #LED1, &P1DIR
        bis.b   #0x01, &IE1     ; enable WDT interrupt
        bis.w   #GIE, SR        ; global interrupts on

        ; Enter Low Power Mode 0: CPU off, SMCLK still runs for WDT
main_loop:
        bis.w   #(GIE|CPUOFF), SR   ; LPM0 — wait for interrupt
        nop                          ; required after LPM entry
        jmp     main_loop
```

The CPU sleeps.  Every 32ms the WDT fires, the ISR runs (toggling LED), then the
CPU goes back to sleep.  Power consumption drops dramatically compared to a
spinning main loop.

---

## Generating Longer Periods

32ms is short.  To get 1Hz (1000ms) from 32ms ticks, count ticks in the ISR:

```asm
; In RAM:
tick_count: .skip 2    ; 16-bit tick counter (put in .data or .bss)

WDT_ISR:
        push    R15
        mov.w   &tick_count, R15
        inc.w   R15             ; count += 1
        mov.w   R15, &tick_count
        cmp.w   #31, R15        ; 31 × 32ms ≈ 992ms (close enough to 1Hz)
        jlo     wdt_done
        clr.w   &tick_count     ; reset counter
        xor.b   #LED1, &P1OUT   ; toggle LED every ~1s
wdt_done:
        pop     R15
        reti
```

---

## IFG1 and Manual Flag Clearing

Unlike Timer_A (which auto-clears CCIFG on TAIV read), the WDT interval flag in
`IFG1` bit 0 (`WDTIFG`) is automatically cleared when the ISR vector is fetched.
You do **not** need to clear it manually in the ISR.

---

## Summary

| Step | Code |
|------|------|
| Set interval mode | `mov.w #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL` |
| Enable WDT IRQ | `bis.b #0x01, &IE1` |
| Enable global IRQ | `bis.w #GIE, SR` |
| Write ISR | `WDT_ISR: ... reti` |
| Place vector | `.org 0xFFF6 / .word WDT_ISR` |
| Sleep in main | `bis.w #(GIE|CPUOFF), SR` |

Now open `examples/wdt_demo.s` to see this in a complete, working program.
