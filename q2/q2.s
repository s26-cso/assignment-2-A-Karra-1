.globl main

.data
    format_str: .string "%lld "
    newline_str: .string "\n"

.text

main:
    addi sp, sp, -8
    sd ra, 0(sp)
    
    addi sp, sp, -48
    sd s0, 40(sp)       # s0 = n
    sd s1, 32(sp)       # s1 = atoi(input_arr)
    sd s2, 24(sp)       # s2 = final_ans array
    sd s3, 16(sp)       # s3 = stack (array)
    sd s4, 8(sp)        # s4 = argv array of string format
    sd s5, 0(sp)        # s5 = i

    # argc in a0, argv in a1 for now
    addi t0, x0, 1
    ble a0, t0, exit_main
    
    ## if (a0<=1) exit() like only ./q2.s is one argument

    # n = argc - 1
    addi s0, a0, -1     
    add s4, a1, x0      

    # arr = malloc(n * 8 bytes)
    slli a0, s0, 3      
    call malloc
    add s1, a0, x0      

    # result = malloc(n * 8 bytes)
    slli a0, s0, 3      
    call malloc
    add s2, a0, x0      

    # stack = malloc(n * 8 bytes)
    slli a0, s0, 3      
    call malloc
    add s3, a0, x0      

    # i = 0
    add s5, x0, x0      

parse_loop:

    # convert argv to integer and store in arr (s1)

    beq s5, s0, algo_setup
    # basically for i in range(n)

    # argv is an array of 64-bit string pointers.
    # Offset is (i+1) * 8 from which actual number part is starting,
    # +1 as first argument always ./script

    

    addi t0, s5, 1
    slli t0, t0, 3
    add t0, s4, t0
    ld a0, 0(t0)

    call atoi           

    # arr[i] = a0
    slli t0, s5, 3
    add t1, s1, t0
    sd a0, 0(t1)

    # result[i] = -1
    addi t2, x0, -1
    add t3, s2, t0
    sd t2, 0(t3)

    addi s5, s5, 1      
    beq x0, x0, parse_loop

algo_setup:
    # t1 is top. -1 means empty.
    addi t1, x0, -1     
    
    # i = n - 1
    addi s5, s0, -1     

for_loop:
    blt s5, x0, print_setup 

    # t2 = arr[i]
    slli t0, s5, 3      
    add t3, s1, t0      
    ld t2, 0(t3)        

while_loop:
    ## if stack.empty() (t1 == -1), break while
    addi t3, x0, -1
    beq t1, t3, while_end

    # t4 = stack[top] (INDEX)
    slli t0, t1, 3
    add t3, s3, t0  
    ld t4, 0(t3)    

    # t5 = arr[stack[top]] (VALUE)
    slli t0, t4, 3      
    add t3, s1, t0      
    ld t5, 0(t3)        

    ## if arr[stack.top()] > arr[i], break while
    bgt t5, t2, while_end

    ## else: stack.pop() -> top--
    addi t1, t1, -1     
    beq x0, x0, while_loop

while_end:
    ## if stack.empty(), skip setting result
    addi t3, x0, -1
    beq t1, t3, push_stack
    
    # If not empty, result[i] = stack[top]
    slli t0, t1, 3
    add t3, s3, t0
    ld t4, 0(t3)        

    slli t0, s5, 3
    add t3, s2, t0
    sd t4, 0(t3)        

push_stack:
    # stack.push(i) -> top++, stack[top] = i
    addi t1, t1, 1      
    slli t0, t1, 3
    add t3, s3, t0
    sd s5, 0(t3)

    # i--
    addi s5, s5, -1     
    beq x0, x0, for_loop

print_setup:
    add s5, x0, x0      

print_loop:
    beq s5, s0, print_done

    slli t0, s5, 3
    add t1, s2, t0
    ld a1, 0(t1)        
    
    la a0, format_str   
    call printf

    addi s5, s5, 1
    beq x0, x0, print_loop

print_done:
    la a0, newline_str
    call printf

exit_main:
    add a0, x0, x0      
    
    ld s5, 0(sp)
    ld s4, 8(sp)
    ld s3, 16(sp)
    ld s2, 24(sp)
    ld s1, 32(sp)
    ld s0, 40(sp)
    addi sp, sp, 48
    
    ld ra, 0(sp)
    addi sp, sp, 8
    
    ret