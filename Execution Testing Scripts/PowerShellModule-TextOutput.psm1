function Show-HelloWorld {
    Write-Host "Purple Team Test"
    Add-Content -Path "BasicOutput.txt" -Value ("{0} - PowerShellModule-TextOutput.psm1 executed successfully" -f (Get-Date))
}
