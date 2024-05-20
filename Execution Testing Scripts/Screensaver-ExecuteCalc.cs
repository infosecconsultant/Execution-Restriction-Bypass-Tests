
using System;
using System.Diagnostics;
using System.IO;

public class StartCalc
{
    static void Main()
    {
        Process.Start("calc.exe");
        File.AppendAllText("BasicExecution.txt", $"{DateTime.Now} - Screensaver-ExecuteCalc.scr executed successfully\n");
    }
}
