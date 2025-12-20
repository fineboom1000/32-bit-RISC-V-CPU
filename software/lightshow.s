# simple_lightshow.s - Clean, working light show
# Binary counter with visible speed

.section .text.startup
.globl _start

_start:
    # Load GPIO base (0x80000000)
    lui  a0, 0x80000
    
    # Initialize counter
    li   t0, 0
    
loop:
    # Write counter to GPIO (only lower 7 bits used)
    andi t1, t0, 0x7F
    sw   t1, 0(a0)
    
    # Software delay loop
    li   t2, 1000000    # Adjust this for speed
delay:
    addi t2, t2, -1
    bnez t2, delay
    
    # Increment counter
    addi t0, t0, 1
    
    # Loop forever
    j    loop