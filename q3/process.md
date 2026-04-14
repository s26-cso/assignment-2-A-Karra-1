# CS2.201: Computer Systems Organization - Assignment 2

## Question 3: Binary Exploitation & Reverse Engineering

**Author:** A-Karra

---

### Overview
This document outlines the reverse-engineering methodology used to bypass the authentication mechanisms in the provided target binaries for Question 3.

### Part A: Static Analysis & Password Recovery
* **Target:** `a/target_A-Karra`
* **Payload:** `a/payload.txt`

#### Methodology:
1. The goal was to find the exact hardcoded password expected by the binary.
2. Instead of decompiling the entire execution flow, I utilized the `strings` command to extract all printable character sequences from the compiled binary.
3. By analyzing the output, I located the success string (`"You have passed!"`).
4. Because static strings are often grouped sequentially in the binary's read-only data segment (`.rodata`), I examined the strings immediately surrounding the success message and successfully identified the plaintext password.
5. This password was piped into the executable via `payload.txt`, achieving the exact output required.

### Part B: Buffer Overflow (Ret2Win)
* **Target:** `b/target_A-Karra`
* **Payload:** `b/payload`

#### Methodology:
1. The objective was to hijack the control flow of the binary to print the success message, bypassing the standard password check entirely.
2. **Reconnaissance:** Since the binary was compiled without Position Independent Executable (`-fno-PIE`, `-no-pie`) protections, function addresses were static. I used `objdump -d target_A-Karra` to disassemble the binary and located the memory address of the hidden "win" function responsible for printing `"You have passed!"`.
3. **Offset Discovery:** I tested the binary with increasingly large inputs to check for bounds-checking vulnerabilities. I identified the exact input length required to overflow the allocated buffer and cause a Segmentation Fault (`core dumped`), effectively calculating the distance from the buffer start to the saved Return Address (RA) on the stack.
4. **Payload Construction:** I crafted a binary payload consisting of `'q'`s to fill the buffer up to the crash offset. I then appended the exact hex address of the target "win" function (in little-endian format) to overwrite the Return Address.
5. **Execution:** Upon reaching the `ret` instruction, the CPU popped my injected address into the Program Counter, jumping execution to the hidden function and successfully printing the required output satisfying the passing criterion.
