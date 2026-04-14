#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0

# 1. Compile
echo "⚙️  Compiling q2.s..."
gcc -g q2.s -o q2_test
if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed!${NC}"
    exit 1
fi

# Helper: Brute force NGE for ground truth
calculate_expected_nge() {
    local arr=("$@")
    local n=${#arr[@]}
    local res=""
    
    for ((i=0; i<n; i++)); do
        local found=-1
        for ((j=i+1; j<n; j++)); do
            if (( arr[j] > arr[i] )); then
                found=$j
                break
            fi
        done
        # Construct string without trailing space
        if [ -z "$res" ]; then res="$found"; else res="$res $found"; fi
    done
    echo "$res"
}

# Test runner with STRICT whitespace check
run_test() {
    local expected="$1"
    local silent="$2"
    shift 2
    local input=("$@")
    
    ((TOTAL_TESTS++))
    
    # Capture raw output. $() strips the final newline, but NOT a trailing space.
    local raw_output=$(./q2_test "${input[@]}")
    
    # Strict comparison: check if raw_output matches expected exactly
    if [ "$raw_output" == "$expected" ]; then
        ((PASSED_TESTS++))
        if [ "$silent" != "true" ]; then
            echo -e "${GREEN}[PASS]${NC} Input: ${input[*]}"
        fi
    else
        echo -e "${RED}[FAIL]${NC} Test $TOTAL_TESTS"
        echo "  Input   : ${input[*]}"
        echo "  Expected: '$expected'"
        
        # Visualize the space error if it exists
        if [[ "$raw_output" == "$expected " ]]; then
            echo "  Got     : '$raw_output' <-- ERROR: Trailing space detected!"
        else
            echo "  Got     : '$raw_output'"
        fi
    fi
}

echo -e "${YELLOW}--- Running Strict Output Tests ---${NC}"

# Document Examples [cite: 91-94]
run_test "1 4 3 4 -1" "false" 85 96 70 80 102
run_test "2 2 4 4 -1 -1 -1" "false" 91 10 99 93 109 90 78

# Edge Cases [cite: 69-70, 78]
run_test "-1" "false" 42
run_test "-1 -1 -1 -1 -1" "false" 5 5 5 5 5
run_test "1 2 3 4 -1" "false" 1 2 3 4 5
run_test "-1 4 3 4 -1" "false" 10 5 1 5 10

echo -e "\n${YELLOW}--- Fuzz Testing (100 Random Arrays) ---${NC}"
for ((t=1; t<=100; t++)); do
    len=$(( RANDOM % 20 + 2 ))
    arr=()
    for ((i=0; i<len; i++)); do arr+=($(( RANDOM % 100 ))); done
    
    expected=$(calculate_expected_nge "${arr[@]}")
    run_test "$expected" "true" "${arr[@]}"
done

echo -e "\n========================================"
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "   ${GREEN}🎉 ALL $TOTAL_TESTS TESTS PASSED!${NC}"
else
    echo -e "   ${RED}❌ FAILED: $PASSED_TESTS / $TOTAL_TESTS passed.${NC}"
    echo "   Tip: If you see 'Trailing space detected', adjust your print loop."
fi