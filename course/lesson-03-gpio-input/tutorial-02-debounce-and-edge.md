# Tutorial 02 — Debounce and Edge Detection

## Why Buttons Lie

A mechanical button doesn't produce a clean HIGH→LOW transition when pressed.
The metal contacts bounce — rapidly making and breaking contact for a few
milliseconds before settling. The MCU sees this as dozens of rapid
press/release events in the time a human experiences as a single press.

```
Ideal:   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾____________________________‾‾‾‾‾‾‾‾
                         press                       release

Reality: ‾‾‾‾‾‾‾‾‾‾‾‾‾‾_‾__‾_______________________‾_‾‾‾‾‾‾
                        bouncing   settled
                        ~5–20ms
```

At 1 MHz the CPU polls millions of times per second — fast enough to catch
every bounce individually. Without debounce, a single button press can register
as 10–30 presses.

---

## Software Debounce

The simplest fix: after you detect the first falling edge (HIGH→LOW), wait long
enough for the bouncing to stop before acting on it — typically 20ms.

```asm
wait_press:
    bit.b   #BTN, &P1IN
    jnz     wait_press          ; released → keep polling

    ; --- first LOW detected — wait for bouncing to settle ---
    mov.w   #20, R12
    call    #delay_ms           ; 20ms debounce window

    ; --- re-read: is the button still pressed after 20ms? ---
    bit.b   #BTN, &P1IN
    jnz     wait_press          ; was a glitch → start over

    ; --- genuine press confirmed ---
```

The second read is the key step. If the LOW was a noise spike, the pin will
be HIGH again after 20ms and you discard it. If it's still LOW after 20ms,
the contacts have settled — real press.

---

## Debounce on Release Too

The release edge also bounces. If your edge-detect loop goes straight to
`wait_press` after a release, it can immediately re-trigger on bounce:

```asm
wait_release:
    bit.b   #BTN, &P1IN
    jz      wait_release        ; still pressed → wait

    ; --- first HIGH detected on release ---
    mov.w   #20, R12
    call    #delay_ms           ; let release settle

    ; --- re-read ---
    bit.b   #BTN, &P1IN
    jz      wait_release        ; was a glitch → start over

    ; --- genuine release confirmed ---
    jmp     wait_press
```

---

## Full Debounced Edge-Detect Pattern

Putting it together — toggle LED once per genuine button press:

```asm
wait_press:
    bit.b   #BTN, &P1IN
    jnz     wait_press

debounce_press:
    mov.w   #20, R12
    call    #delay_ms
    bit.b   #BTN, &P1IN
    jnz     wait_press          ; glitch → retry

    ; --- confirmed press: act here ---
    xor.b   #LED1, &P1OUT

wait_release:
    bit.b   #BTN, &P1IN
    jz      wait_release

debounce_release:
    mov.w   #20, R12
    call    #delay_ms
    bit.b   #BTN, &P1IN
    jz      wait_release        ; glitch → retry

    ; --- confirmed release: ready for next press ---
    jmp     wait_press
```

This is the template for virtually every button interaction in the course.
Commit the structure to memory.

---

## Naming the Pattern as a Subroutine

For a game with multiple places that need button reads, wrap the wait-and-debounce
into a subroutine. A clean interface: call it, it returns only after a complete
press+release cycle.

```asm
;----------------------------------------------------------------------
; wait_button_press — wait for one complete debounced press + release
;
; No arguments. No return value.
; Clobbers: R12, R13 (via delay_ms)
;----------------------------------------------------------------------
wait_button_press:
.Lwbp_wait_press:
    bit.b   #BTN, &P1IN
    jnz     .Lwbp_wait_press

    mov.w   #20, R12
    call    #delay_ms
    bit.b   #BTN, &P1IN
    jnz     .Lwbp_wait_press

.Lwbp_wait_release:
    bit.b   #BTN, &P1IN
    jz      .Lwbp_wait_release

    mov.w   #20, R12
    call    #delay_ms
    bit.b   #BTN, &P1IN
    jz      .Lwbp_wait_release

    ret
```

Caller:

```asm
    call    #wait_button_press  ; blocks until press+release done
    ; now advance game state, increment counter, etc.
```

---

## What About Interrupts?

The MSP430 can trigger an interrupt on a pin-change edge — you don't need to
poll at all. That's cleaner for real applications, especially combined with
low-power modes. You'll do that in Lesson 07. For now, polling is the right
starting point: it's simpler to reason about and debug.

---

## Summary

| Concept | Technique |
|---------|-----------|
| Detect press | Poll `bit.b #BTN, &P1IN` until `jz` (bit = 0) |
| Confirm (not bounce) | `delay_ms 20` then re-read |
| Detect release | Poll `bit.b #BTN, &P1IN` until `jnz` (bit = 1) |
| Level-sensitive | Check pin every loop pass, no debounce needed |
| Edge-sensitive | Detect first transition → debounce → wait for release |
| Full press subroutine | Returns only after confirmed press+release |
