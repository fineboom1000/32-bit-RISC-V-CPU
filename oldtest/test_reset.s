/*

This will check whether my program
begins at the correct entry point
from the linker linker_script

—I also make notes here for my own sake...

I defined in my linker
ENTRY(_stext)


so at RESET the PC should load _stext (the first instruction in .text).

Question for myself to answer: How are .text and stack different?
I know .text is defined within the ROM since we should only need to read and execute
from it and nothing else, where as stack is on the RAM and is used to run the program?
I need some califcation and more here....

first looking at the ld I made
RESET loads _stext and execurtion enter there

the reseet vector/address is defined to be at 0x00001000
and ENTRY(_stext) sets the linker's entry symbol.

Reset pc is loaded from the reset vector and sp is initalized to a platform 
I called STACK_TOP.

Confirm _stext is placed at 0x00001000 (the ROM origin).

Confirm PC begins execution there.
*/

    .section .isr_vector,"a"

    .global _start
    .global _stext

_start:
_stext:
    j . + 0           /* jump-to-self as first instruction */


/*


beneisenberg@Bens-MacBook-Air RISC_V_CPU % riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostartfiles \
  -T linker_script.ld test_reset.S -o test_reset.elf -Wl,-Map=test_reset.map
beneisenberg@Bens-MacBook-Air RISC_V_CPU % riscv32-unknown-elf-readelf -h test_reset.elf | grep 'Entry'
  Entry point address:               0x1000
beneisenberg@Bens-MacBook-Air RISC_V_CPU % riscv32-unknown-elf-nm -n test_reset.elf | grep _stext
00001000 T _stext
beneisenberg@Bens-MacBook-Air RISC_V_CPU % riscv32-unknown-elf-objdump -h test_reset.elf

test_reset.elf:     file format elf32-littleriscv

Sections:
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         00000004  00001000  00001000  00001000  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .data         00000000  20000000  00001004  00002000  2**0
                  CONTENTS, ALLOC, LOAD, DATA
  2 .bss          00000000  20000000  00001004  00002000  2**0
                  ALLOC
  3 .riscv.attributes 0000001a  00000000  00000000  00002000  2**0
                  CONTENTS, READONLY
beneisenberg@Bens-MacBook-Air RISC_V_CPU % riscv32-unknown-elf-objdump -d --section=.isr_vector test_reset.elf | sed -n '1,20p'
riscv32-unknown-elf-objdump: section '.isr_vector' mentioned in a -j option, but not found in any input file

test_reset.elf:     file format elf32-littleriscv

beneisenberg@Bens-MacBook-Air RISC_V_CPU % 



there is an error

I called 
objdump -d --section=.isr_vector
and it failed. I asked gpt why, it says that the ELF has no .isr_vector 
Section
so our code did not prodcue a section with that exact name.

I am getting gpt to walk me through it says that
.section .isr_vector,"a" will tell the assembler to put code in a section named 
then it says that in my complied ELF .text appeared instead of .isr_vector—which did  not appear.
Now I do not know how I would have found this otherwise 
but
"riscv32-unknown-elf-gcc.
GCC’s default -nostartfiles still wraps assembly in its
 own conventions. It often overrides section placement
  unless you add -nostdlib -nostartfiles -nodefaultlibs
  or you give a code section name it recognizes."
So the assembler wrote into .text, not .isr_vector.
it said to use
riscv32-unknown-elf-as -march=rv32i -mabi=ilp32 test_reset.S -o test_reset.o
riscv32-unknown-elf-ld -T linker_script.ld test_reset.o -o test_reset.elf

objdump -h will release all the seciton info headers


trying some stuff
 RISC_V_CPU % riscv32-unknown-elf-objdump -h test_reset.elf


test_reset.elf:     file format elf32-littleriscv

Sections:
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         00000004  00001000  00001000  00001000  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .data         00000000  20000000  00001004  00002000  2**0
                  CONTENTS, ALLOC, LOAD, DATA
  2 .bss          00000000  20000000  00001004  00002000  2**0
                  ALLOC
  3 .riscv.attributes 0000001a  00000000  00000000  00002000  2**0
                  CONTENTS, READONLY


        note gthat "a" just means alloc as in the section is allocated at runtime
        It is not really relevant here yet I do not know much about it. 


        right now see that in my ld I put isr_vector into the output section 
        of .text 
        KEEP(*(.isr_vector)) is inside the .text output section in the .ld
        why we do this:
        the reset vector must be at the start of RTO and must not be discarded by the
        linker—even if unused. KEEP prevents garbage collection.
        Ergo, putting it inside .text makes sure it has executble permissions and is located within code.

asking gpt why did I see .isr_vector in test_reset.o but not in test_reset.elf

That is a little wierd, how is it in the output file (so it was assembled) but not linked?
readelf -S test_reset.o shows the input sections created by the assembler
objdump -h test_reset.eld should show output sections after the linker merged inputs
as our linker script says so.

K so I asked gpt why would the resources I am following care about putting
this vector in its own section. Who cares?
well I do...
here is what it said.
"Easy one-command disassembly of only the vector. (You can still disassemble the low addresses of .text.)

Per-section attributes or special placement separate from .text (different alignment, padding, or later relocation) are harder.

If some external tool strictly expects an output named .isr_vector, it won’t find it."

This means there was no problem.



*/