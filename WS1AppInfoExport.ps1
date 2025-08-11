[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Username = Read-Host -Prompt 'Enter the Username'
    $Password = Read-Host -Prompt 'Enter the Password' -AsSecureString
    $apikey = Read-Host -Prompt 'Enter the API Key'

    #Convert the Password
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    #Base64 Encode AW Username and Password
    $combined = $Username + ":" + $UnsecurePassword
    $encoding = [System.Text.Encoding]::ASCII.GetBytes($combined)
    $cred = [Convert]::ToBase64String($encoding)
    $script:header = @{
    "Authorization"  = "Basic $cred";
    "aw-tenant-code" = $apikey;
    "Content-Type"   = "application/json";
     "Accept"         = "application/json;version=2"
    }

##Prompt for the API hostname##
$apihost = Read-Host -Prompt 'Enter your API server hostname'
$apiBase     = "https://$apihost"
# ===================== GET WINDOWS APPS VIA API =====================
try {
  $AppList = Invoke-RestMethod -Headers $header -Uri "$apiBase/API/mam/apps/search"
} catch {
  throw "API call failed: $($_.Exception.Message)"
}

# Filter for Windows apps (your snippet used 'WinRT')
$WindowsApps = $AppList.applications | Where-Object { $_.Platform -eq "Win_RT" }
if (-not $WindowsApps) { Write-Warning "No Windows (WinRT) apps found from API."; return }
Write-Host ("Found {0} Windows apps" -f ($WindowsApps| Measure-Object).Count)
$details = $WindowsApps | ForEach-Object {
  Invoke-RestMethod -Uri "$apiBase/API/mam/apps/internal/$($_.uuid)" -Headers $header -Method Get
}
$details | ConvertTo-Json -Depth 25 | Set-Content 'C:\temp\WindowsApps.json' -Encoding UTF8
