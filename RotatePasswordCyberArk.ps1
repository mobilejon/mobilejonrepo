##Get Username##
$username = Get-Content C:\temp\username.txt
$CyberArkUsername = “CyberArkMTRPolicyName” + $Username
##Retrieve Local Account Password##
$localpasswordretrieval = Invoke-RestMethod -Method Get -Uri https://cyberarkURL/AIMWebService/Api/Accounts?AppID=VAULTNAME&”Object=“PolicyName-ServiceAccountName”
$localpassword = $localpasswordretrieval.content
$EscapedPassword = [System.Security.SecurityElement]::Escape($localpassword)

##Authenticate##
$AuthBody = @{username=‘SERVICEACCOUNTNAME’;password=$EscapedPassword} | ConvertTo-Json
$CyberArkAuthToken = Invoke-RestMethod -Method Post -Uri https://cyberarkURL/api/auth/Ldap/logon -Body $AuthBody -ContentType "application/json"

##Get the New Password##
$NewPassword = Get-Content C:\temp\newpassword.txt

##Get Account ID##
$header = @{"Authorization" = $CyberArkAuthToken}
$body = @{"NewCredentials" = $NewPassword}
$AccountID = Invoke-RestMethod -Uri https://cyberarkURL/passwordvault/api/Accounts?$CyberArkUsername -Headers $header
$UserID = $AccountID.value.id
##Change Password##
Invoke-RestMethod -Method Post -Uri https://cyberarkURL/passwordvault/api/Accounts/$UserID/Password/Update -Headers $header -Body $body

##Delete Password File##
##Remove-Item -Path C:\temp\newpassword.txt -Force
##Restart-Computer
