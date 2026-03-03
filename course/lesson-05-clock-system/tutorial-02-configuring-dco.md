# Configuring DCO Frequency

## Why It Matters

Everything that depends on timing must know the clock speed:

- **Software delay loops** count clock cycles — wrong speed means wrong delay
- **UART baud rate divider** is computed as `fSMCLK / baud_rate`; at the wrong
  frequency the serial data is garbled
- **Timer_A period** is `TACCR0 / fSMCLK`; off-frequency means wrong interrupt
  rate
- **ADC10 sample timing** is derived from SMCLK or MCLK dividers

If your clock is 2x faster than expected, all delays run 2x too fast. UART will
fail. Timer periods will be half what you calculated. Always calibrate the DCO
before doing anything timing-sensitive.

## Configuration Sequence

The sequence matters. You must clear DCOCTL before changing BCSCTL1's RSEL
field. If you load BCSCTL1 first, the DCO briefly runs at the new range with the
old DCOCTL fine-tune value, which could produce a momentary out-of-spec
frequency.

```asm
set_1mhz:
    ; 1. Clear DCO control register FIRST
    ;    (avoids a glitch when changing frequency range)
    clr.b   &DCOCTL

    ; 2. Set BCSCTL1 from calibration constant at 0x10FF
    ;    This sets the RSEL (range select) bits for the 1 MHz range
    mov.b   &0x10FF, &BCSCTL1   ; CALBC1_1MHZ

    ; 3. Set DCOCTL from calibration constant at 0x10FE
    ;    This fine-tunes the frequency within the range
    mov.b   &0x10FE, &DCOCTL    ; CALDCO_1MHZ

    ; Now MCLK = SMCLK = 1.000 MHz (±1%)
    ret
```

## Configuring for 8 MHz

```asm
set_8mhz:
    clr.b   &DCOCTL
    mov.b   &0x10FD, &BCSCTL1   ; CALBC1_8MHZ
    mov.b   &0x10F9, &DCOCTL    ; CALDCO_8MHZ
    ; Now MCLK = SMCLK = 8.000 MHz (±1%)
    ret
```

## Configuring for 16 MHz

```asm
set_16mhz:
    clr.b   &DCOCTL
    mov.b   &0x10FB, &BCSCTL1   ; CALBC1_16MHZ
    mov.b   &0x10F7, &DCOCTL    ; CALDCO_16MHZ
    ; Now MCLK = SMCLK = 16.000 MHz (±1%)
    ret
```

## Effect on Software Delay Loops

A simple delay loop has a fixed number of cycles per iteration. At 1 MHz, one
cycle takes 1 microsecond. At 8 MHz, one cycle takes 0.125 microseconds.

Consider a loop with 3 cycles per iteration (decrement + compare + branch):

```asm
delay:
    mov.w   #COUNT, R5    ; load iteration count
delay_loop:
    dec.w   R5            ; 1 cycle
    jnz     delay_loop    ; 2 cycles (taken branch)
    ret
```

At 1 MHz (1 us/cycle): delay = COUNT × 3 us At 8 MHz (0.125 us/cycle): delay =
COUNT × 0.375 us = COUNT × 3/8 us

| Clock | COUNT for ~100ms |
|-------|-----------------|
| 1 MHz | 33,333 |
| 8 MHz | 266,667 — does NOT fit in 16 bits (max 65,535)! |

For clocks above about 5 MHz you cannot achieve 100ms with a single 16-bit
counter. Use nested loops instead.

## Nested Loop for Long Delays at 8 MHz

At 8 MHz, counting 100ms requires 800,000 cycles / 3 cycles per iteration =
266,667 iterations. This exceeds the 16-bit maximum of 65,535. Use an outer and
inner loop:

```asm
; 100ms at 8 MHz using nested loops
; Strategy: outer loop × inner loop × 3 cycles = 800,000 cycles
; Choose: outer=10, inner=26667 → 10 × 26667 × 3 = 800,010 cycles ≈ 100ms
delay_100ms_8mhz:
    mov.w   #10, R14            ; outer loop count
outer_loop:
    mov.w   #26667, R15         ; inner loop count (10ms worth)
inner_loop:
    dec.w   R15                 ; 1 cycle
    jnz     inner_loop          ; 2 cycles
    dec.w   R14                 ; 1 cycle (overhead, small)
    jnz     outer_loop          ; 2 cycles (overhead, small)
    ret
```

The overhead from the outer loop is small (3 cycles × 10 = 30 cycles out of
800,010).

## Simpler Approach: Use the Same Routine, Scale the Count

If your delay routine accepts a count parameter in R12, you can call it with
different counts for different clock speeds. Document clearly what clock speed a
given count assumes.

```asm
; Generic delay: R12 = iteration count, ~3 cycles/iter at no divider
delay_iters:
    dec.w   R12
    jnz     delay_iters
    ret

; At 1 MHz: call with 33333 for ~100ms
; At 8 MHz: call with 26667 for ~10ms (then call 10 times for 100ms)
```

## Checking for Invalid Calibration

If the chip has undergone a mass erase or the Info Flash was accidentally
cleared, the calibration constants read back as 0xFF. Loading 0xFF into BCSCTL1
would set an invalid configuration.

```asm
; Safety check — detect erased calibration data
mov.b   &0x10FF, R4         ; read CALBC1_1MHZ
cmp.b   #0xFF, R4
jz      cal_invalid          ; calibration erased! fallback needed
mov.b   R4, &BCSCTL1        ; safe to use
mov.b   &0x10FE, &DCOCTL    ; CALDCO_1MHZ
jmp     cal_done

cal_invalid:
    ; Calibration was erased — use a safe default
    ; DCO at reset is approximately 1.1 MHz but imprecise
    ; For production code: halt and signal error
    ; For development: continue at imprecise reset frequency
    nop                      ; or set known-safe register values

cal_done:
```

In the course examples we skip this check for brevity, but real products should
always validate calibration data before using it.

## Summary Checklist

When configuring the DCO:

1. Stop or service the watchdog timer first
2. `clr.b &DCOCTL` — clear before changing range
3. Load BCSCTL1 from calibration address
4. Load DCOCTL from calibration address
5. Update any delay loop counts that depend on clock speed
6. Update Timer_A TACCR0 values if already configured
7. Update UART baud rate divider if already configured
