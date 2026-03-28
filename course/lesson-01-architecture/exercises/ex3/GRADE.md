# Exercise 3 — SOS Morse Code: Grade Report

**Grade: C+**

## Functionality (Pass/Fail): PARTIAL

The code compiles, runs, and produces a repeating blink pattern — but the pattern is not SOS.

## What Works Well

### 1. Design decision: subroutines

You chose subroutines over inlining — that's the right call. The main loop reads like a sentence:

```asm
main_loop:
    call    #dot
    call    #letter_gap
    call    #dash
    call    #letter_gap
    call    #dot
    call    #word_gap
    jmp     main_loop
```

Clean, readable, maintainable. Good use of `.equ` for timing constants. Comment blocks on each subroutine with input/output documentation is solid practice.

### 2. Defensive LED-off at end of dot

`bic.b #LED1, &P1OUT` at `.Ldot_done` ensures the LED is in a known OFF state regardless of toggle history. That's careful thinking.

## Issues Found

### 1. SOS pattern is wrong — this produces one dot, one dash, one dot (Critical)

The spec in the exercise header states "Inline all 9 flashes" — that 9 is 3 dots + 3 dashes + 3 dots. The README also spells it out:

```
S = · · ·     (3 short flashes)
O = — — —     (3 long flashes)
S = · · ·     (3 short flashes)
```

Your main loop calls `dot` once, then `dash` once, then `dot` once. Each subroutine produces a single flash. So the actual output is:

```
short flash — 450ms gap — long flash — 450ms gap — short flash — 1000ms gap — repeat
```

To produce SOS you need 3 dots per S and 3 dashes per O, with 150ms inter-element gaps within each letter. One approach that preserves your subroutine design:

```asm
main_loop:
    call    #send_S
    call    #letter_gap
    call    #send_O
    call    #letter_gap
    call    #send_S
    call    #word_gap
    jmp     main_loop

send_S:
    call    #dot
    call    #dot
    call    #dot
    ret

send_O:
    call    #dash
    call    #dash
    call    #dash
    ret
```

But that requires `dot` and `dash` to each include their trailing 150ms OFF gap, which brings us to issue 2.

### 2. Dot subroutine is missing the OFF gap

Tracing through `dot` with R4=2:

| Step | R4 | Action |
|------|-----|--------|
| dec  | 1   | not zero — continue |
| xor  |     | LED toggles ON |
| delay |    | wait 150ms |
| jmp  |     | back to top |
| dec  | 0   | zero — jump to done |
| bic  |     | force LED OFF |
| ret  |     | return |

Result: LED ON 150ms, then immediately OFF with no gap. If you called `dot` three times in a row, the dots would blur together with only microseconds between them — visually indistinguishable from one long dash.

Each dot (and dash) needs to include its trailing inter-element gap:

```asm
dot:
    bis.b   #LED1, &P1OUT       ; LED ON
    mov.w   #150, R12
    call    #delay_ms            ; ON for 150ms
    bic.b   #LED1, &P1OUT       ; LED OFF
    mov.w   #150, R12
    call    #delay_ms            ; OFF for 150ms (inter-element gap)
    ret
```

### 3. Dash ON time is 300ms instead of spec's 450ms

The spec states `Dash: LED ON 450 ms`. Your `dash_on` is 300. Standard Morse timing is dash = 3x dot (150 x 3 = 450). At 300ms (2x dot) the dash is still distinguishable from a dot, but it's shorter than standard.

### 4. Minor: R4 used as loop counter

R4 is designated as a persistent ISR register in the project's register convention (`handheld/registers.md`). No ISRs exist in L01 so this doesn't cause a bug now, but it's worth building the habit of using R12-R15 for scratch/temporary values in subroutines.

### 5. delay_ms was provided, not student-written

The clean `delay_ms` in this exercise was provided as boilerplate. Credit for the implementation belongs to the template, not the student.

## Timing Interpretation Note

Your interpretation of "450ms total off" for the letter gap is reasonable — the spec wording is ambiguous. You tested both values on hardware and made a deliberate choice based on what looked better — that's exactly the right approach.

## What To Take Away

The **design** of this program is strong. Subroutines, named constants, clean main loop, documented interfaces — all good instincts. The gap is in **reading the spec carefully** and **tracing execution**. Before calling the code done:

1. Re-read the spec: how many total flashes should one SOS cycle produce?
2. Trace each subroutine: how many times does the LED toggle ON per call?
3. Count the total ON/OFF flashes in one complete main_loop iteration — do you get 3-3-3?

That spec check and manual trace would have caught both the missing repetition and the missing inter-element gap.

## Summary

Good design instincts — subroutines, constants, clean structure, documented interfaces. The core issue is the pattern produces a single dot-dash-dot instead of the 3-3-3 SOS pattern. The clue ("9 flashes") was in the exercise header but was missed. The architecture of the code is sound; with the correct repetition count and inter-element gaps added, this would work.
