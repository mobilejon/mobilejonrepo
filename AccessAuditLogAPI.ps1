#Forces the use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AccessURL = ''
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

     $RemoveMLheaders = @{
        "Accept"="application/json"
        "x-tenant-id"=""
        "Content-Type"="application/json"
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }
$Data = Invoke-RestMethod -Uri "https://$AccessURL/analytics/reports/audit?objectType=RuleSet" -Method GET -headers $RemoveMLheaders | ConvertFrom-Json
$Data.data
