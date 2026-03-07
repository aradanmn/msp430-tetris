# Lesson 15 Exercises — I2C

> **Hardware requirements:** > - 4.7 kΩ pull-up resistors on P1.6 (SDA) and P1.7
(SCL) to VCC > - Remove the LED2 jumper (P1.6 is shared with LED2) > - Terminal:
`picocom -b 9600 /dev/ttyACM0`

---

## Exercise 1 · I2C Bus Scanner

**File:** `ex1/ex1.s`

Run the `i2c_scan` example (or re-implement it from scratch) and test with a
real I2C device connected to the bus.

Extend the scanner to also print addresses that NACK (with a "." for each failed
address) so you can see the full progress:

```
Scanning I2C...
........................................Found: 0x48
...............................
Done. 1 device(s) found.
```

**Count** the number of found devices in a variable and print the total at the
end.

---

## Exercise 2 · Write to an I2C EEPROM (AT24C02)

**File:** `ex2/ex2.s`

The AT24C02 is a 256-byte EEPROM with I2C address 0x50 (A2=A1=A0=0).

Write transaction to store a byte:
```
S  0x50  W  A  mem_addr  A  data_byte  A  P
```

Read transaction to retrieve a byte (set address first, then read):
```
S  0x50  W  A  mem_addr  A  P
S  0x50  R  A  data_byte  NA  P
```

1. Write the byte `0xAB` to EEPROM address `0x00`.
2. Wait 5 ms (write cycle time).
3. Read back from address `0x00`.
4. If value matches `0xAB`: blink LED1 + print "EEPROM OK\r\n".
5. If mismatch: LED2 on + print "FAIL: 0xXX\r\n".

---

## Exercise 3 · TMP102 Temperature Sensor

**File:** `ex3/ex3.s`

The TMP102 has I2C address 0x48 (ADD0=GND).  To read temperature:

1. Send: `S 0x48 R A` — start a read with no register address step (TMP102
   auto-points to temperature register after power-on).
2. Read 2 bytes: `byte0 A byte1 NA P`.
3. Temperature = `((byte0 << 4) | (byte1 >> 4))` in units of 0.0625°C.
4. For integer °C: shift right 4 more (divide by 16... but that loses the
   fractional bits, so just use `((int16_t)(raw) >> 4) * 625 / 10000` — in
   assembly: `raw_asr_4` gives integer °C to ±1°C accuracy).

Print the integer part of the temperature over UART every 2 seconds: `"Temp:
23C\r\n"`

**Alternative:** If you don't have a TMP102, use the MSP430G2552's own internal
temperature sensor from Lesson 12 and output its reading via UART instead.
