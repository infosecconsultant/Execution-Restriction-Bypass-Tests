Set objShell = CreateObject("WScript.Shell")
objShell.Run "calc.exe"
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile("BasicExecution.txt", 8, True)
objFile.WriteLine Now & " - VisualBasicScript-ExecuteCalc.vbs executed successfully"
objFile.Close
