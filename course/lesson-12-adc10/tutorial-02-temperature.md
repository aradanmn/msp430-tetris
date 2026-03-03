# Tutorial 12-2 · Internal Temperature Sensor

## The MSP430 Internal Temperature Sensor

Channel A10 connects to an internal diode-based temperature sensor. It is not a
precision sensor — accuracy is ±2–3°C without calibration — but it is very
useful for simple thermal monitoring and alarms.

The sensor output is approximately:
```
V_sensor = 0.00355 × T_celsius + 0.986    (volts)
```

---

## From ADC Count to Celsius

With a **1.5V internal reference**, the ADC resolution is:
```
V_per_count = 1.5 / 1024 ≈ 0.001465 V/count
```

So the temperature in Celsius is:
```
T = (V_sensor - 0.986) / 0.00355
  = ((ADC_count × 1.5 / 1024) - 0.986) / 0.00355
```

This formula involves floating-point arithmetic — not practical in assembly.
Instead, we use a **linearized integer approximation**.

---

## Integer Temperature Approximation

Around room temperature (25°C), the ADC count is approximately:
```
ADC_25C ≈ (0.00355 × 25 + 0.986) / (1.5/1024)
        ≈ (0.08875 + 0.986) / 0.001465
        ≈ 1.07475 / 0.001465
        ≈ 733 counts
```

A 1°C change corresponds to approximately:
```
Δ counts/°C = 0.00355 / (1.5/1024) ≈ 2.425 counts/°C
```

So a simplified formula for assembly:

```
T_celsius ≈ 25 + (ADC_count - 733) / 2.4
```

In integer arithmetic (divide by 2 as approximation, lose ~20% accuracy):
```asm
mov.w   &ADC10MEM, R12
sub.w   #733, R12           ; R12 = counts from 25°C baseline
; Divide by 2 (shift right 1) for approximate °C offset
rra.w   R12                 ; R12 = (ADC - 733) / 2
add.w   #25, R12            ; R12 = approximate °C
```

This gives accuracy of ±5°C, sufficient for alarm purposes.

---

## Practical Approach: Use Raw Counts for Threshold

Rather than converting to Celsius, compare ADC counts directly:

```asm
; If ADC reading > WARM_THRESHOLD, LED on
.equ    WARM_THRESHOLD, 760     ; approximately 26°C at 1.5V ref

mov.w   &ADC10MEM, R12
cmp.w   #WARM_THRESHOLD, R12
jlo     not_warm
; Temperature is above threshold
bis.b   #LED1, &P1OUT
jmp     done
not_warm:
bic.b   #LED1, &P1OUT
done:
```

Find your threshold experimentally: read the ADC at known room temperature, note
the count, then add/subtract based on the 2.4 counts/°C rate.

---

## Reference Settling Time

The internal reference (`REFON`) takes approximately 30µs to settle after being
turned on.  Always wait before starting the first conversion:

```asm
bis.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0
; Delay 30µs at 1MHz = 30 cycles
mov.w   #30, R15
ref_wait: dec.w R15
          jnz   ref_wait
; Now safe to start conversion
```

---

## Configuration Summary for Temperature Sensor

```asm
; CTL1: internal temp sensor, SMCLK, single conversion
mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1

; CTL0: 1.5V ref, 64-cycle sample (needed for temp sensor RC constant)
mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0

; Reference settling delay
mov.w   #1000, R15
rsettle: dec.w R15
         jnz   rsettle
```

Now open `examples/adc_temp.s` for the complete working program.
