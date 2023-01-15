#Forces the use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
##Capture the Variables for the Scope of the API Call##
$date1 = Get-Date -Date "01/01/1970"
$date2 = (Get-Date).adddays(-7)
$date3 = (Get-Date).AddHours(5)
$timespan =  (New-TimeSpan -Start $date1 -End $date2).TotalMilliSeconds
$timespan2 = (New-TimeSpan -Start $date1 -End $date3).TotalMilliSeconds
$fromMillis = [math]::Floor($timespan)
$toMillis = [math]::Floor($timespan2)
##Auth Variables##
$AccessURL = ''
$ClientId = ''
$ClientSecret = ''
$text = "${ClientId}:${ClientSecret}"
##Authenticate to WS1 Access##
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
##Get Login Risk Data and Send to CSV##
$Response = Invoke-RestMethod -Uri https://$AccessURL/analytics/reports/audit?objectType=LOGIN&fromMillis=$fromMillis&toMillis=$toMillis -Method GET -headers $Headers
$list = New-Object System.Collections.ArrayList @()
for ($i=0; $i -lt $response.data.length; $i++)
{$list.Add(($response.data[$i][4] | ConvertFrom-Json)) |Out-Null}
$RiskLevel = $list | Where-Object -FilterScript {$_.values -like '*LoginRiskLevel*'}
$RiskLevel | Select-Object actorUserName, actorDomain, sourceIp, deviceId, @{Name="LoginRiskLevel";Expression= {$_.values.LoginRiskLevel}} | Export-CSV C:\temp\RiskAuditLog-$((Get-Date).ToString('dd-MM-yyyy')).csv
