# Run as admin

$tenantInfoPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo"
$maxRetries = 24   # 4 hours / 10 minutes per retry
$retryCount = 0

while (-not (Test-Path $tenantInfoPath) -and $retryCount -lt $maxRetries) {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Path not found, retrying in 5 minutes... (Attempt $($retryCount+1) of $maxRetries)"
    Start-Sleep -Seconds 300
    $retryCount++
}

if (Test-Path $tenantInfoPath) {
    $key = "$tenantInfoPath\*"
    $keyinfo = Get-Item $key
    $url = $keyinfo.Name.Split("\")[-1]
    $path = "$tenantInfoPath\$url"

    New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' -PropertyType String -Force -ea SilentlyContinue
    New-ItemProperty -LiteralPath $path -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx' -PropertyType String -Force -ea SilentlyContinue
    New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance' -PropertyType String -Force -ea SilentlyContinue

    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Successfully updated MDM registry values."
}
else {
    Write-Warning "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Path not found after 2 hours, exiting script."
}
