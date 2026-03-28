# MSP430 GDB init — auto-connects to mspdebug GDB server
# Usage: start "MSP430: GDB Server" task first, then "MSP430: Debug"

target remote :2000

# Display registers + next instruction after every step
define hook-stop
  info registers
  x/1i $pc
end

# Shortcuts
define fr
  info registers
end

define fl
  flash
end

# Load the ELF (symbol + flash)
define reflash
  load
  monitor reset
end

echo \n=== MSP430 GDB connected on :2000 ===\n
echo Commands:\n
echo   s / si      — step (source / instruction)\n
echo   n / ni      — next (source / instruction)\n
echo   c           — continue\n
echo   fr          — show all registers\n
echo   info reg r4 — show one register\n
echo   x/16xh 0x0200 — dump RAM (16 half-words from 0x0200)\n
echo   b *0xC000   — breakpoint at address\n
echo   b main      — breakpoint at label\n
echo   reflash     — reload ELF + reset\n
echo   monitor reset — reset MCU\n
echo   Ctrl+C      — halt running program\n
echo \n
