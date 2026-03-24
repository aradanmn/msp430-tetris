TARGET  = ex1
MCU     = msp430g2553

TI_GCC  := $(HOME)/ti/msp430-gcc/bin/msp430-elf-gcc
GCC     := $(shell test -f $(TI_GCC) && echo $(TI_GCC) || which msp430-elf-gcc 2>/dev/null || which msp430-gcc 2>/dev/null)
OBJDUMP := $(patsubst %gcc,%objdump,$(GCC))
MSPDEBUG:= mspdebug
LIBMSP430_DIR := $(HOME)/.local/lib
TI_INC  := $(HOME)/ti/msp430-gcc/include

CFLAGS  = -mmcu=$(MCU) -x assembler-with-cpp -nostdlib -g -Os -Wall -Wextra \
          -Wl,-L$(TI_INC) -Wl,-T,$(TI_INC)/$(MCU).ld \
          -Wl,--section-start=.vectors=0xFFE0

all: $(TARGET).elf

$(TARGET).elf: $(TARGET).s
	$(GCC) $(CFLAGS) -o $@ $<

flash: $(TARGET).elf
	DYLD_LIBRARY_PATH=$(LIBMSP430_DIR):$$DYLD_LIBRARY_PATH $(MSPDEBUG) tilib "prog $(TARGET).elf"

disasm: $(TARGET).elf
	$(OBJDUMP) -d $(TARGET).elf

clean:
	rm -f $(TARGET).elf

.PHONY: all flash disasm clean
