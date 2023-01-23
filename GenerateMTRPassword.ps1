New-Item C:\temp\GenerateMTRPassword.ps1 -ItemType File -Force
Set-Content C:\temp\GenerateMTRPassword.ps1 '##Generate New Random Password and Save to Text File##
Add-Type -AssemblyName System.Web
$NewPassword = [System.Web.Security.Membership]::GeneratePassword(16,3)
New-Item -Path C:\temp\newpassword.txt -Value $NewPassword -Force
##Stage the Config File##
New-Item -Path C:\temp -Name staging -ItemType directory -Force
Copy-Item -Path C:\temp\SkypeSettings.xml -Destination C:\temp\staging\SkypeSettings.xml
##Username##
$SkypeUsername = Get-Content C:\Users\Skype\AppData\Local\Packages\Microsoft.SkypeRoomSystem_8wekyb3d8bbwe\LocalCache\Roaming\Microsoft\Teams\desktop-config.json
$JSONObject = ConvertFrom-Json -InputObject $SkypeUsername
$UPN = $JSONObject.upnWindowUserUpn
##Capture the Password and Username##
$SkypeSettings = Get-Content C:\temp\staging\SkypeSettings.xml
$SkypeSettings = $SkypeSettings -replace "<ExchangeAddress></ExchangeAddress>", ("<ExchangeAddress>" + $UPN + "</ExchangeAddress>") -replace "<SkypeSignInAddress></SkypeSignInAddress>", ("<SkypeSignInAddress>" + $UPN + "</SkypeSignInAddress>") -replace "<Password></Password>", ("<Password>" + $NewPassword + "</Password>") 
$SkypeSettings | Out-File C:\temp\staging\SkypeSettings.xml -Force
Move-Item -Path C:\temp\staging\SkypeSettings.xml -Destination C:\Users\Skype\AppData\Local\Packages\Microsoft.SkypeRoomSystem_8wekyb3d8bbwe\LocalState\SkypeSettings.xml -Force
$identity="Everyone"
$fileSystemRights = "FullControl"
$type = "Allow"
$fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
$fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
$NewAcl = Get-Acl -Path "C:\Users\Skype\AppData\Local\Packages\Microsoft.SkypeRoomSystem_8wekyb3d8bbwe\LocalState\SkypeSettings.xml"
$NewAcl.SetAccessRule($fileSystemAccessRule)
Set-Acl -Path "C:\Users\Skype\AppData\Local\Packages\Microsoft.SkypeRoomSystem_8wekyb3d8bbwe\LocalState\SkypeSettings.xml" -AclObject $NewAcl'
