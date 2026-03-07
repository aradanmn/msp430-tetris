# Tutorial 04-1 · CALL and RET

## The Problem with JMP

In Lesson 02 you wrote a delay loop and jumped into it with `JMP`. That works
once, but what if you need a delay in five different places? You'd have to copy
the loop five times — messy and wasteful.

**Subroutines** (also called functions or procedures) solve this: write the code
once, call it from anywhere.

---

## The CALL Instruction

```asm
call    #my_sub         ; jump to my_sub, remembering where to return
```

`CALL` does two things atomically:

1. **Pushes the return address** (the address of the *next* instruction) onto
   the stack
2. **Jumps** to the target address

On the MSP430, addresses are 16-bit words, so pushing the return address
decrements SP by 2 before storing.

```
Before CALL:                After CALL:
  SP → [other stuff]          SP → [return addr]  ← SP decremented by 2
                                    [other stuff]
```

---

## The RET Instruction

```asm
ret                     ; pop return address from stack and jump to it
```

`RET` is exactly `POP PC`:

1. Reads the 16-bit word at `MEM[SP]` (the return address)
2. Increments SP by 2
3. Jumps to that address (by writing it to PC/R0)

---

## Your First Subroutine

```asm
;----------------------------------------------------------------------
; delay — burns CPU cycles as a software delay
; Input:  R14 = outer loop count (each count ≈ 1000 inner cycles)
; Output: none
; Clobbers: R14, R15
;----------------------------------------------------------------------
delay:
        mov.w   #1000, R15      ; inner loop count
delay_inner:
        dec.w   R15             ; R15 -= 1
        jnz     delay_inner     ; loop until 0
        dec.w   R14             ; outer count -= 1
        jnz     delay           ; repeat
        ret                     ; done — jump back to caller
```

Calling it from `main`:

```asm
main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #LED1, &P1DIR

loop:
        xor.b   #LED1, &P1OUT   ; toggle LED1
        mov.w   #500, R14       ; about 500ms at 1MHz
        call    #delay          ; burn time
        jmp     loop
```

---

## Passing Arguments

The MSP430-GCC convention (which we follow) uses registers **R12–R15** for
function arguments (first arg in R12, second in R13, etc.) and **R12** for the
return value.

```
R12  = first argument  / return value
R13  = second argument
R14  = third argument
R15  = fourth argument (or scratch)
```

You do **not** have to follow this convention in hand-written assembly, but it
is good practice — especially if you ever mix C and assembly.

---

## A Subroutine that Returns a Value

```asm
;----------------------------------------------------------------------
; double — returns R12 × 2 in R12
; Input:  R12 = value
; Output: R12 = value × 2
;----------------------------------------------------------------------
double:
        add.w   R12, R12        ; R12 = R12 + R12
        ret
```

Calling it:

```asm
        mov.w   #7, R12
        call    #double
        ; R12 now contains 14
```

---

## What Happens Step by Step

Assume `main` is at `0xC000` and `double` is at `0xC020`.

```
PC=0xC000  mov.w #7, R12           ; R12 = 7
PC=0xC004  call  #double           ; SP-=2, MEM[SP]=0xC006, PC=0xC020
PC=0xC020  add.w R12, R12          ; R12 = 14
PC=0xC022  ret                     ; PC = MEM[SP] = 0xC006, SP+=2
PC=0xC006  (next instruction)      ; execution resumes here
```

The key insight: **CALL saves the address of the next instruction** (0xC006),
not the address of `CALL` itself (0xC004).

---

## Common Mistakes

| Mistake | Symptom |
|---------|---------|
| Missing `ret` | Program runs off the end of the subroutine into garbage |
| `jmp` instead of `ret` | Works once, but corrupts stack on repeated calls |
| Unbalanced PUSH/POP | SP points to wrong address, `ret` jumps to garbage |

---

## Next

In Tutorial 02 you will learn how to save registers inside a subroutine using
`PUSH` and `POP`, and how nested calls work.
