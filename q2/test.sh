#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Trackers
TOTAL_TESTS=0
PASSED_TESTS=0

# 1. Compile the assembly file
echo "⚙️  Compiling q2.s..."
gcc -g q2.s -o q2_test
if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed!${NC}"
    exit 1
fi
echo -e "${GREEN}Compilation successful.${NC}\n"

# Helper to calculate the correct NGE natively in Bash (Brute force for absolute accuracy)
calculate_expected_nge() {
    local arr=("$@")
    local n=${#arr[@]}
    local res=()
    
    for ((i=0; i<n; i++)); do
        local found=-1
        for ((j=i+1; j<n; j++)); do
            if (( arr[j] > arr[i] )); then
                found=$j
                break
            fi
        done
        res+=($found)
    done
    echo "${res[@]}"
}

# Test runner function
run_test() {
    local expected="$1"
    local silent="$2"
    shift 2
    local input=("$@")
    
    ((TOTAL_TESTS++))
    
    # Run binary and strip trailing spaces
    local output=$(./q2_test "${input[@]}" | xargs) 
    
    if [ "$output" == "$expected" ]; then
        ((PASSED_TESTS++))
        if [ "$silent" != "true" ]; then
            echo -e "${GREEN}[PASS]${NC} Input: ${input[*]}"
        fi
    else
        echo -e "${RED}[FAIL]${NC} Test $TOTAL_TESTS"
        echo "  Input   : ${input[*]}"
        echo "  Expected: $expected"
        echo "  Got     : $output"
    fi
}

echo -e "${YELLOW}--- Phase 1: Assignment Examples & Core Edge Cases ---${NC}"

# Document Examples
run_test "1 4 3 4 -1" "false" 85 96 70 80 102
run_test "2 2 4 4 -1 -1 -1" "false" 91 10 99 93 109 90 78

# Extreme Edge Cases
run_test "" "false"                                # Empty input
run_test "-1" "false" 42                           # Single element
run_test "-1 -1 -1 -1 -1" "false" 5 5 5 5 5        # All duplicates (Flatline)
run_test "1 2 3 4 -1" "false" 1 2 3 4 5            # Strictly ascending
run_test "-1 -1 -1 -1 -1" "false" 5 4 3 2 1        # Strictly descending
run_test "1 2 3 4 -1" "false" -10 -5 0 5 10        # Negatives ascending
run_test "-1 -1 -1 -1 -1" "false" 10 5 0 -5 -10    # Negatives descending
run_test "1 2 3 -1 -1" "false" -50 0 50 100 -100   # Mixed extreme signs
run_test "-1 4 3 4 -1" "false" 10 5 1 5 10         # V-Shape (Valley) -> CORRECTED
run_test "1 2 -1 -1 -1" "false" 1 5 10 5 1         # A-Shape (Mountain) -> CORRECTED
run_test "4 4 4 4 -1 -1" "false" 0 0 0 0 1 0       # Plateau followed by spike -> CORRECTED

echo -e "\n${YELLOW}--- Phase 2: Dynamic Fuzz Testing (100 Random Arrays) ---${NC}"
echo "Throwing 100 random arrays at the binary (lengths 5 to 30, values -100 to 100)..."

FUZZ_PASS=0
for ((t=1; t<=100; t++)); do
    # Generate random length between 5 and 30
    len=$(( RANDOM % 26 + 5 ))
    arr=()
    
    # Populate array with random values between -100 and 100
    for ((i=0; i<len; i++)); do
        val=$(( RANDOM % 201 - 100 ))
        arr+=($val)
    done
    
    # Calculate truth
    expected=$(calculate_expected_nge "${arr[@]}")
    
    # Run test silently (only prints on fail)
    start_fails=$TOTAL_TESTS
    passed_before=$PASSED_TESTS
    
    run_test "$expected" "true" "${arr[@]}"
    
    if (( PASSED_TESTS > passed_before )); then
        ((FUZZ_PASS++))
    fi
done

echo -e "${GREEN}Passed $FUZZ_PASS / 100 random fuzz tests.${NC}"

echo -e "\n========================================"
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "   ${GREEN}🎉 ALL $TOTAL_TESTS TESTS PASSED! PERFECT!${NC}"
else
    echo -e "   ${RED}❌ FAILED: $PASSED_TESTS / $TOTAL_TESTS passed.${NC}"
fi
echo "========================================"