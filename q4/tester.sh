#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}--- Q4 COMPREHENSIVE AUTOGRADER SIMULATOR ---${NC}"

# 1. Setup Phase: Create multiple shared libraries
create_lib() {
    local name=$1
    local op_logic=$2
    echo "int ${name}(int a, int b) { ${op_logic} }" > "temp_${name}.c"
    gcc -shared -fPIC "temp_${name}.c" -o "lib${name}.so"
    rm "temp_${name}.c"
}

echo "🔨 Building test environment..."
create_lib "add" "return a + b;"
create_lib "sub" "return a - b;"
create_lib "mul" "return a * b;"
create_lib "max" "return (a > b) ? a : b;"
create_lib "min" "return (a < b) ? a : b;"

# 2. Compile q4.c
gcc -g q4.c -o calc_app -ldl
if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed! Check your #include <dlfcn.h> and -ldl flag.${NC}"
    exit 1
fi

# 3. Define Test Cases
# Format: "Input_String|Expected_Output"
TESTS=(
    "add 10 5|15"
    "sub 20 8|12"
    "mul 6 7|42"
    "max 100 200|200"
    "min -50 20|-50"
    "add 1 1|2"    # Test switching back to a previously loaded lib
    "add 100 200|300" # Test staying on the same lib
)

PASSED=0
TOTAL=${#TESTS[@]}

echo -e "\n🚀 Running $TOTAL Test Cases..."

for test in "${TESTS[@]}"; do
    IFS='|' read -r input expected <<< "$test"
    
    # Run the app and get result
    # We use 'head -n 1' to just get the first line of output for that specific command
    actual=$(echo "$input" | LD_LIBRARY_PATH=. ./calc_app | xargs)
    
    if [ "$actual" == "$expected" ]; then
        echo -e "${GREEN}[PASS]${NC} Input: $input -> Expected: $expected, Got: $actual"
        ((PASSED++))
    else
        echo -e "${RED}[FAIL]${NC} Input: $input -> Expected: $expected, Got: '$actual'"
    fi
done

# 4. Final Verdict
echo -e "\n========================================"
if [ $PASSED -eq $TOTAL ]; then
    echo -e "   ${GREEN}RESULT: $PASSED/$TOTAL PASSED${NC}"
    echo "   Your caching/dlclose logic looks solid!"
else
    echo -e "   ${RED}RESULT: $PASSED/$TOTAL PASSED${NC}"
fi
echo -e "========================================\n"

# Clean up libs
rm -f libadd.so libsub.so libmul.so libmax.so libmin.so calc_app