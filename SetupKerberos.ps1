# Set Root Domain
If (!$rootDomain) {
    $rootDomain = Get-ADDomain | Select -ExpandProperty DNSRoot
    $rootDomain = $rootDomain.ToUpper()
}
##Request the Service Account Name##
$sAMAccountName = Read-Host -Prompt 'Enter the Service Account Username'

##Set the SPN##
$machineDomain = (Get-WmiObject win32_computersystem).Domain
$machineName = (Get-WmiObject win32_computersystem).DNSHostName
$spn = "HTTP/"+$machineName+"."+$machineDomain
$shortSpn = "HTTP/"+$machineName
setspn -s $spn@$rootDomain $sAMAccountName
Set-ADUser -Identity $sAMAccountName -PasswordNotRequired $true

##Generate the Keytab
$password = Read-Host -Prompt 'Enter the Service Account Password'
$keytabFile = 'C:\temp\new\krb5.keytab'
ktpass.exe -mapuser $sAMAccountName@$rootDomain -princ $spn@$rootDomain  -crypto All -ptype KRB5_NT_PRINCIPAL -pass $password -out $keytabFile
ktpass.exe -princ $spn@$rootDomain -crypto AES128-SHA1 -ptype KRB5_NT_PRINCIPAL -pass "$password" -in "$keytabFile" -out "$keytabFile" -setupn -setpass | Out-Null
"exit code (ktpass-2): $LastExitCode" 
ktpass.exe -princ $spn@$rootDomain -crypto AES256-SHA1 -ptype KRB5_NT_PRINCIPAL -pass "$password" -in "$keytabFile" -out "$keytabFile" -setupn -setpass | Out-Null
"Mapped principal $spn@$rootDomain into $sAMAccountName@$rootDomain, exit code (ktpass-3): $LastExitCode"
ktpass.exe -princ $shortSpn@$rootDomain -mapuser $sAMAccountName@$rootDomain -crypto RC4-HMAC-NT -ptype KRB5_NT_PRINCIPAL -pass "$password" -in "$keytabFile" -out "$keytabFile" -setupn -setpass | Out-Null
"Mapped short $shortSpn@$rootDomain into $sAMAccountName@$rootDomain, exit code (ktpass-4): $LastExitCode"
ktpass.exe -princ $shortSpn@$rootDomain -crypto AES128-SHA1 -ptype KRB5_NT_PRINCIPAL -pass "$password" -in "$keytabFile" -out "$keytabFile" -setupn -setpass | Out-Null
"Mapped short $shortSpn@$rootDomain into $sAMAccountName@$rootDomain, exit code (ktpass-5): $LastExitCode" 
ktpass.exe -princ $shortSpn@$rootDomain -crypto AES256-SHA1 -ptype KRB5_NT_PRINCIPAL -pass "$password" -in "$keytabFile" -out "$keytabFile" -setupn -setpass | Out-Null
"Mapped principal $shortSpn@$rootDomain into $sAMAccountName@$rootDomain, exit code (ktpass-6): $LastExitCode" 
