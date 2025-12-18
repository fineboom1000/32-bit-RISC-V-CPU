.section .text.startup
.global _start

_start:
    # GPIO base address
    lui  a0, 0x80000       # a0 = 0x80000000
    
    # Write 0x7F to all LEDs (all bits on)
    li   a1, 0x7F
    sw   a1, 0(a0)
    
    # Infinite loop - just stay here
loop:
    j    loop