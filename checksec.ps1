<#
.SYNOPSIS
    Scan directories for write permissions, optionally copy & run a payload,
    and (optionally) execute every script found under an "Execution Testing Scripts" folder.

.EXAMPLE
    .\checksec.ps1 -RootDirectory "C:\Targets" `
                          -ExecutablePath "C:\payload\runner.exe" `
                          -ReportFilePath "C:\report.txt" `
                          -CheckMode Active `
                          -RunTestScripts `
                          -TestScriptsDirectory "C:\Execution Testing Scripts"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$RootDirectory,

    [string]$ExecutablePath,

    [Parameter(Mandatory = $true)]
    [string]$ReportFilePath,

    [int]$ExecutionTimeoutSeconds = 2,

    [ValidateSet("Passive", "Active")]
    [string]$CheckMode = "Passive",

    [switch]$RunTestScripts,
    [string]$TestScriptsDirectory,
    [string[]]$ScriptExtensions = @(
    # executable “payload”‑style
    '.exe', '.dll', '.scr', '.cpl', '.hta', '.jar',

    # Windows / CMD / PS / WSH
    '.bat', '.cmd',
    '.ps1', '.psc1', '.psm1',
    '.js',  '.vbs',
    '.ws',  '.wsf', '.wsh',
    '.sct', '.wsc',

    # installers / setup
    '.inf',

    # source files you still want logged / tried
    '.asm', '.c', '.cpp', '.cs', '.vb'
    ),

    [switch]$failexec,
    [switch]$failwrite
)

# --- GUARD RAILS FOR NEW FEATURE ---
if ($RunTestScripts -and -not $TestScriptsDirectory) {
    throw "Parameter -TestScriptsDirectory is required when -RunTestScripts is specified."
}

# ────────────────────────────────────────────────────────────────────────────────
# Helper: Am I admin?
function Test-IsAdmin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = [System.Security.Principal.WindowsPrincipal]::new($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Helper: Which user?
function Get-CurrentUsername {
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

if (Test-IsAdmin) {
    Write-Warning "The script is running with administrator permissions."
}
Write-Verbose "Running as: $(Get-CurrentUsername)"

# ────────────────────────────────────────────────────────────────────────────────
# Global collectors
$script:writeableDirectories            = @()
$script:executionSuccessDirectories     = @()
$script:executionFailDirectories        = @()
$script:writePermissionFailDirectories  = @()
$script:testScriptExecutionSuccessFiles = @()
$script:testScriptExecutionFailFiles    = @()

# ────────────────────────────────────────────────────────────────────────────────
# Check write permission
function Test-WritePermission {
    param([string]$Path)

    $testFilePath      = Join-Path $Path "testperm.tmp"
    $hasWritePermission = $false
    try {
        New-Item -Path $testFilePath -ItemType File -Force -ErrorAction Stop | Out-Null
        Remove-Item -Path $testFilePath -Force -ErrorAction Stop
        $hasWritePermission = $true
        Write-Verbose "Write permission confirmed for $Path"
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning "Unauthorized access for $Path"
        if ($failwrite) { $script:writePermissionFailDirectories += $Path }
    }
    catch {
        Write-Error "Error testing $Path : $_"
        if ($failwrite) { $script:writePermissionFailDirectories += $Path }
    }
    return $hasWritePermission
}

# ────────────────────────────────────────────────────────────────────────────────
# Copy payload → run → clean
function Execute-And-Cleanup {
    param([string]$Path)

    $execName = Split-Path $ExecutablePath -Leaf
    $execPath = Join-Path $Path $execName
    Write-Verbose "Copying $ExecutablePath → $execPath"

    try {
        Copy-Item -Path $ExecutablePath -Destination $execPath -ErrorAction Stop
        $process = Start-Process -FilePath $execPath -PassThru -ErrorAction Stop
        $process.WaitForExit($ExecutionTimeoutSeconds * 1000) | Out-Null
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        return $true
    }
    catch {
        Write-Warning "Execution failed in $Path : $_"
        if ($failexec) { $script:executionFailDirectories += $Path }
        return $false
    }
    finally {
        if (Test-Path $execPath) {
            Remove-Item -Path $execPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# ────────────────────────────────────────────────────────────────────────────────
# NEW: Fire test script with best‑guess host
function Execute-TestScript {
    param([string]$ScriptPath)

    try {
        $ext = ([IO.Path]::GetExtension($ScriptPath)).ToLowerInvariant()
        switch ($ext) {
        
            '.bat' { $proc = Start‑Process 'cmd.exe'  -Arg "/c","`"$ScriptPath`"" -Win Hidden -PassThru -EA Stop }
            '.cmd' { $proc = Start‑Process 'cmd.exe'  -Arg "/c","`"$ScriptPath`"" -Win Hidden -PassThru -EA Stop }
        
            '.psc1'{ $proc = Start‑Process 'powershell.exe' -Arg '-NoLogo','-PSConsoleFile',"`"$ScriptPath`"" -Win Hidden -PassThru -EA Stop }
            '.psm1'{ $proc = Start‑Process 'powershell.exe' -Arg '-NoLogo','-Command',"Import‑Module -Force `"$ScriptPath`""         -Win Hidden -PassThru -EA Stop }
        
            '.jar' { $proc = Start‑Process 'java.exe' -Arg '-jar',"`"$ScriptPath`"" -Win Hidden -PassThru -EA Stop }
        
            '.ws'  | '.wsf' | '.wsh' { $proc = Start‑Process 'wscript.exe' -Arg "`"$ScriptPath`"" -Win Hidden -PassThru -EA Stop }
        
            '.inf' { $proc = Start‑Process 'rundll32.exe' -Arg 'advpack.dll,LaunchINFSection',"`"$ScriptPath`",DefaultInstall" -PassThru -EA Stop }
        
            '.sct' | '.wsc' { $proc = Start‑Process 'regsvr32.exe' -Arg '/s','/n','/u',"/i:`"$ScriptPath`"",'scrobj.dll' -PassThru -EA Stop }
        
            default {            # .exe, .scr, .dll, .asm, .c, .cpp, .cs, .vb, anything unknown
                $proc = Start‑Process $ScriptPath -Win Hidden -PassThru -EA Stop
            }
        }
        $proc.WaitForExit($ExecutionTimeoutSeconds * 1000) | Out-Null
        if (-not $proc.HasExited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
        return $true
    }
    catch {
        Write-Warning "Script failed: $ScriptPath : $_"
        return $false
    }
}

# ────────────────────────────────────────────────────────────────────────────────
# 1 WRITE PERMISSION SCAN  ────────────────────────────────────────────────
Write-Verbose "Scanning $RootDirectory for write permissions."

$directories = Get-ChildItem -Path $RootDirectory -Recurse -Directory -ErrorAction SilentlyContinue
$allItems    = @((Get-Item -LiteralPath $RootDirectory)) + $directories

foreach ($dir in $allItems) {
    if (Test-WritePermission -Path $dir.FullName) {
        $script:writeableDirectories += $dir.FullName
        if ($CheckMode -eq "Active" -and $ExecutablePath) {
            if (Execute-And-Cleanup -Path $dir.FullName) {
                $script:executionSuccessDirectories += $dir.FullName
            }
        }
    }
}

# 2 OPTIONAL TEST SCRIPT EXECUTION  ──────────────────────────────────────
if ($RunTestScripts) {
    Write-Verbose "Executing scripts under $TestScriptsDirectory ..."
    $scriptFiles = Get-ChildItem -Path $TestScriptsDirectory -Recurse -File -ErrorAction SilentlyContinue |
                   Where-Object { $ScriptExtensions -contains $_.Extension.ToLower() }

    foreach ($file in $scriptFiles) {
        if (Execute-TestScript -ScriptPath $file.FullName) {
            $script:testScriptExecutionSuccessFiles += $file.FullName
        }
        else {
            $script:testScriptExecutionFailFiles += $file.FullName
        }
    }
    Write-Verbose "Completed execution of $($scriptFiles.Count) test scripts."
}

# ────────────────────────────────────────────────────────────────────────────────
# REPORT  ────────────────────────────────────────────────────────────────────────
Write-Verbose "Generating report …"

$reportContent  = "Writeable Directories:`n" +
                  ($writeableDirectories -join "`n") +
                  "`n`nDirectories Where Execution Succeeded:`n" +
                  ($executionSuccessDirectories -join "`n")

if ($failexec) {
    $reportContent += "`n`nDirectories Where Execution Failed:`n" +
                      ($executionFailDirectories -join "`n")
}
if ($failwrite) {
    $reportContent += "`n`nDirectories Where Write Permission Check Failed:`n" +
                      ($writePermissionFailDirectories -join "`n")
}
if ($RunTestScripts) {
    $reportContent += "`n`nTest Scripts Executed Successfully:`n" +
                      ($testScriptExecutionSuccessFiles -join "`n")
    if ($testScriptExecutionFailFiles.Count -gt 0) {
        $reportContent += "`n`nTest Scripts That Failed:`n" +
                          ($testScriptExecutionFailFiles -join "`n")
    }
}

$reportContent | Out-File -FilePath $ReportFilePath -Encoding UTF8

if ($VerbosePreference -eq 'Continue') {
    Write-Host "`n===== REPORT ====="
    Write-Host $reportContent
}

Write-Verbose "Report saved to $ReportFilePath"
Write-Verbose "Script complete."
