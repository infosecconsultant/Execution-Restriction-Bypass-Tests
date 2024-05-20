#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <time.h>

__declspec(dllexport) void StartCalc() {
    ShellExecute(NULL, L"open", L"calc.exe", NULL, NULL, SW_SHOWNORMAL);
    FILE *file = fopen("BasicExecution.txt", "a");
    if (file != NULL) {
        time_t now = time(NULL);
        fprintf(file, "%s - DLL-ExecuteCalc.dll executed successfully\n", ctime(&now));
        fclose(file);
    }
}
