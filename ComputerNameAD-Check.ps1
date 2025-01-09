## Define the Computer Name Prefix to Check For ##
$Prefix = ""
Write-Host "Checking computer name prefix: $Prefix"
$details = Get-ComputerInfo

# See if we are AD or AAD joined
$isAD = $false
$isAAD = $false
$tenantID = $null
$goodToGo = $true

if ($details.CsPartOfDomain) {
    Write-Host "Device is joined to AD domain: $($details.CsDomain)"
    $isAD = $true
    $goodToGo = $false # Initialize as false; will validate connectivity below
} else {
    if (Test-Path "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo") {
        $subKey = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"
        $guids = $subKey.GetSubKeyNames()
        foreach ($guid in $guids) {
            $guidSubKey = $subKey.OpenSubKey($guid)
            $tenantID = $guidSubKey.GetValue("TenantId")
        }
    }
    if ($null -ne $tenantID) {
        Write-Host "Device is joined to AAD tenant: $tenantID"
        $isAAD = $true
    } else {
        Write-Host "Not part of AAD or AD, in a workgroup."
    }
}

# AD connectivity check
if ($isAD) {
    $dcInfo = [ADSI]"LDAP://RootDSE"
    if ($null -eq $dcInfo.dnsHostName) {
        Write-Host "No connectivity to the domain, unable to rename at this point."
        $goodToGo = $false
    } else {
        Write-Host "Domain connectivity verified."
        $goodToGo = $true
    }
}

# Validate prefix and proceed only if conditions are met
if (($Prefix -ne "") -and (-not $details.CsName.StartsWith($Prefix)) -and $goodToGo) {
    Write-Host "Device name doesn't match specified prefix, time to update!"
    Exit 1
} else {
    Write-Output "$($details.CsName) is the current hostname."
}
