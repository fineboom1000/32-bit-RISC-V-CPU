.section .text.startup
.global _start

_start:
    # GPIO base address
    lui  a0, 0x80000       # a0 = 0x80000000
    
    # LED counter
    li   a1, 0             # a1 = 0
    
loop:
    # Write counter to LEDs
    sw   a1, 0(a0)         # GPIO_LED = a1
    
    # Simple delay - count to 0x200000
    li   t0, 0x200000
delay_loop:
    addi t0, t0, -1
    bnez t0, delay_loop
    
    # Increment counter
    addi a1, a1, 1
    andi a1, a1, 0x7F      # Keep bits 0-6 (LEDs + RGB)
    
    # Loop forever
    j    loop