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
setspn -s $spn@$rootDomain $sAMAccountName

##Generate the Keytab
$password = Read-Host -Prompt 'Enter the Service Account Password'
$keytabFile = 'C:\temp\krb5.keytab'
ktpass.exe -mapuser $sAMAccountName@$rootDomain -princ $spn@$rootDomain  -crypto RC4-HMAC-NT -ptype KRB5_NT_PRINCIPAL -pass $password -out $keytabFile
