#include <stdio.h>

#include "../src/sum.h"

int main(void) {
    if (sum(2, 3) != 5) {
        fprintf(stderr, "FAIL: sum(2, 3) != 5\n");
        return 1;
    }
    puts("ok: sum");
    return 0;
}
