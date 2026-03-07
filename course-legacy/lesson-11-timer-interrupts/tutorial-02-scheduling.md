# Tutorial 11-2 · Tick-Based Scheduling

## The Scheduler Pattern

With a 1ms tick counter, main becomes a simple scheduler:

```
main_loop:
    sleep (LPM0)
    wake every 1ms (CC0 ISR increments tick)
    check each task: has its interval elapsed?
    if yes: run task, update task's last-run timestamp
    go back to sleep
```

---

## Multi-Rate Task Example

Three tasks at different rates:

```asm
        .data
ms_tick:    .word 0
t_led1:     .word 0     ; last time LED1 ran
t_led2:     .word 0     ; last time LED2 ran
t_heartbeat:.word 0     ; last time heartbeat ran

; Task periods (milliseconds)
.equ    PERIOD_LED1,    500     ; 500ms = 2Hz blink
.equ    PERIOD_LED2,    333     ; 333ms = 3Hz blink
.equ    PERIOD_HEART,  1000    ; 1s heartbeat

        .text
main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        mov.w   &ms_tick, R12

        ; Check LED1 task
        mov.w   R12, R13
        sub.w   &t_led1, R13
        cmp.w   #PERIOD_LED1, R13
        jlo     check_led2
        mov.w   R12, &t_led1
        xor.b   #LED1, &P1OUT

check_led2:
        mov.w   R12, R13
        sub.w   &t_led2, R13
        cmp.w   #PERIOD_LED2, R13
        jlo     check_heart
        mov.w   R12, &t_led2
        xor.b   #LED2, &P1OUT

check_heart:
        ; ... similar ...

        jmp     main_loop
```

---

## Subroutine-Based Scheduler

For cleaner code, put each task into a subroutine:

```asm
;----------------------------------------------------------------------
; run_if_due — run task if its period has elapsed
; Input: R12 = current ms_tick
;        R13 = period (ms)
;        R14 = address of last-run timestamp variable
; Output: Z flag set if task did NOT run, clear if it ran
; Clobbers: R13, R15
;----------------------------------------------------------------------
run_if_due:
        mov.w   R12, R15
        sub.w   @R14, R15        ; elapsed = now - last
        cmp.w   R13, R15        ; elapsed >= period?
        jlo     not_due
        mov.w   R12, 0(R14)     ; update last timestamp
        clr.w   R15             ; Z=0 (task ran)
        ret
not_due:
        mov.w   #1, R15         ; Z=0 but we return non-zero... actually
        ; Caller checks return value: 0=ran, 1=not due
        ret
```

(In practice, using a flag or return value is cleaner than relying on status
bits here.  Demonstrate what works for your program.)

---

## Waking the CPU Only When Needed

The CC0 ISR wakes the CPU every 1ms.  If all tasks check timestamps and none
run, the CPU immediately goes back to sleep.  For a 500ms task, the CPU wakes
499 times for nothing.

**Optimization:** have the ISR check if any task is due and only wake main when
there's actually work:

```asm
TIMERA_CC0_ISR:
        push    R15
        inc.w   &ms_tick

        ; Check if any task is due (simplified: check LED1)
        mov.w   &ms_tick, R15
        sub.w   &t_led1, R15
        cmp.w   #500, R15
        jlo     cc0_sleep       ; not due, don't wake main
        bic.w   #CPUOFF, 0(SP) ; wake main
cc0_sleep:
        pop     R15
        reti
```

This reduces main's wake frequency dramatically — from every 1ms to only when a
task is actually due.

---

## Summary

| Concept | Implementation |
|---------|---------------|
| System tick | CC0 ISR increments `ms_tick` every 1ms |
| Task scheduling | Main checks `ms_tick - last_run >= period` |
| Multi-rate tasks | Each task has its own `last_run` variable |
| Power efficiency | ISR wakes main only when a task is due |

This is the exact pattern used in the capstone Smart Monitor project.
