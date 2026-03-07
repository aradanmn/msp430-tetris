# Tutorial 11-1 · Timer_A CC0 Interrupt

## CC0 vs CC1/CC2 Interrupts

Timer_A has two interrupt vectors:

| Vector | Address | Source |
|--------|---------|--------|
| Timer_A CC0 | 0xFFF4 | TACCR0 match only |
| Timer_A CC1/2/overflow | 0xFFF2 | CC1, CC2, or TAR overflow |

The CC0 vector has **higher priority** and its own dedicated vector. The CC1/CC2
vector is shared — you must read `TAIV` to determine which sub-source fired.

For a 1ms system tick, we use **CC0 exclusively** — the simplest and most common
pattern.

---

## Generating a 1ms Tick

With SMCLK = 1MHz and no divider (ID_0):
- 1ms = 1000 ticks → TACCR0 = **999**

```asm
; 1ms tick using Timer_A CC0 interrupt
mov.w   #999, &TACCR0                       ; 1ms period
mov.w   #CCIE, &TACCTL0                     ; enable CC0 interrupt
mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL ; SMCLK, Up mode
```

No divider needed — 1MHz SMCLK can count to 999 in exactly 1ms.

---

## The CC0 ISR

```asm
;----------------------------------------------------------------------
; TIMERA_CC0_ISR — fires every 1ms
; Increments a global tick counter in RAM
;----------------------------------------------------------------------
TIMERA_CC0_ISR:
        ; CCIFG is automatically cleared when the CC0 vector is fetched
        ; (unlike WDT where IFG1.WDTIFG must be cleared by software)

        push    R15
        inc.w   &ms_tick            ; increment tick counter
        pop     R15
        reti

        .section ".vectors","ax",@progbits
        .org    0xFFF4
        .word   TIMERA_CC0_ISR
```

Note: **CCIFG is auto-cleared** for the CC0 vector.  You do not need to clear
TACCTL0.CCIFG manually.

---

## Using the Tick Counter

In your `.data` section:

```asm
        .data
ms_tick:    .word 0     ; millisecond counter (16-bit, wraps at 65535)
```

In the main loop, compare against timestamps:

```asm
        .data
last_led:   .word 0     ; ms_tick value at last LED toggle

        .text
main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; sleep
        nop

        ; Check if 500ms have elapsed since last toggle
        mov.w   &ms_tick, R12
        sub.w   &last_led, R12     ; elapsed = now - last
        cmp.w   #500, R12
        jlo     main_loop          ; not yet

        mov.w   &ms_tick, &last_led  ; update timestamp
        xor.b   #LED1, &P1OUT
        jmp     main_loop
```

This is a **non-blocking check** — the CPU is asleep most of the time and wakes
for 1µs every millisecond to increment the counter.

---

## 16-bit Wrap-around

`ms_tick` wraps after 65535ms ≈ 65.5 seconds.  For programs running longer than
that, use a 32-bit counter (two 16-bit registers).

For simple exercises ≤ 60 seconds, 16-bit is sufficient.

---

## Key Points

- CC0 ISR is one of the highest priority interrupts (vector 0xFFF4)
- CCIFG auto-clears on CC0 vector fetch — no manual clear needed
- The tick counter is the simplest form of an RTOS kernel
- Keep the ISR body to 3–5 instructions for minimal jitter
