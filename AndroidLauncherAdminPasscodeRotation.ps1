#----------------------------------------------------------[Declarations]----------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#-----------------------------------------------------------[Functions]------------------------------------------------------------
if ([string]::IsNullOrEmpty($wsoserver))
  {
    $script:WSOServer = "asXXX.awmdm.com/API"
    
  }
 if ([string]::IsNullOrEmpty($header))
  {
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
    "Accept"         = "application/json;version=2";
    "Content-Type"   = "application/json";}
  }

##Find and Select the Launcher Profile##

$profile = Read-Host -Prompt 'Enter the Launcher Profile you want to rotate the password for'

try {

    
  $sresult = Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/api/mdm/profiles/search?platform=android&searchtext=$profile" -ContentType "application/json" -Header $header

}

catch {
  Write-Host "An error occurred when logging on $_"
  break
}
$menu = @{}
for ($i=1;$i -le $sresult.ProfileList.count; $i++) 
{ Write-Host "$i. Profiles: $($sresult.ProfileList[$i-1].ProfileName), id: $($sresult.ProfileList[$i-1].ProfileId)"
$menu.Add($i,($sresult.ProfileList[$i-1].ProfileId))}
[int]$id = Read-Host 'Enter selection'
$ProfileId = $menu.Item($id)
##Get the Details of the Existing Profile##
$body = Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/api/mdm/profiles/$ProfileId" -ContentType "application/json" -Header $header | ConvertTo-Json
$fixBody = $body -replace "@", ""
# Convert JSON string to PowerShell object
$newBody = $fixBody | ConvertFrom-Json

# Check if General is an array and has at least one element
if ($newBody.General -is [System.Array] -and $newBody.General.Count -gt 0) {
    # Reconstruct the first object in the General array and add the new property
    $firstItem = $newBody.General[0] | Select-Object *,@{Name='CreateNewVersion';Expression={'True'}}
    
    # Replace the original first element with the modified one
    $newBody.General[0] = $firstItem
} elseif ($newBody.General -ne $null) {
    # If General is not an array but a single object
    # Reconstruct the General object and add the new property
    $newBody.General = $newBody.General | Select-Object *,@{Name='CreateNewVersion';Expression={'True'}}
} else {
    # If General is null or doesn't exist, initialize it as an array with the new object
    $newBody.General = @(@{CreateNewVersion = "True"})
}

# Convert back to JSON string

# Processing each AllowedApplication entry
$newBody.AndroidForWorkKiosk.AllowedApplications = $newBody.AndroidForWorkKiosk.AllowedApplications | ForEach-Object {
    $entry = $_.Trim("{} ")
    $pairs = $entry -split ';'
    $appObj = @{}
    foreach ($pair in $pairs) {
        $parts = $pair.Split("=", 2)
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            $appObj[$key] = $value
        }
    }
    return $appObj
}

$newBody.AndroidForWorkKiosk.GroupId = "{" + $newBody.AndroidForWorkKiosk.GroupId.Trim("{}") + "}"
$newBody.AndroidForWorkKiosk.UserName = "{" + $newBody.AndroidForWorkKiosk.UserName.Trim("{}") + "}"


# Convert the entire object back to a JSON string

$newVersionBody = $newBody | ConvertTo-Json -Depth 10



function Generate-RandomPassword {
    param (
        [int]$length = 16
    )

    $characters = 'abcdefghiklmnoprstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ1234567890!@$?_-'
    $bytes = new-object "System.Byte[]" $length
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    $password = ($bytes | ForEach-Object { $characters[$_ % $characters.Length] }) -join ''
    return $password
}

$newPassword = Generate-RandomPassword -length 16
$updatedbody = $newVersionBody -replace "\*\*\*\*\*", $NewPassword
$newPasswordBody = $updatedbody
# Define a regex pattern to match the specific structure
# This pattern looks for the "{SmartGroupId=number; Name=text}" structure
$pattern = '"\{SmartGroupId=(\d+);\s*Name=([^}]+)\}"'

# Replacement string reformats the matched strings into a valid JSON object
$replacement = '{"SmartGroupId": "$1", "Name": "$2"}'
$finalBody = $newPasswordBody -replace $pattern, $replacement


Invoke-RestMethod -Method Post -Uri "https://asXXX.awmdm.com/api/mdm/profiles/platforms/android/update" -ContentType "application/json" -body $finalBody -Header $header

##$mailParams = @{
    ##SmtpServer               = 'smtp.office365.com'
    ##Port                     = '587' 
    ##UseSSL                   = $true
    ##Credential               = New-Object System.Management.Automation.PSCredential ("", "")
    ##From                     = ''
    ##To                       = ''
    ##Subject                  = "Android Launcher Admin Passcode Updated"
    ##Body                     = "The Passcode has been updated. The new Passcode is $NewPassword"
    ##BodyAsHtml               = $true
  ##  Priority                 = 'High'
##    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
##}

##Send-MailMessage @mailParams
