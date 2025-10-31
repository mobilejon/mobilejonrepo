# =======================
# Pre-Execution Setup
# =======================
$RemediationName = "SetTimeZone"
$LogFolder = "C:\Logs\Intune\Remediations"
$LogFile = Join-Path -Path $LogFolder -ChildPath "$RemediationName.log"

if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

Start-Transcript -Path $LogFile -Append

try {
    # =======================
    # Step 1: Enable App Access to Location
    # =======================
    $appPrivacyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
    New-Item -Path $appPrivacyPath -Force | Out-Null
    Set-ItemProperty -Path $appPrivacyPath -Name "LetAppsAccessLocation" -Value 1 -Type DWord -Force
    Write-Output "Set LetAppsAccessLocation to 1 in $appPrivacyPath"

    # =======================
    # Step 2: Set ConsentStore\location to Allow
    # =======================
    $consentStorePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    New-Item -Path $consentStorePath -Force | Out-Null
    Set-ItemProperty -Path $consentStorePath -Name "Value" -Type String -Value "Allow"
    Write-Output "Set Value to 'Allow' in $consentStorePath"

    # =======================
    # Step 3: Sensor Permission Override
    # =======================
    $sensorOverridePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
    if (-not (Test-Path $sensorOverridePath)) {
        New-Item -Path $sensorOverridePath -Force | Out-Null
        Write-Output "Created registry key: $sensorOverridePath"
    } else {
        Write-Output "Registry key already exists: $sensorOverridePath"
    }
    Set-ItemProperty -Path $sensorOverridePath -Name "SensorPermissionState" -Type DWord -Value 1 -Force
    Write-Output "Set SensorPermissionState to 1 in $sensorOverridePath"

    # =======================
    # Step 4: Enable and Start Location Service
    # =======================
    $LocationServiceConfigurationKey = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
    New-Item -Path $LocationServiceConfigurationKey -Force | Out-Null
    Set-ItemProperty -Path $LocationServiceConfigurationKey -Name "Status" -Value 1 -Type DWord -Force
    Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
    Write-Output "Enabled and started Location Service"

    # =======================
    # Step 5: Ensure tzautoupdate is Automatic and Running
    # =======================
    $serviceName = "tzautoupdate"
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        Write-Output "Service '$serviceName' does not exist."
    } else {
        if ($service.StartType -ne 'Automatic') {
            Write-Output "Service '$serviceName' is not set to Automatic. Updating..."
            Set-Service -Name $serviceName -StartupType Automatic
        } else {
            Write-Output "Service '$serviceName' is already set to Automatic."
        }

        if ($service.Status -ne 'Running') {
            Write-Output "Service '$serviceName' is not running. Starting it now..."
            Start-Service -Name $serviceName
        } else {
            Write-Output "Service '$serviceName' is already running."
        }
    }

} catch {
    Write-Error "An error occurred during remediation: $_"
} finally {
    Stop-Transcript
}
