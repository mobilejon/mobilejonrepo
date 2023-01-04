$KeyPath = "HKLM:\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist"
$KeyName = "2"
$KeyType = "String"
$KeyValue = "gehmmocbbkpblljhkekmfhjpfbkclbph"
if(!(Test-Path $KeyPath)) {
    try {
        #Create registry path
        New-Item -Path $KeyPath -ItemType RegistryKey -Force -ErrorAction Stop
		New-Item -Path $KeyPathSettings -ItemType RegistryKey -Force -ErrorAction Stop
    }
    catch {
        Write-Output "FAILED to create the registry path"
    }
}

#Verify if the registry key already exists
if(!((Get-ItemProperty $KeyPath).$KeyName)) {
    try {
        #Create registry key 
        New-ItemProperty -Path $KeyPath -Name $KeyName -PropertyType $KeyType -Value $KeyValue
    }
    catch {
        Write-Output "FAILED to create the registry key"
    }
    }
