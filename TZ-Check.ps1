$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
$valueName = "Value"
$expectedValue = "Allow"

try {
    $actualValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName

    if ($actualValue -eq $expectedValue) {
        exit 0  # Compliant
    } else {
        exit 1  # Not compliant
    }
} catch {
    exit 1  # Key or value doesn't exist, so not compliant
}
