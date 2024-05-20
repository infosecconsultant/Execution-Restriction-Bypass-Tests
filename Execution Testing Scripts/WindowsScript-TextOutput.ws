<job>
    <script language="VBScript">
        MsgBox "Purple Team Test"
        Set objFSO = CreateObject("Scripting.FileSystemObject")
        Set objFile = objFSO.OpenTextFile("BasicOutput.txt", 8, True)
        objFile.WriteLine Now & " - WindowsScriptFile-TextOutput.ws executed successfully"
        objFile.Close
    </script>
</job>
