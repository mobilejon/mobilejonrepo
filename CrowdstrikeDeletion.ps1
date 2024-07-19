# Define the target directory and file pattern
$targetDirectory = "C:\Windows\System32\drivers\CrowdStrike"
$filePattern = "C-00000291*.sys"

# Get the list of files matching the pattern in the target directory
$files = Get-ChildItem -Path $targetDirectory -Filter $filePattern

# Initialize an array to store problematic files
$problematicFiles = @()

# Iterate through each file and check the timestamp
foreach ($file in $files) {
    # Get the file's LastWriteTime
    $lastWriteTimeUTC = $file.LastWriteTimeUtc

    # Check if the LastWriteTime matches the problematic timestamp (04:09 UTC)
    if ($lastWriteTimeUTC.Hour -eq 4 -and $lastWriteTimeUTC.Minute -eq 9) {
        # Add the file to the problematic files array
        $problematicFiles += $file
    }
}

# Delete the problematic files
if ($problematicFiles.Count -gt 0) {
    Write-Output "Deleting problematic files:"
    $problematicFiles | ForEach-Object {
        Write-Output "Deleting $_.FullName"
        Remove-Item -Path $_.FullName -Force
    }
    Write-Output "Problematic files deleted."
} else {
    Write-Output "No problematic files to delete."
}
