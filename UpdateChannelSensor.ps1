# Returns the Office Channel
# Execution Context: System
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
$subKey = $key.OpenSubKey("SOFTWARE\Microsoft\Office\ClickToRun\Configuration")
$regkey_value = $subKey.GetValue("UpdateChannel")
$channel = $regkey_value.Replace('http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60','Current Channel').Replace('http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6','Monthly Enterprise Channel').Replace('http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114','Semi-Annual Enterprise Channel')
return $channel
