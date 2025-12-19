# Should write 0x55 to GPIO immediately

.section .text.startup
.globl _start

_start:
    # Load GPIO base (0x80000000)
    lui  a0, 0x80000
    
    # Load test pattern 0x55
    li   a1, 0x55
    
    # Write to GPIO
    sw   a1, 0(a0)
    
    # Infinite loop
loop:
    j    loop