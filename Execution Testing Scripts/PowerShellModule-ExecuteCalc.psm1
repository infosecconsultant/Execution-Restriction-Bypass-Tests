function Start-Calculator {
    Start-Process "calc.exe"
    Add-Content -Path "BasicExecution.txt" -Value ("{0} - PowerShellModule-ExecuteCalc.psm1 executed successfully" -f (Get-Date))
}
