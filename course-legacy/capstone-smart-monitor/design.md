# Design Notes — Smart Environment Monitor

## System Tick

Timer_A CC0 generates a 1ms interrupt.  The ISR increments `ms_tick` (a 16-bit
unsigned counter) and wakes main from LPM0.

```
SMCLK = 1 MHz
TACCR0 = 999  → interrupt every 1000 cycles = 1ms
```

Because `ms_tick` is 16-bit, it wraps at 65535ms ≈ 65.5 seconds. The timestamp
comparison `(ms_tick - t_last)` correctly handles wrap-around as long as the
period is less than 32 seconds (which 500ms and 2000ms are).

## Temperature Measurement

ADC10 with internal temperature sensor (channel INCH_10):
- Reference: 1.5 V internal (`SREF_1 | REFON`)
- Sample time: 64 ADC10CLK cycles (`ADC10SHT_3`)
- Result: 10-bit value in ADC10MEM

Conversion formula (from MSP430 datasheet, Table 62):
```
T(°C) = (ADC10MEM × 1.5V / 1023 − V_offset) / T_coeff
V_offset ≈ 0.986 V at 25°C
T_coeff  ≈ 3.55 mV/°C
```

Integer approximation (accurate to ±2°C):
```
raw = ADC10MEM
T_C = (raw × 3 − 2480) / 10   [assembly: multiply then subtract and divide]
```

Simpler calibration approach used here:
```
T_C = (raw - 673) / 4 + 25    (calibrate 673 and 4 for your chip)
```

## Alarm Logic

```
armed    = 1/0 (global flag, toggled by button)
alarm    = 1/0 (set when T > threshold AND armed)
threshold = 30°C (adjustable constant)
```

UART output format:
- Normal: `"T=XXC  [OK]\r\n"`
- Alarm:  `"T=XXC  [ALARM]\r\n"`
- Disarmed: `"T=XXC  [OFF]\r\n"`

## WDT Safety

WDT is configured in watchdog mode with ACLK/32768 ≈ 2.7s timeout. Main pets the
watchdog every iteration of the 2000ms temperature task. If the firmware hangs
for >2.7s, the WDT resets the MCU.

Pet: `mov.w #(WDTPW|WDTCNTCL), &WDTCTL`

## Register Usage Convention

Following the course calling convention:
- R12: first argument / return value
- R13: second argument
- R14: string pointer (uart_puts)
- R15: scratch (delay inner loop)
- R4, R5: preserved globals (armed flag, alarm state)

## Memory Layout

```
RAM (512 bytes total):
  .data segment:
    ms_tick    (2 bytes) — 16-bit millisecond counter
    t_temp     (2 bytes) — timestamp of last temp reading
    t_hb       (2 bytes) — timestamp of last heartbeat
    armed      (1 byte)  — 0=disarmed, 1=armed
    alarm      (1 byte)  — 0=no alarm, 1=alarming
    temp_c     (2 bytes) — last measured temperature in °C

Flash (8KB):
  .text — code
  .rodata — string constants
  .vectors — interrupt vector table at 0xFFE0..0xFFFF
```
