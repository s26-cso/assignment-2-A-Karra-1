.globl main

.data
    filename: .string "input.txt"
    mode: .string "r"
    yes_str: .string "Yes\n"
    no_str: .string "No\n"

.text

main:

    addi sp, sp, -40
    sd ra, 32(sp)
    sd s0, 24(sp)       # s0 = file pointer
    sd s1, 16(sp)       # s1 = left index
    sd s2, 8(sp)        # s2 = right index
    sd s3, 0(sp)        # s3 = char_left temporary holder

    la a0, filename
    la a1, mode
    call fopen
    add s0, a0, x0      

    ## if (fp == NULL) exit
    beq s0, x0, exit_main

    # to get file length the command to run is this: 
    # fseek(fp, 0, SEEK_END)

    # I didnt know this file command so here is the summary of c function:

    # The Three Arguments:
    # stream: The file pointer you got from fopen().
    # offset: Exactly how many bytes you want to move. This can be a positive number (move forward) or a negative number (move backward).
    # whence (The Origin): This is the most important part. It tells fseek where to start counting that offset from. It has three modes:
    #     SEEK_SET (Value: 0): Start counting from the absolute beginning of the file.
    #     SEEK_CUR (Value: 1): Start counting from your current position in the file.
    #     SEEK_END (Value: 2): Start counting from the absolute end of the file.

    add a0, s0, x0
    add a1, x0, x0      # offset = 0
    addi a2, x0, 2      # SEEK_END = 2
    call fseek

    # ftell(fp)
    add a0, s0, x0
    call ftell
    
    # a0 now holds total bytes. right = length - 1, left = 0
    addi s2, a0, -1
    add s1, x0, x0

    ## if file is empty (right = length-1 = -1 < 0), it is palindrome
    blt s2, x0, print_yes

    # remove \n in the end if any 
    # fseek(fp, right, SEEK_SET)
    add a0, s0, x0
    add a1, s2, x0
    add a2, x0, x0      # SEEK_SET = 0
    call fseek

    # fgetc(fp)
    add a0, s0, x0
    call fgetc

    ## if the last char is \n (ASCII 10), right--
    addi t0, x0, 10     
    bne a0, t0, loop_start
    
    addi s2, s2, -1

loop_start:
    # If left >= right, we checked the whole string
    bge s1, s2, print_yes

    # read left character
    # fseek(fp, left, SEEK_SET)
    add a0, s0, x0
    add a1, s1, x0
    add a2, x0, x0      
    call fseek

    # fgetc(fp)
    add a0, s0, x0
    call fgetc
    add s3, a0, x0      # Save char_left in s3 temporary

    # read right char by: 
    # fseek(fp, right, SEEK_SET)
    add a0, s0, x0
    add a1, s2, x0
    add a2, x0, x0      
    call fseek

    # fgetc(fp)
    add a0, s0, x0
    call fgetc          # char_right stays in a0

    ## if (char_left != char_right), jump to print_no
    bne s3, a0, print_no

    # left++
    addi s1, s1, 1
    # right--
    addi s2, s2, -1
    
    beq x0, x0, loop_start

print_no:
    la a0, no_str
    call printf
    beq x0, x0, close_file

print_yes:
    la a0, yes_str
    call printf

close_file:
    add a0, s0, x0
    call fclose

exit_main:
    add a0, x0, x0      

    ld s3, 0(sp)
    ld s2, 8(sp)
    ld s1, 16(sp)
    ld s0, 24(sp)
    ld ra, 32(sp)
    addi sp, sp, 40
    
    ret