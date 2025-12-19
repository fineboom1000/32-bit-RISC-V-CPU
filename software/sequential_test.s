.section .text.startup
.global _start

_start:
    # Write 0x01
    lui  a0, 0x80000
    li   a1, 0x01
    sw   a1, 0(a0)
    
    # Write 0x03 (should overwrite 0x01 immediately)
    li   a1, 0x03
    sw   a1, 0(a0)
    
    # Write 0x07
    li   a1, 0x07
    sw   a1, 0(a0)
    
    # Write 0x0F - THIS is what should stay visible
    li   a1, 0x0F
    sw   a1, 0(a0)
    
    # Infinite loop at THIS address
loop:
    j    loop
