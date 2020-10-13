
#----------------------------------------------------------[Declarations]----------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function SyncCorporateDevices { 


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


   ## "Accept"         = "application/json;version=2";
    "Content-Type"   = "application/json";}
  }


$devicetype = 'iPad'
$lgid = ''

  try {
      
$devices = Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/api/mdm/devices/search?lgid=$lgid&Platform=Apple&PageSize=1000" -ContentType "application/json" -Header $header


##$ipads = $devices.devices.id.value


$devicelist = $devices.devices | where-object -filterscript {$_.enrollmentstatus -eq "Enrolled"}


$ipads = $devicelist.id.value


Write-Host "Device Sync is in Progress"



foreach ($ipad in $ipads) { invoke-restmethod -Method Post -Uri "https://asXXX.awmdm.com/api/mdm/devices/$ipad/commands?command=SyncDevice" -ContentType "application/json" -Header $header | Out-Null }


Write-Host "Device Sync is in Done!"


Write-Host "Device Query is in Progress"


foreach ($ipad in $ipads) { invoke-restmethod -Method Post -Uri "https://asXXX.awmdm.com/api/mdm/devices/$ipad/commands?command=DeviceQuery" -ContentType "application/json" -Header $header | Out-Null }
 }
    catch {
  Write-Host "An error occurred when logging on $_"
  break
  }
}


Function SyncStoreiPads { 

if ([string]::IsNullOrEmpty($wsoserver))
  {
    $script:WSOServer = "asXXX.awmdm.com/api"
    
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
   ## "Accept"		 = "application/json;version=2";
    "Content-Type"   = "application/json";}
  }

$devicetype = 'iPad'
$lgid = ''
  try {
      
$devices = Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/API/mdm/devices/search?model=$devicetype&lgid=$lgid&pagesize=5000" -ContentType "application/json" -Header $header

$ipads = $devices.devices.id.value

Write-Host "Device Sync is in Progress"

foreach ($ipad in $ipads) { invoke-restmethod -Method Post -Uri "https://asXXX.awmdm.com/api/mdm/devices/$ipad/commands?command=SyncDevice" -ContentType "application/json" -Header $header | Out-Null }
 

 } 
  
catch {
  Write-Host "An error occurred when logging on $_"
  break
  }
}

Function SyncStoreiPods { 

 

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
   ## "Accept"         = "application/json;version=2";
    "Content-Type"   = "application/json";}
  }

 

$devicetype = 'iPod touch'
$lgid = ''
 

  try {
      
$devices = Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/API/mdm/devices/search?model=$devicetype&lgid=$lgid&pagesize=5000" -ContentType "application/json" -Header $header

 

$ipads = $devices.devices.id.value

 

Write-Host "Device Sync is in Progress"

 

foreach ($ipad in $ipads) { invoke-restmethod -Method Post -Uri "https://asXXX.awmdm.com/api/mdm/devices/$ipad/commands?command=SyncDevice" -ContentType "application/json" -Header $header | Out-Null }
 

 } 
  
catch {
  Write-Host "An error occurred when logging on $_"
  break
  }
}
  
Function AddtoSmartGroup {

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
    "Accept"		 = "application/json;version=2";
    "Content-Type"   = "application/json";}
  }
$group = Read-Host -Prompt 'Enter the Smart Group you want to add devices to'

try {

    
  $sresult = Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/api/mdm/smartgroups/search?name=$group" -ContentType "application/json" -Header $header

}

catch {
  Write-Host "An error occurred when logging on $_"
  break
}
$menu = @{}
for ($i=1;$i -le $sresult.smartgroups.count; $i++) 
{ Write-Host "$i. Group: $($sresult.smartgroups[$i-1].name), id: $($sresult.smartgroups[$i-1].smartgroupuuid)"
$menu.Add($i,($sresult.smartgroups[$i-1].smartgroupuuid))}
[int]$id = Read-Host 'Enter selection'
$sgid = $menu.Item($id)

##Search for a User

  
$user = Read-Host -Prompt 'Enter the User for the device you want to add'


try {

    
$devicelist= Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/api/mdm/devices/search?user=$user" -ContentType "application/json" -Header $header

}

catch {
  Write-Host "An error occurred when logging on $_"
  break
}

$menu = @{}
for ($i=1;$i -le $devicelist.devices.count; $i++) 
{ Write-Host "$i. Device: $($devicelist.devices[$i-1].DeviceFriendlyName), S/N: $($devicelist.devices[$i-1].SerialNumber), UUID: $($devicelist.devices[$i-1].uuid)"
$menu.Add($i,($devicelist.devices[$i-1].uuid))}
[int]$devid = Read-Host 'Enter selection'
$device = $menu.Item($devid)
##$devicelist.devices | format-table -Property @{Name = 'Group Name'; Expression = {$_.name}},@{Name = 'Devices'; Expression = {$_.smartgroupuuid}},@{Name = 'Assignments'; Expression = {$_.smartgroupid}},@{Name = 'Exclusions'; Expression = {$_.exclusions}}

##Add User to Smart Group
write-host $device
$newdevice =  @{
            value= $device;
            path= '/smartGroupsOperationsV2/devices';
            op= 'add'
           }
  
$json = $newdevice | ConvertTo-json 
$temp = "[" + $json + "]"  
invoke-restmethod -Method Patch -Uri "https://asXXX.awmdm.com/api/mdm/smartgroups/$sgid" -Header $header -Body $temp

}
Function AddtoSmartGroupCSV {

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
    "Accept"		 = "application/json;version=2";
    "Content-Type"   = "application/json";}
  }
$group = Read-Host -Prompt 'Enter the Smart Group you want to add devices to'

try {

    
  $sresult = Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/api/mdm/smartgroups/search?name=$group" -ContentType "application/json" -Header $header

}

catch {
  Write-Host "An error occurred when logging on $_"
  break
}
$menu = @{}
$print = @{}
for ($i=1;$i -le $sresult.smartgroups.count; $i++) 
{ <#Write-Host "$i. Group: #>$($sresult.smartgroups[$i-1].name), <#id: #>$($sresult.smartgroups[$i-1].smartgroupuuid)<#"#>
$menu.Add($i,($sresult.smartgroups[$i-1].smartgroupuuid))
$print.Add($sresult.smartgroups[$i-1].name)}
Write-Host $print
[int]$id = Read-Host 'Enter selection'
$sgid = $menu.Item($id)

##Search for a User
Write-Host "`n*Instructions*`n Create a .csv file with a Row called 'Serial' the columns below it need to be filled with device serial tags" 
$userprompt = Read-Host -Prompt 'Enter the Path of the .CSV file'
$temp = Import-Csv -Path $userprompt | where-object {$_.serial}
$userList = @()
$deviceArray = @()
for ($i=0;$i -le ($temp.serial.count -1); $i++){
    $userList += ($temp.serial[$i])}

    write-host $temp
    foreach ($object in $userList){ $callDevice = Invoke-RestMethod -Method Get -Uri "https://asXXX.awmdm.com/api/mdm/devices/serialnumber/$object" -ContentType "application/json" -Header $header
    $counting = $count++

    $deviceArray += ($callDevice.uuid)
$newdevice =  @{
            value= $deviceArray[$counting];
            path= '/smartGroupsOperationsV2/devices';
            op= 'add'
           }
$json = $newdevice | ConvertTo-json 
$temp = "[" + $json + "]" 
invoke-restmethod -Method Patch -Uri "https://asXXX.awmdm.com/api/mdm/smartgroups/$sgid" -Header $header -Body $temp
  }  
}
function Show-Menu
  {
    param (
          [string]$Title = 'VMware Workspace ONE UEM API Menu'
          )
       Clear-Host
       Write-Host "$Title
        Press '1' to sync Corporate Devices
        Press '2' to sync store iPads
        Press '3' to sync store iPods
        Press '4' Adding single user device to Smart Group
        Press '5' Add .CSV file of user devices to Smart Group
        Press 'Q' to quit."
         }

do

 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
    
    '1' {  

         SyncCorporateDevices
    } 

    '2' {

        SyncStoreiPads

    }
    
    '3' {
   
         SyncStoreiPods

    }

    '4' {

        AddtoSmartGroup
    }
    '5' {

        AddtoSmartGroupCSV
    }
    
    }
    pause
 }
 until ($selection -eq 'q')
