# Lesson 01 Exercises

Complete these after reading both tutorials and building the example. Attempt
each exercise before looking at the solution.

---

## Exercise 1 — Register Arithmetic

Write a program that:
1. Stops the watchdog timer
2. Loads the value 42 into R4
3. Loads the value 13 into R5
4. Adds R5 to R4 (result in R4 should be 55 = 0x37)
5. Stores the result to RAM address 0x0200
6. Halts

**Verify with mspdebug:**
```
mspdebug rf2500
(mspdebug) prog ex1.elf
(mspdebug) run
(mspdebug) halt
(mspdebug) md 0x0200 2
```
Expected: you should see `37 00` (55 in little-endian 16-bit).

**Starter file:** `ex1/ex1.s` **Solution:** `ex1/solution/ex1.s`

---

## Exercise 2 — Status Register Flags

Write a program that:
1. Loads 0x1234 into R4
2. Subtracts R4 from R4 (result = 0, Zero flag should be set)
3. Uses `jz` to branch to a "zero_path" label
4. At zero_path: stores 0x0001 to RAM 0x0202 (meaning "zero was detected")
5. At non_zero_path: stores 0x0000 to RAM 0x0202
6. Halts after storing

**Verify with mspdebug:** `md 0x0202 2` should show `01 00`.

**Starter file:** `ex2/ex2.s` **Solution:** `ex2/solution/ex2.s`

---

## Exercise 3 — Memory Write and Read Back

Write a program that:
1. Writes the 16-bit value 0xABCD to RAM address 0x0200
2. Reads that value back into R6
3. Writes R6 to RAM address 0x0202 (confirming the read)
4. Halts

**Verify:** `md 0x0200 4` should show `CD AB CD AB` (little-endian).

Starter file: `ex3/ex3.s` | Solution: `ex3/solution/ex3.s`
