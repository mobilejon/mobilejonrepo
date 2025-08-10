# ===================== PREREQS =====================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---- API creds (your snippet) ----
$Username = Read-Host -Prompt 'Enter the Username'
$Password = Read-Host -Prompt 'Enter the Password' -AsSecureString
$apikey   = Read-Host -Prompt 'Enter the API Key'

# Convert secure string
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Basic auth for API
 $combined = $Username + ":" + $UnsecurePassword
$encoding = [System.Text.Encoding]::ASCII.GetBytes($combined)
$cred     = [Convert]::ToBase64String($encoding)
$header   = @{
  "Authorization"  = "Basic $cred"
  "aw-tenant-code" = $apikey
  "Content-Type"   = "application/json"
  "Accept"         = "application/json;version=3"
}

# ---- Hosts ----
$apihost = Read-Host -Prompt 'Enter your API server hostname (e.g. as1688.awmdm.com)'
# Derive Console host from API host (as#### -> cn####). If not matching, just swap "as"->"cn".
if ($apihost -match '^as(\d+)\.awmdm\.com$') { $consoleHost = "cn$($Matches[1]).awmdm.com" }
else { $consoleHost = ($apihost -replace '^as','cn') }
$apiBase     = "https://$apihost"
$consoleBase = "https://$consoleHost"

Write-Host "API host:     $apiBase"
Write-Host "Console host: $consoleBase"

# ===================== GET WINDOWS PROFILES VIA API =====================
try {
  $Profiles = Invoke-RestMethod -Headers $header -Uri "$apiBase/API/mdm/profiles/search"
} catch {
  throw "API call failed: $($_.Exception.Message)"
}

# Filter for Windows profiles (your snippet used 'WinRT')
$WindowsProfiles = $Profiles.ProfileList | Where-Object { $_.Platform -eq "WinRT" }
if (-not $WindowsProfiles) {
  Write-Warning "No Windows (WinRT) profiles found from API."
  return
}
Write-Host ("Found {0} Windows profiles" -f ($WindowsProfiles | Measure-Object).Count)

# ===================== CONSOLE LOGIN (AJAX TWO-STEP) =====================
$session     = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$LoginUrl    = "$consoleBase/AirWatch/Login"
$ActionUrl   = "$consoleBase/AirWatch/Login/Login/Login-User"
$ProfilesUrl = "$consoleBase/AirWatch/Profiles"

function Parse-Inputs([string]$Html) {
  [regex]::Matches($Html,'<input[^>]*>','IgnoreCase') | ForEach-Object {
    $tag=$_.Value
    [pscustomobject]@{
      name  = ([regex]::Match($tag,'\bname="([^"]*)"', 'IgnoreCase').Groups[1].Value)
      type  = ([regex]::Match($tag,'\btype="([^"]*)"', 'IgnoreCase').Groups[1].Value)
      value = ([regex]::Match($tag,'\bvalue="([^"]*)"', 'IgnoreCase').Groups[1].Value)
    }
  }
}
function Get-HiddenInputs([string]$Html){
  $d=@{}
  Parse-Inputs $Html | ? { $_.type -ieq 'hidden' -and $_.name } | % { $d[$_.name]=$_.value }
  $d
}
function GetAntiForgeryCookie([string]$Base){
  ($session.Cookies.GetCookies($Base) | ? { $_.Name -like '__RequestVerificationToken*' } | Select -First 1).Value
}
function New-AjaxHeaders([string]$Base,[string]$Referer,[string]$FieldTok){
  $h=@{
    'X-Requested-With'         = 'XMLHttpRequest'
    'Accept'                   = 'application/json, text/javascript, */*; q=0.01'
    'Origin'                   = $Base
    'Referer'                  = $Referer
    'User-Agent'               = 'Mozilla/5.0'
    'RequestVerificationToken' = $FieldTok
  }
  $cookieTok = GetAntiForgeryCookie $Base
  if ($cookieTok) { $h['X-RequestVerificationToken'] = "$($FieldTok):$($cookieTok)" }
  $h
}

# Step 0: GET login page
$p0 = Invoke-WebRequest -Uri $LoginUrl -WebSession $session -MaximumRedirection 10 -Headers @{
  'Accept'          = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
  'Accept-Language' = 'en-US,en;q=0.9'
  'User-Agent'      = 'Mozilla/5.0'
}
$h0 = Get-HiddenInputs $p0.Content
$fieldTok0 = $h0['__RequestVerificationToken']; if (-not $fieldTok0) { $fieldTok0 = GetAntiForgeryCookie $consoleBase }
if (-not $fieldTok0) { throw "No anti-forgery token on login page." }

# Step 1: POST username (AJAX)
$body1 = @{}
$h0.Keys | % { $body1[$_] = $h0[$_] }
$body1['UserName'] = $Username
if ((Parse-Inputs $p0.Content | ? { $_.name -ieq 'RememberUsername' }).Count) { $body1['RememberUsername'] = 'false' }
$body1['Login'] = 'Next'
$hdrs1 = New-AjaxHeaders -Base $consoleBase -Referer $LoginUrl -FieldTok $fieldTok0
$r1 = Invoke-WebRequest -Method POST -Uri $ActionUrl -WebSession $session `
      -Headers $hdrs1 -Body $body1 -ContentType "application/x-www-form-urlencoded; charset=UTF-8"
$j1 = $r1.Content | ConvertFrom-Json
if ($j1.IsSessionExpired) { throw "Step 1: session expired (CSRF mismatch)." }
if (-not $j1.HasView -or [string]::IsNullOrEmpty($j1.ViewHtml)) {
  $msg = if ($j1.Message) { $j1.Message } else { "No ViewHtml returned." }
  throw "Step 1 failed: $msg"
}

# Step 2: POST password (AJAX)
$html2    = $j1.ViewHtml
$h2       = Get-HiddenInputs $html2
$fieldTok2= $h2['__RequestVerificationToken']; if (-not $fieldTok2) { throw "No token in password view." }
$body2 = @{}
$h2.Keys | % { $body2[$_] = $h2[$_] }
if ((Parse-Inputs $html2 | ? { $_.name -ieq 'UserName' }).Count) { $body2['UserName'] = $Username }
if    ((Parse-Inputs $html2 | ? { $_.name -ieq 'Password' }).Count) { $body2['Password'] = $UnsecurePassword }
elseif ((Parse-Inputs $html2 | ? { $_.name -ieq 'Passcode' }).Count) { $body2['Passcode'] = $UnsecurePassword }
else { throw "Password/Passcode field not present in password view." }
$body2['Login'] = 'Log In'
$hdrs2 = New-AjaxHeaders -Base $consoleBase -Referer $LoginUrl -FieldTok $fieldTok2
$r2 = Invoke-WebRequest -Method POST -Uri $ActionUrl -WebSession $session `
      -Headers $hdrs2 -Body $body2 -ContentType "application/x-www-form-urlencoded; charset=UTF-8"
$j2 = $r2.Content | ConvertFrom-Json
if ($j2.IsSessionExpired) { throw "Step 2: session expired." }
if (-not $j2.IsSuccess -and [string]::IsNullOrEmpty($j2.RedirectUrl)) {
  $msg = if ($j2.Message) { $j2.Message } else { "Unknown login error" }
  throw "Login failed: $msg"
}
if ($j2.RedirectUrl) {
  $redir = if ($j2.RedirectUrl -match '^https?://') { $j2.RedirectUrl } else { "$consoleBase$($j2.RedirectUrl)" }
  Invoke-WebRequest -Uri $redir -WebSession $session | Out-Null
}

# Get CSRF from Profiles page (once; refresh if needed later)
$pp = Invoke-WebRequest -Uri $ProfilesUrl -WebSession $session
$csrf = ([regex]::Match($pp.Content,'name="__RequestVerificationToken"[^>]*value="([^"]+)"','IgnoreCase').Groups[1].Value)
if (-not $csrf) { $csrf = GetAntiForgeryCookie $consoleBase }
if (-not $csrf) { throw "No __RequestVerificationToken on Profiles page." }

# ===================== DOWNLOAD LOOP PER PROFILE UUID =====================
function Extract-XmlFromModal([string]$html){
  $m = [regex]::Match($html, '(?is)<textarea[^>]*id=["'']Xml["''][^>]*>(.*?)</textarea>')
  if (-not $m.Success) { throw "Couldn't find <textarea id=""Xml""> in the response." }
  $decoded = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value).Trim()
  # Pretty print if well-formed
  try {
    $doc = New-Object System.Xml.XmlDocument
    $doc.PreserveWhitespace = $false
    $doc.LoadXml($decoded)
    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.OmitXmlDeclaration = $false
    $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
    $sw = New-Object System.IO.StringWriter
    $xw = [System.Xml.XmlWriter]::Create($sw, $settings)
    $doc.Save($xw); $xw.Close()
    return $sw.ToString()
  } catch {
    return $decoded
  }
}

$downloadHeaders = @{
  "X-Requested-With"         = "XMLHttpRequest"
  "Accept"                   = "application/xml,text/plain,*/*"
  "Referer"                  = $ProfilesUrl
  "RequestVerificationToken" = $csrf
  "User-Agent"               = "Mozilla/5.0"
}

foreach ($uuid in ($WindowsProfiles | Select-Object -Expand ProfileUuid | Sort-Object -Unique)) {
  if ([string]::IsNullOrWhiteSpace($uuid)) { continue }
  $viewUrl = "$consoleBase/AirWatch/Profiles/ViewProfileXML/$uuid"
  $outFile = "profile-$uuid.xml"

  try {
    $r = Invoke-WebRequest -Uri $viewUrl -WebSession $session -Headers $downloadHeaders
    $raw = $r.Content

    # If server returned session-expired JSON, refresh CSRF once and retry
    $isExpired = $false
    try { $j = $raw | ConvertFrom-Json; $isExpired = ($j -and $j.IsSessionExpired) } catch { $isExpired = $false }
    if ($isExpired) {
      $pp = Invoke-WebRequest -Uri $ProfilesUrl -WebSession $session
      $csrf = ([regex]::Match($pp.Content,'name="__RequestVerificationToken"[^>]*value="([^"]+)"','IgnoreCase').Groups[1].Value)
      if (-not $csrf) { $csrf = GetAntiForgeryCookie $consoleBase }
      $downloadHeaders['RequestVerificationToken'] = $csrf
      $r = Invoke-WebRequest -Uri $viewUrl -WebSession $session -Headers $downloadHeaders
      $raw = $r.Content
    }

    $xmlOut = Extract-XmlFromModal $raw
    $xmlOut | Out-File -Encoding UTF8 $outFile
    Write-Host "✅ Saved $outFile"
  } catch {
    Write-Warning "Failed to fetch $uuid : $($_.Exception.Message)"
  }
}

Write-Host "Done."
