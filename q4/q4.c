#include <stdio.h>
#include <string.h>
#include <dlfcn.h>

/*

basically first take op num1 num2 as input then check if already the previous op was same.
if not then close the curr library
then use RTLD_LAZY flag while opening so that the library is only looked up if its function is mention
else it remains unresolved which is better

then by function pointers
dlsym returns the address of the required function and converts it into the general format which we have typedef here
so that it can be used for printing


*/

int main(void) {
    char op[6];
    int num1, num2;
    char current_op[6] = "";
    void *handle = NULL;

    while (scanf("%5s %d %d", op, &num1, &num2) == 3) {
        if (strcmp(op, current_op) != 0) {

            if (handle != NULL) dlclose(handle);
            char libname[20];
            snprintf(libname, sizeof(libname), "./lib%s.so", op);

            handle = dlopen(libname, RTLD_LAZY);
            strncpy(current_op, op, 5);
            current_op[5] = '\0';
        }

        typedef int (*op_func_t)(int, int);
        // function pointer mentioned raaaaahhhhhh
        op_func_t func = (op_func_t) dlsym(handle, op);
        printf("%d\n", func(num1, num2));
    }

    if (handle != NULL) dlclose(handle);

    return 0;
}