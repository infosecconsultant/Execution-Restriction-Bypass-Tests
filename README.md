# PowerShell Script for Directory and Execution Check

## Summary

This PowerShell script scans directories within a specified root directory for write permissions and optionally attempts to execute a given executable in each writeable directory. It generates a report with a list of directories where write permissions exist and where the executable was successfully executed. The script also supports command-line arguments for root directory, executable path, and report file path.

## Prerequisites

Before running the script, ensure that you have the following:

- PowerShell 5.0 or higher.
- Necessary permissions to access and write to the directories you wish to scan.
- The execution policy set to allow the script to run. This can be set via the `Set-ExecutionPolicy` cmdlet. For example:
  
```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage

To run the script, use the following syntax from the PowerShell command line:

```
.\DirectoryExecutionCheck.ps1 -RootDirectory "C:\path_to_scan\" -ExecutablePath "C:\path_to.exe" -ReportFilePath "C:\path_to_report.txt"
```


### Parameters
* -RootDirectory [string]: The root directory where the script will begin scanning for writeable directories.
* -ReportFilePath [string]: The path where the script will output its report.

### Optional Parameters
* -ExecutablePath [string]: The full path to the executable that will be copied and executed in writeable directories.
* -ExecutionTimeoutSeconds [int]: The maximum amount of time, in seconds, to wait for the executable to run before timing out (default is 30 seconds).
* -CheckMode [string]: The mode of operation, either "Passive" or "Active". "Passive" will only check for write permissions, while "Active" will also attempt to execute the provided executable (default is "Passive").


## Script Functions
* Test-IsAdmin: Checks if the script is running with administrator privileges.
* Get-CurrentUsername: Retrieves the current username under which the script is running.
* Test-WritePermission: Tests write permissions on a given directory.
* Execute-And-Cleanup: Attempts to execute the provided executable in a given directory and then removes it.
