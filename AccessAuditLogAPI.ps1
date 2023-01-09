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
##Perform the Audit Log Query##
$Response = Invoke-RestMethod -Uri "https://$AccessURL/analytics/reports/audit?objectType=RuleSet&fromMillis=$fromMillis&toMillis=$toMillis -headers $Headers
##Build the Array
$list = New-Object System.Collections.ArrayList
for ($i=0; $i -lt $response.data.length; $i++)
##Populate the Array
{$list.Add(($response.data[$i][4] | ConvertFrom-Json))}
$List | Export-CSV "C:\temp\auditlog.csv"
