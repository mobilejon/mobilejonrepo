$KeyPath = "HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist"
$KeyName = "3"
$KeyType = "String"
$KeyValue = "fdjamakpfbbddfjaooikfcpapjohcfmg;https://clients2.google.com/service/update2/crx"
if(!(Test-Path $KeyPath)) {
    try {
        #Create registry path
        New-Item -Path $KeyPath -ItemType RegistryKey -Force -ErrorAction Stop
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
