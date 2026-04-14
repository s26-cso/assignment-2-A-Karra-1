.globl make_node
.globl insert
.globl get
.globl getAtMost

.equ NODE_VAL, 0
.equ NODE_LEFT, 8
.equ NODE_RIGHT, 16
.equ NODE_SIZE, 24

.text

make_node:
    # a0 has val

    addi sp, sp, -8
    sd ra, 0(sp)

    # before calling malloc i have to set a0 = 24 (no of bytes to be malloced)

    addi sp, sp, -8
    sd s0, 0(sp)
    add s0, a0, x0

    addi a0, x0, NODE_SIZE
    call malloc

    sw s0, NODE_VAL(a0)
    sd x0, NODE_LEFT(a0)
    sd x0, NODE_RIGHT(a0)

    ld s0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16

    ret

insert:
    # a0 has struct Node, a1 has value to be inserted

    addi sp, sp, -8
    sd ra, 0(sp)

    beq a0, x0, insert_base_case
    bne a0, x0, insert_usual_case

insert_base_case:
    add a0, a1, x0
    # now a0 also has val
    call make_node
    
    ld ra, 0(sp)
    addi sp, sp, 8
    ret


insert_usual_case:

    lw t0, NODE_VAL(a0)

    ble a1, t0, insert_left
    bgt a1, t0, insert_right

insert_left:
    addi sp, sp, -8
    sd a0, 0(sp)
    ld a0, NODE_LEFT(a0)
    call insert

    ld t1, 0(sp)
    sd a0, NODE_LEFT(t1)

    beq x0, x0, insert_end


insert_right:
    addi sp, sp, -8
    sd a0, 0(sp)
    ld a0, NODE_RIGHT(a0)
    call insert

    ld t1, 0(sp)
    sd a0, NODE_RIGHT(t1)
    
    beq x0, x0, insert_end

insert_end:
    ld t1, 0(sp)
    addi sp, sp, 8
    
    add a0, t1, x0
    
    ld ra, 0(sp)
    addi sp, sp, 8
    
    ret

get:
    # a0 has root, a1 has val
    beq a0, x0, get_end

get_while:
    beq a0, x0, get_end

    lw t0, NODE_VAL(a0)
    beq a1, t0, get_end
    blt a1, t0, go_left
    bgt a1, t0, go_right

go_left:
    ld a0, NODE_LEFT(a0)
    beq x0, x0, get_while

go_right:
    ld a0, NODE_RIGHT(a0)
    beq x0, x0, get_while

get_end:
    ret

getAtMost:
    # Swapping arguments
    add t2, a0, x0
    add a0, a1, x0
    add a1, t2, x0

    # Now after swapping again a0 has root, a1 has val
    beq a0, x0, return_neg1 
    ## if root == NULL, return -1
    addi t1, x0, -1

getAtMost_while:
    beq a0, x0, getAtMost_end

    lw t0, NODE_VAL(a0)
    beq a1, t0, exact_match
    blt a1, t0, goAtMost_left
    bgt a1, t0, goAtMost_right

goAtMost_left:
    ld a0, NODE_LEFT(a0)
    beq x0, x0, getAtMost_while

goAtMost_right:
    add t1, t0, x0
    ld a0, NODE_RIGHT(a0)
    beq x0, x0, getAtMost_while

exact_match:
    add t1, t0, x0

getAtMost_end:
    add a0, t1, x0
    ret

return_neg1:
    li a0, -1
    ret