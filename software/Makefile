# makefile for fpga led blinker
PREFIX = riscv64-unknown-elf-
CC = $(PREFIX)gcc
AS = $(PREFIX)as
LD = $(PREFIX)ld
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump

# flags
CFLAGS = -march=rv32i -mabi=ilp32 -O2 -Wall -ffreestanding -nostdlib
ASFLAGS = -march=rv32i -mabi=ilp32
LDFLAGS = -T linker_simple.ld -m elf32lriscv

# targets
OBJS = startup_simple.o led_blink.o
ELF = led_blink.elf
BIN = led_blink.bin
HEX = led_blink.hex
COE = led_blink.coe
DIS = led_blink.dis

.PHONY: all clean coe

all: $(ELF) $(BIN) $(HEX) $(DIS) coe

# link
$(ELF): $(OBJS) linker_simple.ld
	$(LD) $(LDFLAGS) $(OBJS) -o $(ELF)

# compile c
led_blink.o: led_blink.c
	$(CC) $(CFLAGS) -c led_blink.c -o led_blink.o

# assemble startup
startup_simple.o: startup_simple.s
	$(AS) $(ASFLAGS) startup_simple.s -o startup_simple.o

# generate binary
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BIN)

# generate hex
$(HEX): $(BIN)
	hexdump -v -e '1/4 "%08x\n"' $(BIN) > $(HEX)

# generate coe file for vivado
coe: $(HEX)
	@echo "memory_initialization_radix=16;" > $(COE)
	@echo "memory_initialization_vector=" >> $(COE)
	@cat $(HEX) | sed '$$!s/$$/,/' >> $(COE)
	@echo ";" >> $(COE)
	@echo "generated $(COE) for vivado block memory initialization"

# disassembly
$(DIS): $(ELF)
	$(OBJDUMP) -D $(ELF) > $(DIS)

clean:
	rm -f *.o $(ELF) $(BIN) $(HEX) $(COE) $(DIS)

help:
	@echo "targets"
	@echo "  all     build everything"
	@echo "  coe     generate coe file for vivado"
	@echo "  clean   remove build artifacts"