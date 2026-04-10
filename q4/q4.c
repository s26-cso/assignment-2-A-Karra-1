#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int main(void) {
    char op[6];         /* op is at most 5 chars + null terminator */
    int num1, num2;

    char current_op[6] = "";   /* tracks which library is currently loaded */
    void *handle = NULL;        /* handle to the currently loaded library */

    while (scanf("%5s %d %d", op, &num1, &num2) == 3) {

        /* Only load a new library if the operation has changed */
        if (strcmp(op, current_op) != 0) {

            /* Unload the previous library before loading the new one.
               This ensures we never hold more than one 1.5GB library
               in memory at a time, keeping us within the 2GB limit. */
            if (handle != NULL) {
                dlclose(handle);
                handle = NULL;
            }

            /* Build the shared library filename: lib<op>.so */
            char libname[16]; /* "lib" (3) + 5 + ".so" (3) + '\0' (1) = 12, 16 is safe */
            snprintf(libname, sizeof(libname), "./lib%s.so", op);

            handle = dlopen(libname, RTLD_LAZY);
            if (handle == NULL) {
                fprintf(stderr, "Error loading library %s: %s\n", libname, dlerror());
                return 1;
            }

            strncpy(current_op, op, sizeof(current_op) - 1);
            current_op[sizeof(current_op) - 1] = '\0';
        }

        /* Look up the function with the same name as the operation */
        dlerror(); /* clear any existing error */

        typedef int (*op_func_t)(int, int);
        op_func_t func = (op_func_t) dlsym(handle, op);

        char *err = dlerror();
        if (err != NULL) {
            fprintf(stderr, "Error finding symbol %s: %s\n", op, err);
            dlclose(handle);
            return 1;
        }

        int result = func(num1, num2);
        printf("%d\n", result);
    }

    if (handle != NULL) {
        dlclose(handle);
    }

    return 0;
}