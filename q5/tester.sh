#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}       Q5 Palindrome Tester (O(1))      ${NC}"
echo -e "${YELLOW}========================================${NC}"

# 1. Compile the assembly
echo "⚙️  Compiling q5.s..."
gcc -g q5.s -o palindrome_test
if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed!${NC}"
    exit 1
fi

run_test() {
    local input_str="$1"
    local expected="$2"
    local test_name="$3"

    # Create the input.txt file without a trailing newline for pure string tests
    echo -n "$input_str" > input.txt
    
    # Run the binary
    local output=$(./palindrome_test | xargs)
    
    if [ "$output" == "$expected" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name"
    else
        echo -e "${RED}[FAIL]${NC} $test_name"
        echo "  Input   : '$input_str'"
        echo "  Expected: $expected"
        echo "  Got     : $output"
    fi
}

# 2. Basic Tests
echo -e "\n--- Standard Tests ---"
run_test "racecar" "Yes" "Odd length palindrome"
run_test "noon" "Yes" "Even length palindrome"
run_test "hello" "No" "Standard non-palindrome"
run_test "a" "Yes" "Single character"
run_test "" "Yes" "Empty file"

# 3. Newline Handling Test
echo -e "\n--- Newline Handling ---"
# Create a file that HAS a newline at the end
echo "madam" > input.txt
output=$(./palindrome_test | xargs)
if [ "$output" == "Yes" ]; then
    echo -e "${GREEN}[PASS]${NC} Palindrome with trailing newline"
else
    echo -e "${RED}[FAIL]${NC} Palindrome with trailing newline (Got: $output)"
fi

# 4. Stress Test (Large File)
echo -e "\n--- Stress Test (Long String) ---"
# Generate a 10,001 character palindrome ('a' x 5000 + 'b' + 'a' x 5000)
LARGE_PALI=$(printf 'a%.0s' {1..5000}; echo -n "b"; printf 'a%.0s' {1..5000})
run_test "$LARGE_PALI" "Yes" "10,001 char palindrome"

# Clean up
rm -f input.txt palindrome_test
echo -e "\n${YELLOW}========================================${NC}"