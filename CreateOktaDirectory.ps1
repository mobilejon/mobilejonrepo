#Forces the use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AccessURL = Read-Host -Prompt 'Enter your WS1 Access URL'
$Domain = Read-Host -Prompt 'Enter your New Domain'
$DirectoryName = Read-Host -Prompt 'Enter a name for your new Access Directory'

##Start-Sleep -s 30
$ClientId = Read-Host -Prompt 'Enter your OAuth Client ID'
$ClientSecret = Read-Host -Prompt 'Enter your Client Secret'
$text = "${ClientId}:${ClientSecret}"
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
$headers = @{
        "Authorization"="Basic $base64";
        "Accept" = "*/*"
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

     $dirHeaders = @{
        "Accept"="application/vnd.vmware.horizon.manager.connector.management.directory.other+json"
        "Content-Type"="application/vnd.vmware.horizon.manager.connector.management.directory.other+json"
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }
    $restheader = $restheader | ConvertTo-Json
    ##Build the Body##
     $script:body = @{
    "type" = "OTHER_DIRECTORY"
    "domains"  = @($Domain)
     "name" = $DirectoryName
        }
    ##Convert Body to Json##
    $body = $body | ConvertTo-Json
   


Invoke-RestMethod -Uri "https://$AccessURL/SAAS/jersey/manager/api/connectormanagement/directoryconfigs" -Method POST -headers $dirHeaders -Body $Body
