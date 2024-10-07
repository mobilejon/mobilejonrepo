# Define the path to the Word executable
$wordPath = "C:\Program Files\Microsoft Office\root\Office16\Winword.exe"

# Check if the file exists
if (Test-Path $wordPath) {
    # Get the file version information
    $fileVersionInfo = Get-Item $wordPath | Select-Object -ExpandProperty VersionInfo
    $wordVersion = $fileVersionInfo.FileVersion

    Write-Output "Microsoft Word Version: $wordVersion"

    # Check if the version is 18025.20104
    if ($wordVersion -eq "18025.20104") {
        Write-Output "Version 18025.20104 detected. Exiting with code 1."
        exit 1
    }
} else {
    Write-Output "Microsoft Word executable not found at the specified path."
}

# Default exit with code 0 (success) if no issues
exit 0
