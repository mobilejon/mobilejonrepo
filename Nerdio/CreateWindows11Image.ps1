#description: (PREVIEW) Create a working AVD environment with desktop image and autoscale host pool
#tags: Nerdio, Preview

<#

This script creates a working AVD environment, including:
 - AVD Workspace
 - Desktop Image
 - Dynamic Host Pool with Autoscale enabled
 - Assigns users to host pool

NOTE: the created Workspace will not be visible in NMW until you set 
"Hide Unassigned Workspaces" to OFF in the settings of Workspaces page

This script requires the NME API to be enabled, under settings -> Nerdio Integrations

Before running this script, set the Required Variables to your own values. 

You may also wish to look over the Additional Variables section and make any necessary changes 
from the defaults specified here.

#>


##### Required Variables #####

$client_secret = $SecureVars.ClientSecret # Set this variable in NMW under Settings -> Nerdio Integrations
$app_url = '' # no trailing slash
$client_id = ''
$scope = 'api://XX/.default'
$tenant_id =''

$SubscriptionId = ''
$ResourceGroupName = ""

$VnetName = ''
$NetworkResourceGroupName = ""
$SubnetName = '' # subnet where AVD hosts will be provisioned
$RegionName = "eastus2" # e.g. "eastus2"


##### Additional Variables #####

$WindowsVersion = 'microsoftwindowsdesktop/office-365/win11-24h2-avd-m365/latest' # Version of windows to use in desktop image and host pool
$ImageVmSize = 'Standard_D2s_v5'

$WorkspaceName = "AVD-Win11"
$WorkspaceFriendlyName = "Windows 11 Remote Desktop"
$WorkspaceDescription = "Access to your personal Windows 11 remote desktop"
$AdConfigId = ""

$DesktopImageName = "AVD-GEN-W11-IMG"
$ImageStorageType = 'StandardSSD_LRS'

$TimeZone = "Eastern Standard Time"

$HostPoolName = "AVD-GEN-W11"
$HostPoolDescription = "All Std Apps on Windows 11 24H2"
$ScriptedActionIDs = @()  # List of Scripted Actions (by id) to be run on the image. Can be used to install software. E.g.: $ScriptedActionIDs = @(35, 36)

$UserUPNs = @('')
# Users to assign to the new host pool. E.g.: $UserUPNs =  @('first_user@domain.com', 'second_user@domain.com', 'third_user@domain.com')

$HostVmPrefix = "AVD-GEN11"
$HostVmSize = "Standard_D16s_v4"
$HostVmStorageType = 'Premium_LRS'
$HostVmDiskSize = 128
$hasEphemeralOSDisk = $false
$BaseHostPoolCapacity = 1
$MinActiveHostsCount = 1
$BurstCapacity = 2

#####

##### Script Logic #####

$errorActionPreference = "Stop" 

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

$encoded_scope = [System.Web.HTTPUtility]::UrlEncode("$Scope")

$body = "grant_type=client_credentials&client_id=$client_id&scope=$encoded_scope&client_secret=$client_secret"

$TokenResponse = Invoke-RestMethod "https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token" -Method POST -Headers $headers -Body $body

$token = $TokenResponse.access_token

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")
$headers.Add("Accept", "application/json")
$headers.Add("Content-Type", "application/json")


if (!$AdConfigId){
    $AdConfigs = Invoke-RestMethod -Uri "$app_url/api/v1/ad/config" -Method Get -UseBasicParsing -Headers $headers
    $AdConfigId = ($AdConfigs | Where-Object isDefault -eq $true).id
} 

$NewDesktopImageBody = @"
{
 "jobPayload": {
		"imageId": {
            "subscriptionId": "$SubscriptionId",
            "resourceGroup": "$ResourceGroupName",
            "name": "$DesktopImageName"
        },
        "sourceImageId": "$WindowsVersion",
        "vmSize": "$ImageVmSize",
        "storageType": "$ImageStorageType",
        "diskSize": 128,
        "networkId": "/subscriptions/$SubscriptionId/ResourceGroups/$NetworkResourceGroupName/providers/Microsoft.Network/virtualNetworks/$VnetName",
        "subnet": "$SubnetName",
        "description": "image description",
        "noImageObjectRequired": false,
        "enableTimezoneRedirection": true,
        "vmTimezone": "Eastern Standard Time",
        "scriptedActionsIds": $(if ($ScriptedActionIDs){$ScriptedActionIDs | ConvertTo-Json} else{'null'})
    },
    "failurePolicy": {
        "restart": true,
        "cleanup": true
    }
}
"@

$NewDesktopImage = Invoke-RestMethod "$app_url/api/v1/desktop-image/create-from-library" -Method 'POST' -Headers $headers -Body $NewDesktopImageBody 

# Get status of job
$NewDesktopImageStatus = Invoke-RestMethod "$app_url/api/v1/job/$($NewDesktopImage.job.id)" -Method Get -Headers $headers 

while ($NewDesktopImageStatus.jobStatus -eq 'Pending' -or $NewDesktopImageStatus.jobStatus -eq 'Running')
{
    Sleep 60
    $NewDesktopImageStatus = Invoke-RestMethod "$app_url/api/v1/job/$($NewDesktopImage.job.id)" -Method Get -Headers $headers 
}

if ($NewDesktopImageStatus.jobStatus -eq 'Failed') {
    Throw "Error creating desktop image"
}
