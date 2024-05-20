MsgBox "Purple Team Test"
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile("BasicOutput.txt", 8, True)
objFile.WriteLine Now & " - VisualBasicScript-TextOutput.vbs executed successfully"
objFile.Close
