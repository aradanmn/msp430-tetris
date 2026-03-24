# Register Allocation Convention

In bare-metal MSP430, the ISR and main-line code share the same register file.
Without a convention, the ISR could silently clobber a register that main-line
code depends on — intermittent bugs that are brutal to debug. As the project
grows via `#include`, every module needs to know what's "mine" vs "shared."

With only 512 bytes of RAM, keeping hot state in registers (not memory) is a
real performance and space win — but only if registers are managed deliberately.

## Convention (MSP430 R0–R15)

| Register | Role | Scope |
|----------|------|-------|
| R0–R3 | PC, SP, SR, CG — CPU-reserved | Hardware |
| **R4** | Frame/tick counter | ISR — persistent across ticks |
| **R5** | Input state (current button bitmap) | ISR — written by `input_read`, read by `game_update` |
| **R6** | Previous input state (for edge detection) | ISR — updated each frame |
| **R7** | Game state / mode flags | ISR — persistent |
| **R8–R11** | Game-specific state (piece position, score, etc.) | ISR — assigned as needed per game |
| **R12–R15** | Scratch / subroutine arguments | Caller-saved — any subroutine may clobber these |

## Rules

1. **R4–R11 are persistent.** Subroutines must `push`/`pop` any R4–R11 they need as scratch.
2. **R12–R15 are scratch.** Callers assume these are destroyed by any `call`. Return values in R12.
3. **The ISR owns R4–R7.** Main-line code (before LPM0 entry) may initialize them but must not read them after `bis.w #(GIE|CPUOFF), SR`.
4. This convention aligns with the MSP430 GCC ABI (R12–R15 = args/return, R4–R11 = callee-saved), so if we ever link C modules, it "just works."

## Example

```asm
; In hal/timer.s — ISR uses R4 as tick counter (persistent)
timer_isr:
    dec.w   R4                      ; R4 = frame tick countdown
    jnz     .Lnot_frame
    mov.w   #FRAME_TICKS, R4
    call    #game_update            ; may use R12–R15 as scratch
.Lnot_frame:
    reti

; A subroutine that needs R4 temporarily must save/restore it
spi_tx_byte:
    push    R4                      ; save caller's R4
    ; ... use R4 as scratch ...
    pop     R4                      ; restore
    ret
```
