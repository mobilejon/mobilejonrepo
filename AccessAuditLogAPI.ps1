#Forces the use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$date1 = Get-Date -Date "01/01/1970"
$date2 = (Get-Date).adddays(-7)  
$date3 = (Get-Date) 
$timespan =  (New-TimeSpan -Start $date1 -End $date2).TotalMilliSeconds
$timespan2 = (New-TimeSpan -Start $date1 -End $date3).TotalMilliSeconds
$fromMillis = [math]::Floor($timespan)
$toMillis = [math]::Floor($timespan2)
$AccessURL = ''

##Start-Sleep -s 30
$ClientId = ''
$ClientSecret = ''
$text = "${ClientId}:${ClientSecret}"
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
$headers = @{
        "Authorization"="Basic $base64";
        "Content-Type"="application/x-www-form-urlencoded";
    }

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

     $Headers = @{
        "Accept"="application/vnd.vmware.horizon.manager.reports.table+json"
        "x-tenant-id"=""
        "Content-Type"="application/vnd.vmware.horizon.manager.reports.table+json"
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }
    $global:workspaceOneAccessConnection

    $Headers = @{
       "x-tenant-id"=""
       "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
   }
$Response = Invoke-RestMethod -Uri "https://$AccessURL/analytics/reports/audit?objectType=RuleSet&fromMillis=$fromMillis&toMillis=$toMillis" -Method GET -headers $Headers
$encdata = $Response.data[0][4] | ConvertFrom-Json
$encdata | Export-CSV "C:\temp\AccessAuditLogs-$date.csv"
