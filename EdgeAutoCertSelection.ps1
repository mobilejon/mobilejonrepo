$KeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\AutoSelectCertificateForUrls"
$KeyName = "1"
$KeyType = "String"
$KeyValue = '{"pattern":"https://cas-aws.workspaceoneaccess.com/","filter":{}}'
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

New-ItemProperty -Path $KeyPath -Name $KeyName -PropertyType $KeyType -Value $KeyValue -Force

