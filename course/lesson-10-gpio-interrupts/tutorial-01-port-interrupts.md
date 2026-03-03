# Tutorial 10-1 · Port 1 Interrupts

## Port 1 Interrupt Registers

Port 1 has three interrupt-specific registers (all 8-bit):

| Register | Address | Function |
|----------|---------|----------|
| P1IFG | 0x0023 | Interrupt flag: bit set when edge detected |
| P1IES | 0x0024 | Edge select: 0=rising, 1=falling |
| P1IE | 0x0025 | Interrupt enable: 1=enabled for this pin |

All Port 1 pins share **one interrupt vector** at `0xFFE4`.  Your ISR must check
P1IFG to determine which pin triggered the interrupt.

---

## Configuration Steps

```asm
; 1. Configure pin as input (default, but explicit is better)
bic.b   #BTN, &P1DIR        ; P1.3 = input

; 2. Enable pull-up resistor (so pin has a defined level when not pressed)
bis.b   #BTN, &P1REN        ; enable pull resistor
bis.b   #BTN, &P1OUT        ; P1OUT selects pull-up (1) or pull-down (0)

; 3. Select falling edge (button active-low: pressed = 3.3V → 0V = falling)
bis.b   #BTN, &P1IES        ; 1 = falling edge trigger

; 4. Clear any stale flag (important! edge may have been detected
;    during the configuration sequence above)
bic.b   #BTN, &P1IFG        ; clear flag

; 5. Enable interrupt for this pin
bis.b   #BTN, &P1IE         ; enable PORT1 interrupt for P1.3

; 6. Enable global interrupts (in main, after all setup)
bis.w   #GIE, SR
```

---

## Writing the PORT1 ISR

```asm
PORT1_ISR:
        ; Which pin triggered?  Check P1IFG
        bit.b   #BTN, &P1IFG
        jz      port1_done          ; not our button

        ; Clear the flag FIRST (prevents re-triggering)
        bic.b   #BTN, &P1IFG

        ; Do the work
        xor.b   #LED1, &P1OUT

port1_done:
        reti
```

**Critical**: clear P1IFG **inside the ISR** before returning. If you don't, the
ISR fires again immediately after RETI.

---

## Edge Select (P1IES)

| P1IES bit | Trigger |
|-----------|---------|
| 0 | Rising edge (LOW → HIGH) |
| 1 | **Falling edge** (HIGH → LOW) ← button press (active-low) |

You can change P1IES at runtime to alternate between detecting press and release
events.

---

## Vector Table Entry

```asm
        .section ".vectors","ax",@progbits
        .org    0xFFE4
        .word   PORT1_ISR
        .org    0xFFFE
        .word   main
```

---

## Multiple Pins on Port 1

If multiple pins on Port 1 have interrupts enabled, they all share the PORT1
vector.  Your ISR must check each P1IFG bit:

```asm
PORT1_ISR:
        ; Check P1.3 (button)
        bit.b   #BIT3, &P1IFG
        jz      check_p1_0
        bic.b   #BIT3, &P1IFG
        ; handle button
        jmp     port1_done

check_p1_0:
        bit.b   #BIT0, &P1IFG
        jz      port1_done
        bic.b   #BIT0, &P1IFG
        ; handle P1.0

port1_done:
        reti
```

---

## Complete Example Skeleton

```asm
main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; LED1 output
        bis.b   #LED1, &P1DIR

        ; Button S2 — falling edge interrupt
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES        ; falling edge
        bic.b   #BTN, &P1IFG        ; clear stale flag
        bis.b   #BTN, &P1IE         ; enable interrupt
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR   ; LPM0
        nop
        jmp     main_loop

PORT1_ISR:
        bic.b   #BTN, &P1IFG
        xor.b   #LED1, &P1OUT
        reti

        .section ".vectors","ax",@progbits
        .org    0xFFE4
        .word   PORT1_ISR
        .org    0xFFFE
        .word   main
```

Next: Tutorial 02 covers button bounce and how to handle it.
