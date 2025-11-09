    /* for some reason this code never worked 
    it keeps failing to build.
    */
    
    
    .section .text
    .globl _stext
_stext:
    # compute RAM base in t0 = 0x20000000
    lui    t0, 0x20000        # t0 = 0x20000000

    # build mem[8] addr = t8 = 0x20000020 using t8 itself
    lui    t8, 0x20000
    addi   t8, t8, 32         # t8 = 0x20000000 + 32

    # build mem[9] addr = t7 = 0x20000024
    lui    t7, 0x20000
    addi   t7, t7, 36         # t7 = 0x20000000 + 36

    # diagnostic: store computed t0 at mem[8]
    sw     t0, 0(t8)          # mem[8] <- t0 (should be 0x20000000)

    # small diagnostic: store a known small pattern mem[9] (decimal 291 = 0x123)
    addi   t9, x0, 291
    sw     t9, 0(t7)          # mem[9] <- 291

    # ----------------------------------------------------------------
    # Start marker: successful start will write 1
    sw     x0, 0(t0)          # default 0
    addi   t1, x0, 1
    sw     t1, 0(t0)          # mem[0] = 1 (start)

    # ----------------------------------------------------------------
    # BEQ test with fail/success markers
    addi   t1, x0, 222        # fail code decimal 222 (0xDE)
    sw     t1, 4(t0)          # FAIL marker at mem[1]
    addi   t2, x0, 5
    addi   t3, x0, 5
    beq    t2, t3, beq_true
    # beq false path (should not run)
    addi   t1, x0, 191        # 0xBF = 191
    sw     t1, 4(t0)
    j      beq_after
beq_true:
    addi   t1, x0, 16         # success code 16
    sw     t1, 4(t0)
beq_after:

    # ----------------------------------------------------------------
    # JAL / CALL test
    addi   t1, x0, 223        # fail code 223 (0xDF)
    sw     t1, 8(t0)          # FAIL mem[2]
    jal    ra, call_sub
    addi   t1, x0, 33         # 0x21 = 33
    sw     t1, 8(t0)          # mem[2] success

call_sub:
    addi   t1, x0, 32         # 0x20 = 32
    sw     t1, 12(t0)         # mem[3]
    jalr   x0, ra, 0

    # ----------------------------------------------------------------
    # LOAD/STORE test
    addi   t1, x0, 224        # fail code 224 (0xE0)
    sw     t1, 16(t0)         # FAIL mem[4]
    addi   t1, x0, 85         # 0x55 = 85
    sw     t1, 16(t0)         # store value
    lw     t4, 16(t0)
    sw     t4, 20(t0)         # mem[5] loaded value
    addi   t1, x0, 85
    sw     t1, 16(t0)         # mark success

    # ----------------------------------------------------------------
    # BNE test
    addi   t1, x0, 225        # fail code 225 (0xE1)
    sw     t1, 24(t0)         # FAIL mem[6]
    addi   t5, x0, 1
    addi   t6, x0, 2
    bne    t5, t6, bne_true
    addi   t1, x0, 49         # 0x31 = 49
    sw     t1, 24(t0)
    j      bne_after
bne_true:
    addi   t1, x0, 48         # 0x30 = 48
    sw     t1, 24(t0)
bne_after:

    # ----------------------------------------------------------------
    # done marker
    addi   t1, x0, 255        # 0xFF = 255
    sw     t1, 28(t0)         # mem[7] done

spin:
    j spin
