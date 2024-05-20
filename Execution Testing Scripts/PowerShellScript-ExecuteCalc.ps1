Start-Process "calc.exe"
Add-Content -Path "BasicExecution.txt" -Value ("{0} - PowerShellScript-ExecuteCalc.ps1 executed successfully" -f (Get-Date))
