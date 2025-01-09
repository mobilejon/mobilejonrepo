# Define the target certificate store
$certStore = "Cert:\LocalMachine\My"

# Initialize $UPN variable
$UPN = $null

# Search for the Intune certificate based on the Issuer
$intuneCert = Get-ChildItem -Path $certStore | Where-Object {
    $_.Issuer -like "*CN=Microsoft Intune MDM Device CA*"
}

# Check if the certificate is found
if ($intuneCert) {
    $certThumbprint = $intuneCert.Thumbprint

    # Path to the enrollments registry key
    $enrollmentsPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"

    # Loop through each subkey to match the DMPCertThumbPrint
    Get-ChildItem -Path $enrollmentsPath | ForEach-Object {
        $enrollment = Get-ItemProperty -Path $_.PSPath
        if ($enrollment.DMPCertThumbPrint -eq $certThumbprint) {
            # Store the UPN in the $UPN variable
            $UPN = $enrollment.UPN
        }
    }
}

# Proceed if $UPN is found
if ($UPN) {
    # Extract the numeric part (XXXX) from the UPN
    if ($UPN -match "\d+") {
        $numbers = $matches[0]
    } else {
        Write-Host "No numeric part found in UPN. Exiting script."
        Exit 1 # Exit with an error code
    }

    # Construct the updated computer name
    $updatedComputerName = ""

    # Set the computer name
    Write-Host "Renaming computer to $($updatedComputerName)"
    Rename-Computer -NewName $updatedComputerName -Force

    # Make sure we reboot if still in ESP/OOBE by reporting a 1641 return code (hard reboot)
    if ($details.CsUserName -match "defaultUser") {
        Write-Host "Exiting during ESP/OOBE with return code 1641"
        Exit 1641
    } else {
        Write-Host "Initiating a restart in 10 minutes"
        & shutdown.exe /g /t 600 /f /c "Restarting the computer due to a computer name change. Save your work."
        Exit 0
    }
} else {
    Write-Host "No UPN found. Exiting script."
    Exit 1 # Exit with an error code
}
