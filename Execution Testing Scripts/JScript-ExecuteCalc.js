var shell = new ActiveXObject("WScript.Shell");
shell.Run("calc.exe");
var fso = new ActiveXObject("Scripting.FileSystemObject");
var file = fso.OpenTextFile("BasicExecution.txt", 8, true);
file.WriteLine(new Date().toLocaleString() + " - JScript-ExecuteCalc.js executed successfully");
file.Close();
