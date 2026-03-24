# Tutorial 01 — Interrupts

## The Problem with Polling

In Lesson 04 your main loop spent all its time doing this:

```asm
main_loop:
    bit.w   #TAIFG, &TACTL   ; is the tick ready?
    jz      main_loop         ; no — spin
    bic.w   #TAIFG, &TACTL   ; yes — clear and continue
    ...
    jmp     main_loop
```

The CPU is running flat-out, checking the same register thousands of times
per millisecond waiting for a flag to change. This has two costs:

1. **Power:** the CPU draws full current even while doing nothing useful
2. **Opportunity:** the CPU can't sleep or respond to anything else while spinning

Interrupts invert the model. Instead of the CPU asking "is anything ready yet?"
on every cycle, the hardware tells the CPU "something happened — deal with it."
The CPU can spend the intervening time asleep.

---

## How MSP430 Interrupts Work

When an interrupt source fires (timer overflow, button press, UART byte received):

1. Hardware finishes the current instruction
2. The **program counter (PC)** and **status register (SR)** are pushed onto the stack
3. **GIE** (global interrupt enable, SR bit 3) is automatically cleared — no nested interrupts
4. The CPU reads the **interrupt vector** for that source from the vector table
5. PC jumps to the ISR at that address
6. Your ISR code runs
7. `reti` pops SR and PC from the stack — execution resumes where it was interrupted

The vector table lives at the top of flash (0xFFE0–0xFFFE). Each 2-byte slot
holds the address of the ISR for that source, or 0 if unused.

---

## Timer_A CC0 Interrupt

In Lesson 04 you used TAIFG (the overflow flag in TACTL). There is a separate,
cleaner interrupt for up-mode: the **CC0 interrupt**, which fires when TAR
reaches TACCR0 — the same moment TAIFG would be set, but handled in hardware.

**To enable it:** set the `CCIE` bit in `TACCTL0` before starting the timer.

```asm
mov.w   #TICK_PERIOD, &TACCR0
mov.w   #CCIE, &TACCTL0              ; enable CC0 interrupt
mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL
```

**Vector address:** `0xFFF4` — position 10 in the table (counting from 0xFFE0).

---

## ISR Anatomy

An ISR looks almost identical to a subroutine, with one difference: it ends
with `reti` instead of `ret`.

```asm
timer_isr:
    ; do work here — decrement counters, toggle LEDs, etc.
    reti                    ; restore SR and PC, resume interrupted code
```

`ret` pops only PC. `reti` pops both SR and PC — it fully restores the CPU
state to what it was before the interrupt. This is essential: if SR had GIE
set and CPUOFF set (CPU was sleeping), `reti` restores both, putting the CPU
back to sleep after the ISR finishes.

**Registers:** the ISR shares all registers with the rest of your program.
R4–R15 are not automatically saved. If your ISR uses a register that the
interrupted code also uses, you must push and pop it:

```asm
timer_isr:
    push    R5              ; save R5 if ISR clobbers it
    ; ... use R5 ...
    pop     R5              ; restore
    reti
```

For the exercises in this lesson all state lives in dedicated registers
(R6, R7, R8…) and the ISR is the only code that touches them, so no
push/pop is needed.

---

## Enabling Interrupts: GIE

The vector table and CCIE only arm the interrupt source. For any interrupt
to actually fire, **GIE** (Global Interrupt Enable, SR bit 3) must be set.

```asm
bis.w   #GIE, SR            ; enable interrupts (CPU keeps running)
```

In practice you set GIE at the same time you enter LPM0 — see Tutorial 02.
Never enable GIE before your interrupt sources are configured, or a stale
flag could trigger an ISR before your registers are initialized.

---

## Interrupt Vector Table — Full Map

```asm
    .section ".vectors","ax",@progbits
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   0           ; 0xFFE4  Port 1
    .word   0           ; 0xFFE6  Port 2 / unused
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI_A0/B0 RX
    .word   0           ; 0xFFEE  USCI_A0/B0 TX
    .word   0           ; 0xFFF0  unused
    .word   0           ; 0xFFF2  Timer_A overflow (TAIE/TAIFG)
    .word   timer_isr   ; 0xFFF4  Timer_A CC0  ← this lesson
    .word   0           ; 0xFFF6  WDT interval
    .word   0           ; 0xFFF8  unused
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
```

Replace `0` with your ISR label for each source you use. Only one ISR
can occupy each slot — if you have multiple sources, each gets its own slot.

---

## Common Mistakes

**Forgetting CCIE:** the CC0 interrupt never fires. The timer runs but
nothing happens. Symptom: code after `bis.w #(GIE|CPUOFF), SR` is never reached,
program hangs silently.

**Using `ret` instead of `reti`:** SR is not restored. If the CPU was in LPM0,
it doesn't go back to sleep — it runs off the end of the ISR into whatever
comes next in memory.

**Writing the ISR address in the wrong vector slot:** count carefully from
0xFFE0. Off-by-one means the wrong ISR fires (or none does).

**Enabling GIE before registers are initialized:** an immediately-pending
flag (TAIFG left set from a previous run) can trigger the ISR before R6 is
loaded, causing the counter to decrement from 0 → 0xFFFF.
