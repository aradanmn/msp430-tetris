# Lesson 10 Exercises — GPIO Interrupts

---

## Exercise 1 · Button Press Toggle (Interrupt-Driven)

**File:** `ex1/ex1.s`

Toggle LED1 on each confirmed button press using a PORT1 ISR. Main sleeps in
LPM0.  Include debouncing.

This is the same as the example, implemented from scratch without looking at the
example code.

**Checklist:**
- [ ] P1.3 configured as input with pull-up
- [ ] Falling edge selected (P1IES)
- [ ] P1IFG cleared before enabling P1IE
- [ ] ISR clears P1IFG, debounces, toggles LED1
- [ ] RETI used (not RET)
- [ ] Vector at 0xFFE4

---

## Exercise 2 · Press Counter

**File:** `ex2/ex2.s`

Maintain a press counter in RAM.  On each button press (ISR), increment the
counter.  In main (after waking from LPM), if counter > 0:
- Blink LED1 `counter` times
- Reset counter to 0

The blink pattern lets you "see" how many times you've pressed the button since
the last blink sequence.

**Hint:** Use a shared variable `press_count` in `.data`.  ISR increments it;
main reads, blinks, clears.

---

## Exercise 3 · Both Edges — Press and Release

**File:** `ex3/ex3.s`

Detect both the press and release of S2:

- **Press (falling edge):** LED1 turns ON, LED2 turns OFF
- **Release (rising edge):** LED1 turns OFF, LED2 turns ON

After the ISR handles the press (falling edge), switch P1IES to rising edge to
catch the release.  After the release, switch back to falling.

```asm
; In ISR, toggle edge select:
xor.b   #BTN, &P1IES       ; toggle between 0 (rising) and 1 (falling)
bic.b   #BTN, &P1IFG       ; clear flag AFTER toggling edge select
```

Note: always clear P1IFG **after** changing P1IES to avoid spurious triggers
caused by the edge-select change itself.
