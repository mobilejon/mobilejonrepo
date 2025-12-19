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
$StreamName          = "Custom-SecureBootServicing_CL"

$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing"

# Troubleshooting switch: set to $true to send a known-good payload (no registry read needed)
$UseDebugPayload = $false

# Optional: enforce TLS 1.2 (safe default)
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# Normalize DCE URI (avoid accidental double-slashes)
$DceLogsIngestionUri = $DceLogsIngestionUri.TrimEnd("/")


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

    # Build record with stable schema (all fields always present)
    $record = [ordered]@{
        TimeGenerated            = (Get-Date).ToUniversalTime().ToString("o")  # ISO 8601 UTC
        Hostname                 = $env:COMPUTERNAME
        RegistryPath             = $RegPath
        UEFICA2023Status         = $null
        WindowsUEFICA2023Capable = $null
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

    # IMPORTANT: braces prevent PowerShell from eating ?api-version as part of the variable name
    $uri = "$DceLogsIngestionUri/dataCollectionRules/$DcrImmutableId/streams/${StreamName}?api-version=2023-01-01"

    # Make URI visible + accessible after execution
    $global:LastIngestionUri = $uri

    Write-Host "POST URI: $uri"
    Write-Host "Payload:  $JsonPayload"

    try {
        $resp = Invoke-WebRequest -Method POST -Uri $uri -Headers @{
            Authorization = "Bearer $AccessToken"
        } -ContentType "application/json" -Body $JsonPayload -UseBasicParsing

        Write-Host "HTTP Status: $($resp.StatusCode)"

        # Helpful headers (may or may not be present)
        $reqId  = $resp.Headers["x-ms-request-id"]
        $corrId = $resp.Headers["x-ms-correlation-request-id"]
        if ($reqId)  { Write-Host "x-ms-request-id: $reqId" }
        if ($corrId) { Write-Host "x-ms-correlation-request-id: $corrId" }

        return $true
    }
    catch {
        $msg = $_.Exception.Message

        # If response exists, surface status code + response body
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
Write-Host "Acquiring token..."
$token = Get-LogsIngestionToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $Secret

# Build payload
if ($UseDebugPayload) {
    Write-Host "Using DEBUG payload (no registry read)."
    $record = [ordered]@{
        TimeGenerated            = (Get-Date).ToUniversalTime().ToString("o")
        Hostname                 = $env:COMPUTERNAME
        RegistryPath             = $RegPath
        UEFICA2023Status         = "test"
        WindowsUEFICA2023Capable = "test"
    }
} else {
    Write-Host "Collecting registry values from: $RegPath"
    $record = Get-SecureBootServicingRecord -RegPath $RegPath
}

# Logs Ingestion expects an array
$payload = ConvertTo-Json -InputObject @($record) -Depth 6

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
Write-Host "Validate in Log Analytics (after 2–10 minutes) with:"
Write-Host "  SecureBootServicing_CL | where ingestion_time() > ago(2h) | order by ingestion_time() desc"
