.section .text.startup
.global _start

_start:
    lui  a0, 0x80000
    
    # Write 0x01
    li   a1, 0x01
    sw   a1, 0(a0)
    
    # Unconditional jump to target
    j    target
    
    # If jump fails, we'll execute this (write 0x0E = BAD)
    li   a1, 0x0E
    sw   a1, 0(a0)
    
target:
    # If jump works, we get here (write 0x03 = GOOD)
    li   a1, 0x03
    sw   a1, 0(a0)
    
loop:
    j    loop
