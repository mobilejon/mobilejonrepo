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

# ===================== GET WINDOWS PROFILES VIA API =====================
try {
  $Profiles = Invoke-RestMethod -Headers $header -Uri "$apiBase/API/mdm/profiles/search"
} catch {
  throw "API call failed: $($_.Exception.Message)"
}

# Filter for Windows profiles (your snippet used 'WinRT')
$WindowsProfiles = $Profiles.ProfileList | Where-Object { $_.Platform -eq "WinRT" }
if (-not $WindowsProfiles) { Write-Warning "No Windows (WinRT) profiles found from API."; return }
Write-Host ("Found {0} Windows profiles" -f ($WindowsProfiles | Measure-Object).Count)


# Ensure output folder
$null = New-Item -ItemType Directory -Path 'C:\temp' -Force

# Pull details and write a single JSON file
$details = $WindowsProfiles | ForEach-Object {
  Invoke-RestMethod -Uri "$apiBase/API/mdm/profiles/$($_.ProfileId)" -Headers $header -Method Get
}

$details | ConvertTo-Json -Depth 25 | Set-Content 'C:\temp\WindowsPolicies.json' -Encoding UTF8
