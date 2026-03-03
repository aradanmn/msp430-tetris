# Tutorial 04-2 · PUSH, POP, and Register Discipline

## The Problem with Scratch Registers

Consider this subroutine that blinks LED1 three times:

```asm
blink3:
        mov.w   #3, R12         ; loop counter in R12
blink3_loop:
        xor.b   #LED1, &P1OUT
        mov.w   #300, R14
        call    #delay          ; ← delay uses R14 and R15!
        dec.w   R12
        jnz     blink3_loop
        ret
```

**Bug**: `delay` uses R14 as its argument (passed by the caller) and R15 as a
scratch register.  By the time `delay` returns, R14 has been destroyed.  If
`blink3`'s caller was using R14 for something important, that value is now gone.

This is the **register clobbering** problem.

---

## PUSH and POP

`PUSH Rx` saves a register to the stack:

```
SP -= 2
MEM[SP] = Rx
```

`POP Rx` restores it:

```
Rx = MEM[SP]
SP += 2
```

**Critical rule**: every `PUSH` must be matched by exactly one `POP` before
`RET`, or the return address will be wrong.

---

## Callee-Save Convention

A subroutine that uses registers R4–R10 should save them on entry and restore
them on exit.  R11–R15 are considered "scratch" (the caller expects them to be
destroyed).

```asm
;----------------------------------------------------------------------
; my_sub — example of proper register discipline
; Clobbers: R12 (return value), R13, R14, R15 (scratch — expected)
; Saves/restores: R4, R5 (callee-saved)
;----------------------------------------------------------------------
my_sub:
        push    R4              ; save callee-saved registers
        push    R5

        ; ... use R4 and R5 freely ...

        pop     R5              ; restore in REVERSE order
        pop     R4
        ret
```

**Pop in reverse order**: you push R4 first (deeper on stack), then R5 on top.
Pop takes the top first, so pop R5, then R4.

---

## Fixed blink3 With Register Save

```asm
blink3:
        push    R12             ; save caller's R12 (we use it as loop counter)
        push    R14             ; save caller's R14 (delay clobbers it)

        mov.w   #3, R12
blink3_loop:
        xor.b   #LED1, &P1OUT
        mov.w   #300, R14
        call    #delay
        dec.w   R12
        jnz     blink3_loop

        pop     R14             ; restore in reverse order
        pop     R12
        ret
```

Wait — should `blink3` save R12?  R12 is a *scratch* register (it is used for
arguments and return values).  The **caller** should save R12 if it cares about
its value.  So the answer depends on context.  In our course, document your
clobbers clearly and match your PUSHes.

---

## Stack Diagram for a Nested Call

```
main                    blink3              delay
────────────────────────────────────────────────────────
call #blink3
  SP→ [ret_to_main]
                        push R12
                          SP→ [R12]
                              [ret_to_main]
                        push R14
                          SP→ [R14]
                              [R12]
                              [ret_to_main]
                        call #delay
                          SP→ [ret_to_blink3]
                                [R14]
                                [R12]
                                [ret_to_main]
                                                delay body runs
                        ret (from delay)
                          SP→ [R14]
                              [R12]
                              [ret_to_main]
                        pop R14
                        pop R12
                          SP→ [ret_to_main]
                        ret (from blink3)
  SP→ (restored)
```

Every `CALL` adds one word to the stack; every `RET` removes one word. Every
`PUSH` adds one word; every `POP` removes one word. The stack must balance to
zero before `RET`.

---

## The Stack in MSP430 Memory

The MSP430G2552 stack lives in RAM:

```
0x03FF  ← Top of RAM
0x03FE  ← Initial SP (SP points here after reset)
...     ← stack grows downward (to lower addresses)
0x0200  ← Bottom of RAM
```

If your stack grows into your variables (stack overflow), behavior is undefined
— often a crash or silent corruption.  With only 512 bytes of RAM, keep
subroutine nesting depth shallow.

---

## Quick Reference

| Instruction | Effect on SP | Effect on memory / register |
|-------------|-------------|-----------------------------|
| `PUSH Rx`   | SP -= 2     | MEM[SP] = Rx |
| `POP Rx`    | SP += 2     | Rx = MEM[SP-2] (value that was there) |
| `CALL #sub` | SP -= 2     | MEM[SP] = next PC; PC = sub |
| `RET`       | SP += 2     | PC = MEM[SP-2] |

---

## Next Steps

Now open `examples/subroutines.s` to see all three patterns in a working
program, then tackle the exercises.
