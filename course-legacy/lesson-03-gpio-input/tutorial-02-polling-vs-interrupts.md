# Tutorial 02 — Polling vs. Interrupts

## Two Ways to Detect Events

When an external event happens (button press, data arrives, timer fires), the
CPU needs to respond. There are two fundamental approaches:

1. **Polling**: The CPU continuously checks whether the event has occurred.
2. **Interrupt-driven**: The CPU does other work (or sleeps) until the hardware
   signals an event.

---

## Polling

In polling, the CPU loops and repeatedly reads the input register to check for a
change:

```asm
main_loop:
        bit.b   #BTN, &P1IN         ; Check button
        jnz     main_loop           ; Not pressed → keep checking

        ; Button is pressed — handle it
        call    #debounce
        xor.b   #LED1, &P1OUT       ; Toggle LED

        ; Wait for release
wait_release:
        bit.b   #BTN, &P1IN
        jz      wait_release
        call    #debounce

        jmp     main_loop           ; Back to polling
```

**Advantages of polling:**
- Simple to understand and implement
- Predictable timing — you know exactly when the check happens
- No interrupt service routines, no complex state management

**Disadvantages of polling:**
- CPU is fully occupied — it cannot do anything else while polling
- High power consumption — the CPU runs continuously at full speed
- Latency — the response time depends on how fast the loop runs and what other
  code is in the loop

For a simple button-controlled LED where nothing else needs to happen, polling
is perfectly appropriate.

---

## The Complete Polling Pattern with Debounce

The standard pattern used in this course:

```asm
;--- Setup ---
bic.b   #BTN, &P1DIR            ; P1.3 input
bis.b   #BTN, &P1REN            ; Enable pull resistor
bis.b   #BTN, &P1OUT            ; Pull-up

;--- Main loop ---
poll_loop:

        ; 1. Wait for button to be pressed
wait_press:
        bit.b   #BTN, &P1IN         ; Test P1.3
        jnz     wait_press          ; Pin HIGH = not pressed, keep polling

        ; 2. Debounce — wait for bouncing to settle
        call    #debounce

        ; 3. Take action
        xor.b   #LED1, &P1OUT       ; Toggle LED

        ; 4. Wait for button to be released
wait_release:
        bit.b   #BTN, &P1IN
        jz      wait_release        ; Pin LOW = still pressed, wait

        ; 5. Debounce release
        call    #debounce

        jmp     poll_loop

debounce:
        push    R15
        mov.w   #6667, R15          ; ~20ms at 1MHz
db:     dec.w   R15
        jnz     db
        pop     R15
        ret
```

The wait-for-press → debounce → action → wait-for-release → debounce cycle is
the standard polling template for button input.

---

## Why Wait for Release?

Without the wait-for-release step, the main loop returns immediately to
wait-for-press. Since buttons take 50–200ms to fully release, the CPU might
detect the same press several more times before the pin goes HIGH. This causes a
single button press to trigger multiple actions.

Waiting for release (with debounce) ensures the button has fully returned to its
idle state before the next detection cycle begins.

---

## Preview: Interrupt-Driven Input

Polling keeps the CPU busy continuously. For a button-only program, this wastes
power. The MSP430's strength is ultralow-power sleep modes — but the CPU must be
asleep to use them.

An interrupt-driven approach works like this:

1. Configure the GPIO pin to generate an interrupt on a falling edge (P1IES,
   P1IE)
2. Write an interrupt service routine (ISR) at the PORT1_VECTOR address
3. Put the CPU into low-power mode (LPM): `bis.w #LPM3+GIE, &SR`
4. When the button is pressed, the CPU wakes automatically, runs the ISR, then
   sleeps again

The power difference is dramatic: polling at 1MHz draws ~220µA, while LPM3 sleep
draws less than 1µA. For a battery-powered product, this difference means weeks
vs. years of battery life.

Interrupt-driven GPIO input is covered in **Lesson 10**. The polling approach in
this lesson is the prerequisite — understanding polling makes interrupts easier
to learn by contrast.

---

## Why Debounce Delay Works

During a button bounce event, the pin voltage oscillates between HIGH and LOW at
a frequency of roughly 1–10kHz. Each oscillation lasts 100µs–1ms. The total
bounce period is typically 5–20ms.

A 20ms debounce delay means: after detecting the initial press, the CPU ignores
everything for 20ms. During that time, all the bounces occur. After 20ms, the
button has settled into its final stable state (LOW = pressed). The CPU then
reads a clean, stable signal.

The key insight: the debounce delay doesn't need to be exact. 15ms, 20ms, or
30ms all work. Shorter delays (less than ~5ms) risk catching a bounce. Longer
delays (over 100ms) feel sluggish to the user.

---

## The Importance of Release Debounce

Debouncing the release is just as important as debouncing the press:

```
Button press   |¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
PIN voltage:   3.3V                   0V

With bouncing:
               _____|__|___|_____|____|______
               not pressed  bouncing  pressed

Button release |_____________________|¯¯¯¯¯¯¯¯¯|
PIN voltage:   0V                    3.3V

With bouncing:
               ____________________|__|_|_____|
               pressed         bouncing  not pressed
```

If you don't debounce the release, the CPU may re-enter `wait_press` while the
pin is still bouncing and immediately detect another "press" — even though the
user only pressed once.

---

## Testing Button Input with mspdebug

You can verify button wiring and pull-up configuration without flashing a full
program:

```
$ mspdebug rf2500
(mspdebug) prog button.elf
(mspdebug) run
(mspdebug) halt
(mspdebug) md 0x0020 1    ; Read P1IN
```

With no button pressed, P1IN bit 3 should be 1 (0x08 or higher if other pins are
HIGH). Press and hold the button, then halt and read again — bit 3 should be 0.

Alternatively, use the `regs` command after running with button presses to
observe the program state after each press.
