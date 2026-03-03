# Lesson 12 · ADC10 — Analog-to-Digital Converter

## What You'll Learn

- How the ADC10 converts analog voltages to 10-bit digital values
- How to read the internal temperature sensor (channel A10)
- How to configure the voltage reference (1.5V internal)
- How to trigger a conversion and read ADC10MEM
- A practical temperature threshold alarm using LED feedback

## Why This Matters

Analog sensing is everywhere: temperature, light, pressure, voltage. The
MSP430G2552's ADC10 has 8 external channels plus two internal channels
(temperature sensor and VCC/2).  This lesson gives you the foundation to read
any analog signal.

## Goals

1. Configure ADC10 for single conversion, internal reference, temp sensor
2. Trigger conversion and poll ADC10BUSY until complete
3. Read ADC10MEM and compare against a threshold
4. Convert raw ADC value to approximate Celsius

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-adc10-basics.md` | ADC10 architecture, registers, conversion steps |
| `tutorial-02-temperature.md` | Internal temp sensor, voltage-to-temperature formula |

## Example

```
examples/
└── adc_temp.s   ← Read temp sensor every 500ms; LED1 on if too warm
```

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | Busy-wait ADC read; blink LED1 N times proportional to ADC result |
| ex2 | Threshold alarm: LED2 on when ADC reading exceeds 600 counts |
| ex3 | Read an external analog channel (A3/P1.3 — needs jumper to voltage) |

## Capstone Connection

The capstone reads the internal temperature sensor via ADC10 and sends readings
over UART.  This lesson is the ADC foundation.
