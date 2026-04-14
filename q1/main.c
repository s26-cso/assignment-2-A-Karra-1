#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

// Struct definition ensuring 8-byte alignment for pointers on 64-bit systems
// This perfectly matches your NODE_VAL=0, NODE_LEFT=8, NODE_RIGHT=16 assembly offsets.
struct Node {
    int val;
    struct Node* left;
    struct Node* right;
};

// Extern declarations mapping to your RISC-V assembly functions
extern struct Node* make_node(int val);
extern struct Node* insert(struct Node* root, int val);
extern struct Node* get(struct Node* root, int val);
extern int getAtMost(int val, struct Node* root);

// Global test counters
int test_count = 0;
int pass_count = 0;

// Custom assertion macros for clean output
#define ASSERT_EQ(actual, expected, msg) do { \
    test_count++; \
    if ((actual) == (expected)) { pass_count++; } \
    else { printf("[FAIL] Test %d: %s. Expected %d, got %d\n", test_count, msg, (int)(expected), (int)(actual)); } \
} while(0)

#define ASSERT_PTR_EQ(actual, expected, msg) do { \
    test_count++; \
    if ((actual) == (expected)) { pass_count++; } \
    else { printf("[FAIL] Test %d: %s. Expected %p, got %p\n", test_count, msg, (void*)(expected), (void*)(actual)); } \
} while(0)

#define ASSERT_PTR_NEQ(actual, expected, msg) do { \
    test_count++; \
    if ((actual) != (expected)) { pass_count++; } \
    else { printf("[FAIL] Test %d: %s. Pointer should not be %p\n", test_count, msg, (void*)(expected)); } \
} while(0)


int main() {
    printf("========================================\n");
    printf("   BST RISC-V Assembly Stress Test      \n");
    printf("========================================\n\n");

    // ---------------------------------------------------------
    // Phase 1: Core Memory & Base Cases
    // ---------------------------------------------------------
    struct Node* single = make_node(42);
    ASSERT_PTR_NEQ(single, NULL, "make_node should return a valid pointer");
    ASSERT_EQ(single->val, 42, "make_node should set correct value");
    ASSERT_PTR_EQ(single->left, NULL, "make_node should initialize left pointer to NULL");
    ASSERT_PTR_EQ(single->right, NULL, "make_node should initialize right pointer to NULL");

    struct Node* neg_node = make_node(-999);
    ASSERT_EQ(neg_node->val, -999, "make_node should handle negative values");

    struct Node* zero_node = make_node(0);
    ASSERT_EQ(zero_node->val, 0, "make_node should handle zero");

    // ---------------------------------------------------------
    // Phase 2: Edge Cases on Empty / Single Node Trees
    // ---------------------------------------------------------
    ASSERT_PTR_EQ(get(NULL, 10), NULL, "get on NULL root should return NULL");
    ASSERT_EQ(getAtMost(10, NULL), -1, "getAtMost on NULL root should return -1");

    ASSERT_PTR_EQ(get(single, 42), single, "get should find the root node");
    ASSERT_PTR_EQ(get(single, 10), NULL, "get should return NULL for missing value in single node tree");

    ASSERT_EQ(getAtMost(42, single), 42, "getAtMost for exact root match");
    ASSERT_EQ(getAtMost(50, single), 42, "getAtMost for target > root in single node tree");
    ASSERT_EQ(getAtMost(10, single), -1, "getAtMost for target < root in single node tree");

    // ---------------------------------------------------------
    // Phase 3: Skewed Tree Dynamics (Left and Right)
    // ---------------------------------------------------------
    struct Node* left_skewed = NULL;
    for (int i = 10; i > 0; i--) {
        left_skewed = insert(left_skewed, i);
    }
    ASSERT_EQ(getAtMost(0, left_skewed), -1, "Left-skewed tree: getAtMost below all values");
    ASSERT_EQ(getAtMost(11, left_skewed), 10, "Left-skewed tree: getAtMost above all values");
    ASSERT_PTR_NEQ(get(left_skewed, 1), NULL, "Left-skewed tree: get deepest node");

    struct Node* right_skewed = NULL;
    for (int i = 1; i <= 10; i++) {
        right_skewed = insert(right_skewed, i);
    }
    ASSERT_EQ(getAtMost(0, right_skewed), -1, "Right-skewed tree: getAtMost below all values");
    ASSERT_EQ(getAtMost(11, right_skewed), 10, "Right-skewed tree: getAtMost above all values");
    ASSERT_PTR_NEQ(get(right_skewed, 10), NULL, "Right-skewed tree: get deepest node");

    // ---------------------------------------------------------
    // Phase 4: Fuzz Testing (Volume and Pattern Recognition)
    // ---------------------------------------------------------
    // We will build a complex tree with 100 elements.
    // To ensure reproducible tests, we use a deterministic "random" array.
    struct Node* large_tree = NULL;
    int test_data[100];
    
    // Generate 100 numbers: 0, 10, 20... 990
    for(int i = 0; i < 100; i++) {
        test_data[i] = i * 10;
    }

    // Insert them in a pseudo-random order to balance the tree somewhat
    for(int i = 0; i < 100; i++) {
        int index = (i * 37) % 100; // Scrambled insertion
        large_tree = insert(large_tree, test_data[index]);
    }

    // Now, run 100 queries for exact `get` matches
    for(int i = 0; i < 100; i++) {
        struct Node* res = get(large_tree, i * 10);
        ASSERT_PTR_NEQ(res, NULL, "Fuzz get: node should exist");
        if (res != NULL) {
            ASSERT_EQ(res->val, i * 10, "Fuzz get: value should match exactly");
        } else {
            test_count++; // skip to keep count aligned if a previous failed
        }
    }

    // Run 100 queries for missing `get` values (shifted by +5)
    for(int i = 0; i < 100; i++) {
        struct Node* res = get(large_tree, (i * 10) + 5);
        ASSERT_PTR_EQ(res, NULL, "Fuzz get: missing node should return NULL");
    }

    // Run 100 `getAtMost` queries falling exactly ON the nodes
    for(int i = 0; i < 100; i++) {
        int val = getAtMost(i * 10, large_tree);
        ASSERT_EQ(val, i * 10, "Fuzz getAtMost: exact match check");
    }

    // Run 100 `getAtMost` queries falling BETWEEN the nodes
    // e.g., getAtMost(15) should return 10. getAtMost(25) should return 20.
    for(int i = 0; i < 100; i++) {
        int target = (i * 10) + 7; // e.g., 7, 17, 27...
        int expected = i * 10;     // e.g., 0, 10, 20...
        int val = getAtMost(target, large_tree);
        ASSERT_EQ(val, expected, "Fuzz getAtMost: floor value check");
    }

    // ---------------------------------------------------------
    // Phase 5: Deep Negatives & Off-by-one Edge Cases
    // ---------------------------------------------------------
    struct Node* neg_tree = NULL;
    neg_tree = insert(neg_tree, -50);
    neg_tree = insert(neg_tree, -100);
    neg_tree = insert(neg_tree, -25);
    
    ASSERT_EQ(getAtMost(-100, neg_tree), -100, "Negative Tree: exact lowest bound");
    ASSERT_EQ(getAtMost(-101, neg_tree), -1, "Negative Tree: out of lower bounds");
    ASSERT_EQ(getAtMost(-26, neg_tree), -50, "Negative Tree: intermediate floor");
    ASSERT_EQ(getAtMost(0, neg_tree), -25, "Negative Tree: above all values");

    // ---------------------------------------------------------
    // Results
    // ---------------------------------------------------------
    printf("\n========================================\n");
    if (pass_count == test_count) {
        printf("   ALL %d TESTS PASSED! FLAWLESS! \n", pass_count);
    } else {
        printf("   FAILED: %d out of %d passed.\n", pass_count, test_count);
    }
    printf("========================================\n");

    return 0;
}