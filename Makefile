# Makefile for RISC-V CPU test program
#Heavily inspired

# Toolchain: for RV64
PREFIX = riscv64-unknown-elf-
CC = $(PREFIX)gcc
AS = $(PREFIX)as
LD = $(PREFIX)ld
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump

# Flags - force 32-bit with rv64 toolchain, needed.
CFLAGS = -march=rv32i -mabi=ilp32 -O2 -Wall -ffreestanding -nostdlib
ASFLAGS = -march=rv32i -mabi=ilp32
LDFLAGS = -T linker_script.ld -m elf32lriscv
# Targets
OBJS = startup.o main.o
ELF = program.elf
DIS = program.dis

.PHONY: all clean hex

all: $(ELF) hex $(DIS)

# Link
$(ELF): $(OBJS) linker_script.ld
	$(LD) $(LDFLAGS) $(OBJS) -o $(ELF)

# Compile C
main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

# Assemble startup
startup.o: startup.s
	$(AS) $(ASFLAGS) startup.s -o startup.o

# Generate hex files using Python script
hex: $(ELF)
	python3 elf_to_memhex.py $(ELF) \
		--rom-origin 0x00001000 \
		--ram-origin 0x20000000 \
		--out-imem imem.hex \
		--out-dmem dmem.hex

# Disassembly
$(DIS): $(ELF)
	$(OBJDUMP) -D $(ELF) > $(DIS)

clean:
	rm -f *.o $(ELF) $(DIS) imem.hex dmem.hex

# Help
help:
	@echo "Targets:"
	@echo "  all     - Build ELF and generate hex files"
	@echo "  hex     - Generate imem.hex and dmem.hex from ELF"
	@echo "  clean   - Remove build artifacts"