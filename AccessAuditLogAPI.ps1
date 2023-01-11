 #Forces the use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
##Declares Variables for the Date Filter for Audit Logs##
$date1 = Get-Date -Date "01/01/1970"
$date2 = (Get-Date).adddays(-7)  
$date3 = (Get-Date) 
$timespan =  (New-TimeSpan -Start $date1 -End $date2).TotalMilliSeconds
$timespan2 = (New-TimeSpan -Start $date1 -End $date3).TotalMilliSeconds
##Declares the Variables for the Filter itself
$fromMillis = [math]::Floor($timespan)
$toMillis = [math]::Floor($timespan2)

##Specify your Access Hostname
$AccessURL = ''
##Specify your oAuth Client ID and Secret
$ClientId = ''
$ClientSecret = ''
$text = "${ClientId}:${ClientSecret}"
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
$headers = @{
        "Authorization"="Basic $base64";
        "Content-Type"="application/x-www-form-urlencoded";
    }
##Auth and Get your Bearer Token##
$results = Invoke-WebRequest -Uri "https://$AccessURL/SAAS/auth/oauthtoken?grant_type=client_credentials" -Method POST -Headers $headers
$accessToken = ($results.Content | ConvertFrom-Json).access_token
  $authHeader = @{
        "Authorization"="Bearer $accessToken";
    }
      $global:workspaceOneAccessConnection = new-object PSObject -Property @{
        'Server' = "https://$AccessURL"
        'headers' = $authHeader
    } 
$global:workspaceOneAccessConnection
 ##Declare the Header for your Audit Log Query##    

$Headers = @{
        "x-tenant-id"=""      
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }
    $global:workspaceOneAccessConnection

    $Headers = @{
       "x-tenant-id"=""
       "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
   }
##Perform Audit Search
$Response = Invoke-RestMethod -Uri "https://$AccessURL/analytics/reports/audit?objectType=RuleSet&fromMillis=$fromMillis&toMillis=$toMillis" -Method GET -headers $Headers
$list = New-Object System.Collections.ArrayList
for ($i=0; $i -lt $response.data.length; $i++)
{$list.Add(($response.data[$i][4] | ConvertFrom-Json))}
##Capture AuthMethods into Array and Re-write Audit Log##
$authmethods = Invoke-RestMethod -Uri "https://$AccessURL/SAAS/jersey/manager/api/authmethods" -Method GET -Headers $headers
$authmethods = $authmethods.items | Select-Object authMethodName, uuid
$authnmethods=Get-Content -Path C:\temp\internalauthmethodlist.json | ConvertFrom-Json
for ($i=0; $i -lt $response.data.length; $i++)
{ $list.Add(($response.data[$i][4] | ConvertFrom-Json))| out-null

}
foreach ($item in $list){
foreach ($authmethod in $authnmethods.Methods) {
$item.values = $item.values -replace $authmethod.ID, $authmethod.Name
if ($item.psobject.Properties.name -contains "oldValues") {
$item.oldValues = $item.oldValues -replace $authmethod.ID, $authmethod.Name}
}
}
foreach ($item in $list){
    foreach ($authmethod in $authmethods) { 
        $item.values = $item.values -replace $authmethod.uuid, $authmethod.authMethodName 
        if ($item.PSObject.Properties.name -contains "oldValues") {
            $item.oldValues = $item.oldValues -replace $authmethod.uuid, $authmethod.authMethodName
        }
}
}
$List | Export-CSV "C:\temp\auditlog.csv"
