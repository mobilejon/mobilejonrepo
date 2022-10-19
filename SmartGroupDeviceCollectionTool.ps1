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
$group = Read-Host -Prompt 'Enter the Smart Group you want to export devices to CSV'
try {

    
  $sresult = Invoke-RestMethod -Method Get -Uri $apihost/api/mdm/smartgroups/search?name=$group -ContentType "application/json" -Header $header

}
catch {
  Write-Host "An error occurred when logging on $_"
  break
}
$menu = @{}
for ($i=1;$i -le $sresult.smartgroups.count; $i++) 
{ Write-Host "$i. Group: $($sresult.smartgroups[$i-1].name), id: $($sresult.smartgroups[$i-1].smartgroupid)"
$menu.Add($i,($sresult.smartgroups[$i-1].smartgroupid))}
[int]$id = Read-Host 'Enter selection'
$sgid = $menu.Item($id)
$sgname = $menu.Item($id)
$userlist = Invoke-RestMethod -Headers $header -Credential $Credentials https://$apihost/API/mdm/smartgroups/$sgid
$devices = $userlist.DeviceAdditions.id
$devicelist = foreach ($device in $devices) {Invoke-RestMethod https://$apihost/API/mdm/devices/$device -Headers $header}
$devicelist | export-csv c:\temp\$sgname.csv 
