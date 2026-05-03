# Lesson 03 — Exercise 1 Grade

**Score: 8/10 — Pass**

---

## First Attempt

```asm
.Lbtn_press:
    bit.b   #BTN, &P1IN
    jz      button_pressed
    jnz     button_released

button_pressed:
    xor.b   #LED1, &P1OUT
    jmp     .Lbtn_press
button_released:
    jmp     main_loop
```

**Problem:** `button_pressed` toggles then loops back to `.Lbtn_press`.
While the button is held, the loop runs continuously — toggling LED1
thousands of times per second. The LED state on release is essentially random.
This is a different failure mode from bounce: it's a structural bug, not a
hardware artifact.

Secondary issue: `button_released` and `button_pressed` are global labels.
Local labels (`.L` prefix) should be used for internal branch targets.

---

## Final Version

```asm
.Lbtn_press:
    bit.b   #BTN, &P1IN
    jnz     .Lbtn_press
    xor.b   #LED1, &P1OUT
.Lbtn_release:
    bit.b   #BTN, &P1IN
    jz      .Lbtn_release
    jmp     main_loop
```

**Correct.** Two separate polling loops with the toggle between them.
Button is held → stays in `.Lbtn_press`. Pressed → exits, toggles once,
waits for release. Clean structure, local labels used correctly.

---

## On Bounce

The exercise expects observable erratic behavior. It wasn't visible on this
hardware — the S2 contacts are clean enough that bounce doesn't manifest at
the polling rate. The concept is understood; the implementation is correct.

---

## Summary

| Requirement | Result |
|---|---|
| BTN configured as input with pull-up | ✅ |
| LED1 configured as output | ✅ |
| Wait-for-press loop | ✅ (after fix) |
| Single toggle | ✅ (after fix) |
| Wait-for-release loop | ✅ (after fix) |
| Local labels | ✅ (after fix) |
| First attempt structural bug identified and fixed | ✅ |

**-2:** First attempt had the toggle inside the press polling loop (continuous
toggling while held), requiring a structural correction before the program
behaved correctly.
