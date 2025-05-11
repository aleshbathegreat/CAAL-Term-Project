#define STDOUT 0xd0580000
#define MAX_SIZE       8
#define SINGLE_VECTOR  (MAX_SIZE * 4)
#define HALF_VECTOR    (SINGLE_VECTOR / 2)
#define VECTOR_SPACE   (MAX_SIZE * 4 * 2)   /* enough room for a[a1] + even[a1/2] + odd[a1/2] */
#define SAVE_RA        (VECTOR_SPACE + 0)
#define SAVE_A1        (VECTOR_SPACE + 4)
#define SAVE_A0        (VECTOR_SPACE + 8)
#define FRAME_SIZE     (VECTOR_SPACE + 12)

.set MAX_SIZE,      8
.set SINGLE_VECTOR, MAX_SIZE * 4
.set HALF_VECTOR,   SINGLE_VECTOR / 2
.set VECTOR_SPACE,  MAX_SIZE * 4 * 2
.set SAVE_RA,       VECTOR_SPACE + 0
.set SAVE_A1,       VECTOR_SPACE + 4
.set SAVE_A0,       VECTOR_SPACE + 8
.set FRAME_SIZE,    VECTOR_SPACE + 12


.data
## ALL DATA IS DEFINED HERE LIKE MATRIX, CONSTANTS ETC

## DATA DEFINE START
.equ TWIDDLE_FACTOR, 1
.equ Size,           8


signal: .float 4.0, 4.0, 1.0, 2.0, 1.0, 4.0, 3.0, 4.0

## DATA DEFINE END
size: .word Size


.section .text
.global _start
_start:
## START YOUR CODE HERE

##main

    addi t6, zero, 1
    la a0, signal
    la a1, size
    call fft
    j _finish

    # a0 = base address, a1 = size of vector
fft:
    beq a1, t6, base_case

    #reserve stack space
    addi sp, sp, -FRAME_SIZE

    addi s0, sp, FRAME_SIZE

    vsetvli t0, a1, e32, m1
    #---------------vector length set to size
    vle32.v v1, (a0)                    #v1 = a

    srli t1, a1, 1                      #t1 = size/2
    vsetvli t0, t1, e32, m1
    #---------------vector length set to size/2
    vle32.v v2, (a0)                    #v2 = even
    add t2, a0, t1                      #go to second half address
    vle32.v v3, (t2)                    #v3 = odd

    vse32.v v3, 0(sp)
    addi t5, sp, HALF_VECTOR
    vse32.v v2, (t5)
    vsetvli t0, a1, e32, m1
    #---------------vector length set to size
    addi t5, sp, SINGLE_VECTOR
    vse32.v v1, (t5)

    sw ra, SAVE_RA(s0)
    sw a1, SAVE_A1(s0)
    sw a0, SAVE_A0(s0)

    mv a1, t1
    jal fft

    lw a1, SAVE_A1(s0)
    vsetvli t0, a1, e32, m1
    #---------------vector length set to size/2
    addi t5, sp, SINGLE_VECTOR
    vle32.v v4, (t5)
    addi sp, sp, FRAME_SIZE
    addi s0, s0, -FRAME_SIZE
    addi t5, sp, HALF_VECTOR
    vse32.v v4, (t5)

    mv a0, sp                   #t1 here has the value that would be at the end of this code, probably the computation part
    jal fft

    lw a1, SAVE_A1(s0)
    vsetvli t0, a1, e32, m1
    #---------------vector length set to size/2
    addi t5, sp, SINGLE_VECTOR
    vle32.v v4, (t5)
    addi sp, sp, FRAME_SIZE
    addi s0, s0, -FRAME_SIZE
    vse32.v v4, 0(sp)

    lw ra, SAVE_RA(s0)
    lw a1, SAVE_A1(s0)

    #computation goes here
    addi t5, sp, HALF_VECTOR
    vle32.v v3, (t5)

    #v4 = odd, v3 = even, v5 = a
    vfadd.vv v5, v4, v5
    addi t5, sp, SINGLE_VECTOR
    vse32.v v5, (t5)
    vfsub.vv v5, v4, v5

    #second half address of a = sp + SINGLE_VECTOR + a1/2
    srli t4, a1, 1   #size of a / 2
    addi t4, t4, SINGLE_VECTOR
    add t4, t4, sp

    addi t5, t4, SINGLE_VECTOR
    vse32.v v5, (t5)

    jalr  zero, 0(ra)

base_case:
    jalr  zero, 0(ra)


    ## END YOU CODE HERE

# Function: print
# Logs values from array in a0 into registers v1 for debugging and output.
# Inputs:
#   - a0: Base address of array
#   - a1: Size of array i.e. number of elements to log
# Clobbers: t0,t1, t2,t3 ft0, ft1.
printToLogVectorized:
    addi sp, sp, -4
    sw a0, 0(sp)

    li t0, 0x123                 # Pattern for help in python script
    li t0, 0x456                 # Pattern for help in python script
    mv a1, a1                   # moving size to get it from log

	li t0, 0		                # load i = 0
    printloop:
        vsetvli t3, a1, e32           # Set VLEN based on a1
        slli t4, t3, 2                # Compute VLEN * 4 for address increment

        vle32.v v1, (a0)              # Load real[i] into v1
        add a0, a0, t4                # Increment pointer for real[] by VLEN * 4
        add t0, t0, t3                # Increment index

        bge t0, a1, endPrintLoop      # Exit loop if i >= size
        j printloop                   # Jump to start of loop
    endPrintLoop:
    li t0, 0x123                    # Pattern for help in python script
    li t0, 0x456                    # Pattern for help in python script

    lw a0, 0(sp)
    addi sp, sp, 4

	jr ra


# Function: _finish
# VeeR Related function which writes to to_host which stops the simulator
_finish:
    li x3, 0xd0580000
    addi x5, x0, 0xff
    sb x5, 0(x3)
    beq x0, x0, _finish

    .rept 100
        nop
    .endr
