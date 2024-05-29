# Set Root Domain
If (!$rootDomain) {
    $rootDomain = Get-ADDomain | Select -ExpandProperty DNSRoot
    $rootDomain = $rootDomain.ToUpper()
}

$confDir ="C:\Program Files\Workspace ONE Access\Kerberos Auth Service\conf"
$setupLogFile = $confDir+'\krb5-setup.log'
$outputExitCodeFile = $confDir+'\..\..\Support\scripts\executionExitCodeFile.txt'

##Request the Service Account Name##
$sAMAccountName = Read-Host -Prompt 'Enter the Service Account Username'

##Set the SPN##
$machineDomain = (Get-WmiObject win32_computersystem).Domain
$machineName = (Get-WmiObject win32_computersystem).DNSHostName
$spn = "HTTP/"+$machineName+"."+$machineDomain
$shortSpn = "HTTP/"+$machineName
setspn -s $spn@$rootDomain $sAMAccountName
Set-ADUser -Identity $sAMAccountName -PasswordNotRequired $true

##Enable AES Encryption
$keyboth = 24
Get-ADUser -Identity $sAMAccountName | Set-ADUser -Replace @{"msDS-SupportedEncryptionTypes" = $keyboth}

##Generate the Keytab
$ktPassSuccessful = $false
$attemptNumber = 1
$maxRetries = 30
$sleepDurationInSeconds = 5
$keytabFile = $confDir+'\krb5.keytab'

# Fully qualify ktpass command, System32 may not be in the path
$ktpass = "$Env:SystemRoot\System32\ktpass.exe"

Do
{
    # Sleep for few seconds before attempting each attempt.
    Start-Sleep -s $sleepDurationInSeconds

    "Attempting to associate password for the spn and user-account: attempt number: $attemptNumber" | Out-File "$setupLogFile" -Append
    & "$ktpass" -princ $spn@$rootDomain -mapuser $sAMAccountName@$rootDomain -crypto AES128-SHA1 -ptype KRB5_NT_PRINCIPAL -pass "$password" -out "$keytabFile" | Out-File "$setupLogFile" -Append
    "ktpass exit code (ktpass-1): $LastExitCode for the attemptNumber: $attemptNumber" | Out-File "$setupLogFile" -Append

    $attemptNumber++

    $retryKtPass = $false
    if (($LastExitCode -ne 0) -AND ($attemptNumber -lt $maxRetries)) {
        $previousAttemptNumber = $attemptNumber - 1
        "ktpass was not successful in the attempt number: $previousAttemptNumber, retrying with another attempt." | Out-File "$setupLogFile" -Append
        $retryKtPass = $true
    }

} While ($retryKtPass)

Set-ADUser -Identity $sAMAccountName -UserPrincipalName $sAMAccountName'@'$rootDomain

"Before updating -PasswordNotRequired $true" | Out-File "$setupLogFile" -Append
Get-ADUser -Identity $sAMAccountName -Properties PasswordNotRequired | Out-File "$setupLogFile" -Append
Set-ADUser -Identity $sAMAccountName -PasswordNotRequired $false

"After updating -PasswordNotRequired $true" | Out-File "$setupLogFile" -Append
Get-ADUser -Identity $sAMAccountName -Properties PasswordNotRequired | Out-File "$setupLogFile" -Append

$previousAttemptNumber = $attemptNumber - 1
"Exited with total attempts: $previousAttemptNumber" | Out-File "$setupLogFile" -Append

if ($LastExitCode -eq 0) {
    & "$ktpass" -princ $spn@$rootDomain -crypto AES256-SHA1 -ptype KRB5_NT_PRINCIPAL -pass "$password" -in "$keytabFile" -out "$keytabFile" -setupn -setpass | Out-Null
    "Mapped principal $spn@$rootDomain into $sAMAccountName@$rootDomain, exit code (ktpass-2): $LastExitCode" | Out-File "$setupLogFile" -Append

    if ($LastExitCode -eq 0) {
        & "$ktpass" -princ $shortSpn@$rootDomain -mapuser $sAMAccountName@$rootDomain -crypto AES128-SHA1 -ptype KRB5_NT_PRINCIPAL -pass "$password" -in "$keytabFile" -out "$keytabFile" -setupn -setpass | Out-Null
        "Mapped short spn principal $shortSpn@$rootDomain into $sAMAccountName@$rootDomain, exit code (ktpass-3): $LastExitCode" | Out-File "$setupLogFile" -Append

    	if ($LastExitCode -eq 0) {
    		& "$ktpass" -princ $shortSpn@$rootDomain -crypto AES256-SHA1 -ptype KRB5_NT_PRINCIPAL -pass "$password" -in "$keytabFile" -out "$keytabFile" -setupn -setpass | Out-Null
    		"Mapped principal $shortSpn@$rootDomain into $sAMAccountName@$rootDomain, exit code (ktpass-4): $LastExitCode" | Out-File "$setupLogFile" -Append

    		if ($LastExitCode -eq 0) {
    			$ktPassSuccessful = $true
    		}
    	}
    }
} else {
    "ERROR: Failed to map user and generate keytab file." | Out-File "$setupLogFile" -Append
}

$env:exitCode = $LastExitCode

"$env:exitCode" | Out-File "$outputExitCodeFile" -Append

#Write-Host "($LastExitCode) Press any key to continue ..."
#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

"RESULT: exit code $LastExitCode" | Out-File "$setupLogFile" -Append

if ($ktPassSuccessful) {
    Write-Host "Success"
} Else {
    Write-Host "Kerberos setup failed with code $LastExitCode"
}
