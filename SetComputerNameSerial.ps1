$serial = (Get-WmiObject Win32_Bios).SerialNumber
Rename-Computer -NewName $serial -Force
