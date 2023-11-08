#A simple script to check and test for application whitelisting direcotries that have been inadvertently whitelisted that also allow writes in the context of a user you control.

param(
    [Parameter(Mandatory=$true)]
    [string]$RootDirectory,

    [string]$ExecutablePath,

    [Parameter(Mandatory=$true)]
    [string]$ReportFilePath,

    [int]$ExecutionTimeoutSeconds = 2,
    [ValidateSet("Passive", "Active")]
    [string]$CheckMode = "Passive",

    [switch]$failexec,
    [switch]$failwrite
)

# Check if the user is running as administrator
function Test-IsAdmin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = new-object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Get the current username
function Get-CurrentUsername {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentUser.Name
}

# Check for admin rights at the start of the script
if (Test-IsAdmin) {
    Write-Warning "The script is running with administrator permissions."
}

# Report the username under which the script is running
$currentUsername = Get-CurrentUsername
Write-Verbose "The script is running under the username: $currentUsername"


# Initialize the results lists at the script scope
$script:writeableDirectories = @()
$script:executionSuccessDirectories = @()
$script:executionFailDirectories = @()
$script:writePermissionFailDirectories = @()

# Function to test write permission
function Test-WritePermission {
    param ([string]$path)

    $testFilePath = Join-Path -Path $path -ChildPath "testperm.tmp"
    $hasWritePermission = $false

    try {
        New-Item -Path $testFilePath -ItemType "file" -Force -ErrorAction Stop | Out-Null
        Remove-Item -Path $testFilePath -Force -ErrorAction Stop
        $hasWritePermission = $true
        Write-Verbose "Write permission confirmed for ${path}."
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning "Unauthorized access to the permissions of ${path}, skipping..."
        if ($failwrite) {
            $script:writePermissionFailDirectories += $path
        }
    }
    catch {
        Write-Error "Error testing permissions for ${path}: $_"
        if ($failwrite) {
            $script:writePermissionFailDirectories += $path
        }
    }

    return $hasWritePermission
}

# Function to execute and remove the executable
function Execute-And-Cleanup {
    param ([string]$path)

    $execName = Split-Path -Path $ExecutablePath -Leaf
    $execPath = Join-Path -Path $path -ChildPath $execName
    Write-Verbose "Attempting to copy $ExecutablePath to $execPath."
    
    try {
        Copy-Item -Path $ExecutablePath -Destination $execPath -ErrorAction Stop
        Write-Verbose "Successfully copied executable to $execPath."
        $process = Start-Process -FilePath $execPath -PassThru -ErrorAction Stop
        Write-Verbose "Process with ID $($process.Id) started, waiting for exit."
        $process.WaitForExit($ExecutionTimeoutSeconds * 500) | Out-Null
        if (-not $process.HasExited) {
            Write-Verbose "Process with ID $($process.Id) did not exit on its own, attempting to terminate."
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        return $true
    } catch {
        Write-Warning "Execution failed or was skipped in: $execPath. $_"
        if ($failexec) {
            $script:executionFailDirectories += $path
        }
        return $false
    } finally {
        if (Test-Path $execPath) {
            Write-Verbose "Attempting to remove executable: $execPath."
            Remove-Item -Path $execPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main script logic
Write-Verbose "Starting scan for write permissions in $RootDirectory."
# Include the root directory in the list of directories to check
$directories = Get-ChildItem -Path $RootDirectory -Recurse -Directory -ErrorAction SilentlyContinue
$rootItem = Get-Item -Path $RootDirectory
$allItems = @($rootItem) + $directories

foreach ($dir in $allItems) {
    Write-Verbose "Checking permissions for directory: $($dir.FullName)"
    $hasWritePermission = Test-WritePermission -path $dir.FullName
    if ($hasWritePermission) {
        Write-Verbose "Directory is writeable: $($dir.FullName)"
        $script:writeableDirectories += $dir.FullName
        if ($CheckMode -eq "Active") {
            Write-Verbose "Attempting to execute and cleanup in: $($dir.FullName)"
            $executionSucceeded = Execute-And-Cleanup -path $dir.FullName
            if ($executionSucceeded) {
                Write-Verbose "Execution succeeded in: $($dir.FullName)"
                $script:executionSuccessDirectories += $dir.FullName
            } else {
                Write-Warning "Execution failed or was skipped in: $($dir.FullName)"
            }
        }
    } else {
        Write-Warning "No write permissions or skipping directory due to errors: $($dir.FullName)"
    }
}

Write-Verbose "Finished checking directories. Generating report."

# Generate the report content
$reportContent = "Writeable Directories:`n" +
                 ($writeableDirectories -join "`n") +
                 "`n`nDirectories Where Execution Succeeded:`n" +
                 ($executionSuccessDirectories -join "`n")

# Append failed execution directories if switch is used
if ($failexec) {
    $reportContent += "`n`nDirectories Where Execution Failed:`n" + ($executionFailDirectories -join "`n")
}

# Append failed write permission directories if switch is used
if ($failwrite) {
    $reportContent += "`n`nDirectories Where Write Permission Failed:`n" + ($writePermissionFailDirectories -join "`n")
}

# Write the report content to the specified report file
$reportContent | Out-File -FilePath $ReportFilePath -Encoding UTF8

# Output the report content to the console
if ($VerbosePreference -eq 'Continue') {
    Write-Host "Report Content:"
    Write-Host $reportContent
}

Write-Verbose "Report has been saved to $ReportFilePath."
Write-Verbose "Script execution complete."
