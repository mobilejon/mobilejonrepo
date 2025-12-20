<# 
Secure Boot Servicing → Log Analytics (DCR/DCE “direct ingest”)

What it does:
- Reads: HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing
- Captures: UTC timestamp, hostname, registry path, UEFICA2023Status, WindowsUEFICA2023Capable
- Sends one JSON record to Log Analytics via Logs Ingestion API (DCE + DCR)

Prereqs:
- DCR is created (yours is)
- App registration exists + client secret (or cert)
- The app’s service principal has RBAC on the DCR (role assignment you just did)
#>

$ErrorActionPreference = "Stop"

# ----------------------------
# CONFIG — fill these in
# ----------------------------
$TenantId  = ""          # Entra ID tenant (Directory) ID
$ClientId  = ""          # App registration (Application) ID
$Secret    = ""      # Client secret VALUE

$DceLogsIngestionUri = ""
$DcrImmutableId      = ""
$StreamName = ""

$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing"

# Optional: enforce TLS 1.2 (safe default)
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# Normalize DCE URI (avoid accidental double-slashes)
$DceLogsIngestionUri = $DceLogsIngestionUri.TrimEnd("/")

# ----------------------------
# Ensure Get-UEFICertificate is available
# ----------------------------
function Ensure-GetUefiCertificate {
    if (Get-Command -Name Get-UEFICertificate -ErrorAction SilentlyContinue) {
        return
    }

    # Try to install once if missing. This may require admin rights and PSGallery access.
    Write-Host "Get-UEFICertificate not found. Installing Get-UEFICertificate..."
    try {
        # Ensure NuGet provider exists
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force | Out-Null
        }

        # Ensure PSGallery is trusted (optional; remove if you prefer prompts)
        try { Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue } catch {}

        Install-Script -Name Get-UEFICertificate -Force -Scope AllUsers
    }
    catch {
        throw "Failed to install Get-UEFICertificate. Preinstall it on the machine or ensure PSGallery access. Error: $($_.Exception.Message)"
    }

    if (-not (Get-Command -Name Get-UEFICertificate -ErrorAction SilentlyContinue)) {
        throw "Get-UEFICertificate still not available after install attempt."
    }
}

function Get-LogsIngestionToken {
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret
    )

    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        scope         = "https://monitor.azure.com/.default"
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
    }

    try {
        $resp = Invoke-RestMethod -Method POST -Uri $tokenUri -Body $body -ContentType "application/x-www-form-urlencoded"
        if (-not $resp.access_token) { throw "Token response did not include access_token." }
        return $resp.access_token
    }
    catch {
        $msg = $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $msg += "`nDetails: $($_.ErrorDetails.Message)" }
        throw "Failed to acquire token. $msg"
    }
}

function Get-SecureBootServicingRecord {
    param([Parameter(Mandatory)][string]$RegPath)

    # --- KEK data (collected here to avoid scope issues) ---
    $kekThumbprint = $null
    $kekIssued     = $null
    $kekExpires    = $null

    try {
        Ensure-GetUefiCertificate
        $kek = Get-UEFICertificate -Type KEK

        # Depending on the script version, these properties may vary.
        # These are the typical names used by Richard Hicks' script.
        if ($kek) {
            $kekThumbprint = $kek.Thumbprint
            $kekIssued     = $kek.Issued
            $kekExpires    = $kek.Expires
        }
    }
    catch {
        # Don't fail ingestion if KEK read fails; just send nulls.
        Write-Warning "Unable to collect KEK certificate data: $($_.Exception.Message)"
    }

    # Build record with stable schema (all fields always present)
    $record = [ordered]@{
        TimeGenerated            = (Get-Date).ToUniversalTime().ToString("o")  # ISO 8601 UTC
        Hostname                 = $env:COMPUTERNAME
        RegistryPath             = $RegPath
        UEFICA2023Status         = $null
        WindowsUEFICA2023Capable = $null
        KEK_Thumbprint           = $kekThumbprint
        KEK_IssueDate            = if ($kekIssued)  { (Get-Date $kekIssued).ToUniversalTime().ToString("o") } else { $null }
        KEK_ExpirationDate       = if ($kekExpires) { (Get-Date $kekExpires).ToUniversalTime().ToString("o") } else { $null }
    }

    if (-not (Test-Path -Path $RegPath)) {
        # Key missing (older OS / not applicable). Still send a record.
        return $record
    }

    $props = Get-ItemProperty -Path $RegPath

    if ($props.PSObject.Properties.Name -contains "UEFICA2023Status") {
        $record.UEFICA2023Status = [string]$props.UEFICA2023Status
    }
    if ($props.PSObject.Properties.Name -contains "WindowsUEFICA2023Capable") {
        $record.WindowsUEFICA2023Capable = [string]$props.WindowsUEFICA2023Capable
    }

    return $record
}

function Send-ToLogAnalyticsViaDcr {
    param(
        [Parameter(Mandatory)][string]$DceLogsIngestionUri,
        [Parameter(Mandatory)][string]$DcrImmutableId,
        [Parameter(Mandatory)][string]$StreamName,
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter(Mandatory)][string]$JsonPayload
    )

    $uri = "$DceLogsIngestionUri/dataCollectionRules/$DcrImmutableId/streams/${StreamName}?api-version=2023-01-01"
    $global:LastIngestionUri = $uri

    Write-Host "POST URI: $uri"
    Write-Host "Payload:  $JsonPayload"

    try {
        $resp = Invoke-WebRequest -Method POST -Uri $uri -Headers @{
            Authorization = "Bearer $AccessToken"
        } -ContentType "application/json" -Body $JsonPayload -UseBasicParsing

        Write-Host "HTTP Status: $($resp.StatusCode)"

        $reqId  = $resp.Headers["x-ms-request-id"]
        $corrId = $resp.Headers["x-ms-correlation-request-id"]
        if ($reqId)  { Write-Host "x-ms-request-id: $reqId" }
        if ($corrId) { Write-Host "x-ms-correlation-request-id: $corrId" }

        return $true
    }
    catch {
        $msg = $_.Exception.Message

        if ($_.Exception.Response) {
            try {
                $status = [int]$_.Exception.Response.StatusCode
                $msg += "`nHTTP Status: $status"
            } catch {}

            try {
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    $body = $reader.ReadToEnd()
                    if ($body) { $msg += "`nResponse body: $body" }
                }
            } catch {}
        }

        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $msg += "`nDetails: $($_.ErrorDetails.Message)"
        }

        throw "Ingestion POST failed. $msg"
    }
}

# ----------------------------
# MAIN
# ----------------------------
if ([string]::IsNullOrWhiteSpace($TenantId) -or
    [string]::IsNullOrWhiteSpace($ClientId) -or
    [string]::IsNullOrWhiteSpace($Secret)) {
    throw "TenantId, ClientId, and Secret must be filled in."
}

Write-Host "Acquiring token..."
$token = Get-LogsIngestionToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $Secret

Write-Host "Collecting registry + KEK values..."
$record = Get-SecureBootServicingRecord -RegPath $RegPath

# Logs Ingestion expects an array
$payload = ConvertTo-Json -InputObject @($record) -Depth 8

Write-Host "Sending record to Log Analytics..."
$ok = Send-ToLogAnalyticsViaDcr `
    -DceLogsIngestionUri $DceLogsIngestionUri `
    -DcrImmutableId $DcrImmutableId `
    -StreamName $StreamName `
    -AccessToken $token `
    -JsonPayload $payload

Write-Host "Success: $ok"
Write-Host "LastIngestionUri (debug): $global:LastIngestionUri"
Write-Host ""
