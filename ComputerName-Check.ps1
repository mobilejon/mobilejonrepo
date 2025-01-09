##Define the Computer Name Prefix to Check For##
$Prefix = ""
Write-Host $Prefix
$details = Get-ComputerInfo
if (($Prefix -ne "") -and (-not $details.CsName.StartsWith($Prefix))) {
    Write-Host "Device name doesn't match specified prefix, bailing out. Prefix=$Prefix ComputerName=$($details.CsName)"
    Exit 1
}
 else {
    Write-Output "$details.CsName is the current hostname."
}