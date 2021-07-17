# Imports Access API Module from William Lam
#Forces the use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$HTML = Get-Content $PSScriptRoot\template.html -Raw
$FirstName = Read-Host -Prompt 'Enter the New Hire First Name'
$LastName = Read-Host -Prompt 'Enter the New Hire Last Name'
$Username = $FirstName.Substring(0,1) + $LastName
$AccessURL = ''
$Domain = ''
$HTML = $HTML -replace "{First_Name}", $FirstName
$HTML = $HTML -replace "{Username}", $username
$HTML = $HTML -replace "{Access_URL}", $AccessURL

##Start-Sleep -s 30
$ClientId                 = 'PostmanClient'
$ClientSecret             = ''
$text = "${ClientId}:${ClientSecret}"
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
    $headers = @{
        "Authorization"="Basic $base64";
        "Content-Type"="application/x-www-form-urlencoded";
    }
  $authHeader = @{
        "Authorization"="Bearer $accessToken";
    }
      $global:workspaceOneAccessConnection = new-object PSObject -Property @{
        'Server' = "https://$AccessURL"
        'headers' = $authHeader
    } $global:workspaceOneAccessConnection
$results = Invoke-WebRequest -Uri "https://$AccessURL/SAAS/auth/oauthtoken?grant_type=client_credentials" -Method POST -Headers $headers
$accessToken = ($results.Content | ConvertFrom-Json).access_token
## Sync-Directory -DomainID $DomainID


##Remove Existing Magic Links##

     $RemoveMLheaders = @{
        "Accept"="application/json"
        "Content-Type"="application/json"
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }
$userid = Invoke-RestMethod -Uri "https://$AccessURL/SAAS/jersey/manager/api/scim/Users?filter=username%20eq%20%22$username%22" -Method GET -headers $RemoveMLheaders
$userid = $userid.Resources.id

Invoke-RestMethod -uri "https://$AccessURL/SAAS/jersey/manager/api/token/auth/state/$userid" -Method Delete -headers $RemoveMLheaders

##Create Magic Link##

     $MLheaders = @{
        "Accept"="application/vnd.vmware.horizon.manager.tokenauth.link.response+json";
        "Content-Type"="application/vnd.vmware.horizon.manager.tokenauth.generation.request+json"
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }
 $MLjson = @{
        domain = $Domain
        userName = $userName
    }

    $MLbody = $MLjson | ConvertTo-Json

$OTURL = Invoke-RestMethod -Uri "https://$AccessURL/SAAS/jersey/manager/api/token/auth/state" -Method POST -Headers $MLheaders -Body $MLbody
$OTURL.loginLink = $OTURL
$HTML = $HTML -replace "https://replace.this.com", $OTURL

$mailParams = @{
    SmtpServer               = 'smtp.office365.com'
    Port                     = '587' 
    UseSSL                   = $true
    Credential               = (Get-Credential)
    From                     = ''
    To                       = ''
    Subject                  = "Welcome to the Resistance"
    Body                     = $HTML
    BodyAsHtml               = $true
    Priority                 = 'High'
    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
}

Send-MailMessage @mailParams
