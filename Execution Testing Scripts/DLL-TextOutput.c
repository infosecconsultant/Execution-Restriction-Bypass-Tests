#include <windows.h>
#include <stdio.h>
#include <time.h>

__declspec(dllexport) void HelloWorld() {
    MessageBox(NULL, L"Purple Team Test", L"Hello", MB_OK);
    FILE *file = fopen("BasicOutput.txt", "a");
    if (file != NULL) {
        time_t now = time(NULL);
        fprintf(file, "%s - DLL-TextOutput.dll executed successfully\n", ctime(&now));
        fclose(file);
    }
}
