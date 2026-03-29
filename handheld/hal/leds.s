;==============================================================================
; init_leds
; How it works: Sets the GPIOs connected to LEDs as Outputs and in OFF State
;==============================================================================
leds_init:
    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT
    ret
;==============================================================================
; test_leds
; How it works:
;   - LED1 flashes 3 times (150 ms on/off)
;   - LED2 flashes 3 times (150 ms on/off)
;   - Both LEDs flash together 2 times (250 ms on/off)
;   - Both LEDs OFF when done
;==============================================================================
leds_test:
    mov.w   #3, R10
.Lstate_zero:
    mov.b   #LED1, R8
    mov.w   #150, R9
    call    #.Lflash_led
    dec.w   R10
    jnz     .Lstate_zero
    mov.w   #3, R10
.Lstate_one:
    mov.b   #LED2, R8
    mov.w   #150, R9
    call    #.Lflash_led
    dec.w   R10
    jnz     .Lstate_one
    mov.w   #2, R10
.Lstate_two:
    mov.b   #(LED1|LED2), R8
    mov.w   #250, R9
    call    #.Lflash_led
    dec.w   R10
    jnz     .Lstate_two
    bic.b   #(LED1|LED2), &P1OUT
    ret
;==============================================================================
; flash_led
; How it works: the caller loads which LED(s) to turn on/off into R8
;   loads the ms delay into R9.
;==============================================================================
.Lflash_led:
    bis.b   R8, &P1OUT  ; Turn ON LED(s)
    mov.w   R9, R12     ; load delay into R12
    call    #.Ldelay_ms   ; wait X ms
    bic.b   R8, &P1OUT  ; Turn OFF LED(s)
    mov.w   R9, R12     ; load delay into R12
    call    #.Ldelay_ms   ; wait X ms
    ret                 ; return to call
;==============================================================================
; delay_ms
; How it works: at 1 MHz, 1 ms = 1000 cycles
;   Inner loop: dec (1 cycle) + jnz (2 cycles) = 3 cycles per iteration
;   333 iterations × 3 cycles = 999 cycles ≈ 1 ms
;==============================================================================
.Ldelay_ms:
    mov.w   #333, R13   ; 333 interations
.Ltms_loop:
    dec.w   R13         ; one cycle
    jnz     .Ltms_loop  ; two cycles
    dec.w   R12         ; 1ms
    jnz     .Ldelay_ms    ; start another delay_ms
    ret                 ; done return to caller
