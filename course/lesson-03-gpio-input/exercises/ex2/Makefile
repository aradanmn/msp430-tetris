TARGET  = ex2
MCU     = msp430g2553

CC := $(shell which msp430-elf-gcc 2>/dev/null || which msp430-gcc 2>/dev/null)
ifeq ($(CC),)
  $(error No MSP430 GCC found. Run the bootstrap script inside your VM.)
endif
OBJCOPY := $(subst gcc,objcopy,$(CC))
OBJDUMP := $(subst gcc,objdump,$(CC))
SIZE    := $(subst gcc,size,$(CC))

CFLAGS  = -mmcu=$(MCU) -x assembler-with-cpp -nostdlib -g -Wall

all: $(TARGET).elf
	@$(SIZE) $(TARGET).elf

$(TARGET).elf: $(TARGET).s
	$(CC) $(CFLAGS) -o $@ $<

flash: $(TARGET).elf
	mspdebug tilib "prog $<"

disasm: $(TARGET).elf
	$(OBJDUMP) -d $<

clean:
	rm -f $(TARGET).elf

.PHONY: all flash disasm clean
