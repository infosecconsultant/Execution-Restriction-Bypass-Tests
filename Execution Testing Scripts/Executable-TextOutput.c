#include <stdio.h>
#include <time.h>

int main() {
    printf("Purple Team Test\n");
    FILE *file = fopen("BasicOutput.txt", "a");
    if (file != NULL) {
        time_t now = time(NULL);
        fprintf(file, "%s - Executable-TextOutput.exe executed successfully\n", ctime(&now));
        fclose(file);
    }
    return 0;
}
