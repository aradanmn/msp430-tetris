# Lesson 12 Exercises — ADC10

---

## Exercise 1 · Busy-Wait ADC Read

**File:** `ex1/ex1.s`

Read ADC10 from the internal temperature sensor using the busy-wait (polling
ADC10BUSY) method.  Display the result on LED1:

- If `ADC10MEM < 512` (below midpoint): LED1 off
- If `ADC10MEM >= 512`: LED1 on
- LED2 toggles every conversion to confirm readings are happening

Repeat continuously with a 250ms delay between readings.

---

## Exercise 2 · Temperature Threshold Alarm

**File:** `ex2/ex2.s`

Implement a temperature alarm:

1. Read temperature sensor every 500ms
2. If reading > WARM_THRESHOLD (≈ current room temp + 5°C equivalent in counts):
   - LED1 turns ON - LED2 blinks rapidly (5Hz using software delay loop)
3. If reading ≤ WARM_THRESHOLD: - LED1 stays OFF - LED2 blinks slowly (1Hz)

**Finding your threshold:** Warm the sensor by pressing your finger gently on
the MSP430 chip.  Watch the LED change.  Adjust the threshold constant based on
what you observe.

**Starting threshold:** Use `780` (approximately 28°C with 1.5V ref). Each count
≈ 0.4°C, so adjust by ±10 counts per degree.

---

## Exercise 3 · External Analog Channel

**File:** `ex3/ex3.s`

Read an external analog voltage from channel **A4 (P1.4)**.

1. Configure P1.4 as an analog input (set `ADC10AE0 bit 4`)
2. Read continuously; map 0–1023 to an LED brightness display: - Result < 256:
   both LEDs off - Result 256–511: LED1 on - Result 512–767: LED2 on - Result ≥
   768: both LEDs on

To test: connect a potentiometer between VCC (3.3V) and GND, wiper to P1.4.  Or
simply connect P1.4 to GND for min or to 3.3V pin for max.

**Note:** Use `SREF_0` (VCC reference) for external channel readings so the full
0–3.3V range maps to 0–1023.
