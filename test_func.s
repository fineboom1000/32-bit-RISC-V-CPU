
.section .text
.globl main
.globl get_42

get_42:
    addi a0, x0, 42
    ret

main:
    call get_42
    # result now in a0
    ret



















/*
In RISC-V assembly a function is simply this

1. a lable — meaing its name
2. Some instructions
3. a return using ret (aka a PI for jalr x0, 0(ra))

when a funcito is called, using call func, the CPU
saves the return address in ra,
jumps to func.

Inside the function,
a0-a7 holds arugemtns like parameters. 
a0 also holds a return value.
other registser like ti do not need saving.
If you use s0, s1...etc you musts store them on the stack( or heap? check)

lets make a function that returns a constant 42

also note that it is a riscv rule that we return outputs 
to the same registser that held the parameters of the function.



to my expectation

ret is really jalr ra, x0, 0
since we would want to return to where we left off 
and not else where (atleast without reason).

when we start up all GPR are zeroed, but sp since that will
start at _estack as per my linker linker_script


when wel cdall get_42 we really expand
jal ra, get_42
jal does two things
Stores the address of the next instruction (the return point) into ra.
Updates the PC to the address of get_42

this makes sense
as per one of my flashcards,
j-type is a subtype of u type specifically defined to transfer the control
of the program by adding a signed byte to PC


but there is more


when you call jal here is what it does

jal will move by the alignment of the PC, here we are
four byte aligned so it moves PC+4
(note, gpt says +4 is fixed so...it is not quite right what I said)

then it stores the return address

and then it jumps bgy the offset.

see we do not return on the jal insctuoin or else that is an infinte loop!

when we then use jalr to jump back at the end of the function call
ret will really expand to jalr x0, 0(ra)
which jumps to whatever address is in ra.
this does not need to be th e return address on the stack
it can be to a nested function call


note that link means the saved return address that connects a function too
its caller

when you call jal it links the caller and callee by
saving the caller's next-instruction address (PC + 4) into a register (ra),

then jumping to the callee.

That saved address is the link.
So ra is called the link register because it holds that connection.

If a jal or jalr writes to x0, the link is thrown away — no return path saved
*/


    





