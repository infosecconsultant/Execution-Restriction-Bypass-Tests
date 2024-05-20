#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <time.h>

void AppendTextToFile(const char* fileName, const char* message)
{
    FILE* file = fopen(fileName, "a");
    if (file != NULL)
    {
        time_t now = time(0);
        char* dt = ctime(&now);
        fprintf(file, "%s - %s\n", dt, message);
        fclose(file);
    }
}

extern "C" LONG APIENTRY CPlApplet(HWND hwndCPL, UINT uMsg, LPARAM lParam1, LPARAM lParam2)
{
    switch (uMsg)
    {
    case CPL_INIT:
        return TRUE;
    case CPL_GETCOUNT:
        return 1;
    case CPL_INQUIRE:
    {
        LPCPLINFO lpCplInfo = (LPCPLINFO)lParam2;
        lpCplInfo->idIcon = 101;
        lpCplInfo->idName = 102;
        lpCplInfo->idInfo = 103;
        lpCplInfo->lData = 0;
        break;
    }
    case CPL_DBLCLK:
        ShellExecute(NULL, L"open", L"calc.exe", NULL, NULL, SW_SHOWNORMAL);
        AppendTextToFile("BasicExecution.txt", "ControlPanel-ExecuteCalc.cpp executed successfully");
        break;
    }
    return 0;
}
