# Define the path to officec2rclient.exe
$officeC2RClientPath = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\officec2rclient.exe"

# Define the command and arguments to update to a specific version
$arguments = "/update user updatetoversion=17928.20156"

# Check if the officec2rclient.exe exists
if (Test-Path $officeC2RClientPath) {
    # Execute the officec2rclient.exe with the specified arguments
    Start-Process -FilePath $officeC2RClientPath -ArgumentList $arguments -Wait
    Write-Output "Office update initiated to version 17928.20156."
} else {
    Write-Output "The officec2rclient.exe was not found at the specified path."
}
