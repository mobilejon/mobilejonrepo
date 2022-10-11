[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Username = Read-Host -Prompt 'Enter the Username'
    $Password = Read-Host -Prompt 'Enter the Password' -AsSecureString
    $apikey = Read-Host -Prompt 'Enter the API Key'

    #Convert the Password
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    #Base64 Encode AW Username and Password
    $combined = $Username + ":" + $UnsecurePassword
    $encoding = [System.Text.Encoding]::ASCII.GetBytes($combined)
    $cred = [Convert]::ToBase64String($encoding)
    $script:header = @{
    "Authorization"  = "Basic $cred";
    "aw-tenant-code" = $apikey;
    "Content-Type"   = "application/json";}

##Prompt for the API hostname##
$apihost = Read-Host -Prompt 'Enter your API server hostname'

##Prompt for the serial number##
$serialnumber = Read-Host -Prompt 'Enter the serial number for the device you want to migrate'

##Prompt for the Username you want to migrate to##

$username = Read-Host -Prompt 'Enter the username for the device you want to migrate'

##Get the Device ID with the Serial Number##

$deviceresults = Invoke-RestMethod -Headers $header -method Get "https://$apihost/API/mdm/devices?searchby=SerialNumber&id=$serialnumber"
$deviceid = $deviceresults.id.value
##Migrate the Device##
Invoke-RestMethod -Headers $header -method Patch https://$apihost/API/mdm/devices/$deviceid/enrollmentuser/$userid
##Query and Sync Device##

Invoke-Restmethod -Method Post -Uri "https://$apihost/api/mdm/devices/$deviceid/commands?command=SyncDevice" -ContentType "application/json" -Header $header
Invoke-Restmethod -Method Post -Uri "https://$apihost/api/mdm/devices/$deviceid/commands?command=DeviceQuery" -ContentType "application/json" -Header $header
##Sync VPP Assets when Finished##

$groupid = Read-Host -Prompt 'Enter your Group ID to Sync your Apple VPP Assets'
Invoke-RestMethod -Headers $header -method Put https://$apihost/API/mam/apps/purchased/VppSyncAssets/$groupid
