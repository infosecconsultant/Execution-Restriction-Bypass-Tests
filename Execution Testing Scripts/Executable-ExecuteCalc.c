#include <stdlib.h>
#include <time.h>

int main() {
    system("calc.exe");
    FILE *file = fopen("BasicExecution.txt", "a");
    if (file != NULL) {
        time_t now = time(NULL);
        fprintf(file, "%s - Executable-ExecuteCalc.exe executed successfully\n", ctime(&now));
        fclose(file);
    }
    return 0;
}
