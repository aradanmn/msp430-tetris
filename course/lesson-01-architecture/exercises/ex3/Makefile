TARGET  = ex3
MCU     = msp430g2553

GCC     := $(shell which msp430-elf-gcc 2>/dev/null || which msp430-gcc 2>/dev/null)
OBJDUMP := $(patsubst %gcc,%objdump,$(GCC))
CFLAGS  = -mmcu=$(MCU) -x assembler-with-cpp -nostdlib -g -Os -Wall -Wextra

all: $(TARGET).elf

$(TARGET).elf: $(TARGET).s
	$(GCC) $(CFLAGS) -o $@ $<

flash: $(TARGET).elf
	mspdebug ezfet "prog $(TARGET).elf"

disasm: $(TARGET).elf
	$(OBJDUMP) -d $(TARGET).elf

clean:
	rm -f $(TARGET).elf

.PHONY: all flash disasm clean
