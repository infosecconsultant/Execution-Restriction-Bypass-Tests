WScript.Echo("Purple Team Test");
var fso = new ActiveXObject("Scripting.FileSystemObject");
var file = fso.OpenTextFile("BasicOutput.txt", 8, true);
file.WriteLine(new Date().toLocaleString() + " - JScript-TextOutput.js executed successfully");
file.Close();
