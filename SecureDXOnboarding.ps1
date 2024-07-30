[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$file_path = "C:\Program Files\ControlUp\SRM\srmagent.exe"
$latest_version = "C:\ProgramData\ControlUp\SRM\LatestSRMversion.txt"
$urlfileversion = "https://cdn.spm.controlup.com/agent/LatestSRMversion.txt"
$folderPath = "C:\ProgramData\ControlUp\SRM"
$outputfileversion = "$folderPath\LatestSRMversion.txt"

# Check if the service CUPSDXAgent exists
$serviceName = "CUPSDXAgent"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

function install_srm {
    $url = "https://cdn.spm.controlup.com/agent/SRMagentSetup.exe"
    $folderPath = "C:\ProgramData\ControlUp"
    $output = "$folderPath\srmagentsetup.exe"
    $processNames = @("brooklyn_cli","brooklyn","brooklyninstall","srmagentsetupscoutbees","conhost","srmagent","wa_3rd_party_host_32","wa_3rd_party_host_64","notepad","srmagentsetup","srmui")
    $installfolder = "C:\Program Files\ControlUp\SRM"

    # Iterate through the process names
    ForEach ($processName in $processNames) {
        # Check if the process is currently running
        if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
            # If the process is running, kill it
            Stop-Process -Name $processName -Force
        }
    }

    # Check if the file exists
    if (Test-Path $output) {
        # File exists, delete it
        Remove-Item -Path $output -Recurse -Force
    }

    function DownloadFile($url, $output) {
        $webRequest = [System.Net.HttpWebRequest]::Create($url)
        $webRequest.Method = "GET"
        $webResponse = $webRequest.GetResponse()

        $totalBytes = $webResponse.ContentLength
        $bufferSize = 4096
        $bytesRead = 0

        $responseStream = $webResponse.GetResponseStream()
        $fileStream = [System.IO.File]::Create($output)

        while ($bytesRead -lt $totalBytes) {
            $buffer = New-Object byte[] $bufferSize
            $read = $responseStream.Read($buffer, 0, $bufferSize)
            $fileStream.Write($buffer, 0, $read)
            $bytesRead += $read

            $progress = [Math]::Floor(($bytesRead / $totalBytes) * 100)
            Write-Host ("Progress: {0}% - {1} of {2} bytes" -f $progress, $bytesRead, $totalBytes)
        }

        $responseStream.Close()
        $fileStream.Close()

        Write-Host "Download completed."
    }

    # Download the file
    DownloadFile $url $output

    # Run the file as an administrator
    Start-Process -FilePath "$output" -ArgumentList "/S"
}

if ($service -eq $null) {
    # Service does not exist, proceed to install SRM
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force
    }

    $AdminGroupSID = "S-1-5-32-544"
    $AdminGroup = New-Object System.Security.Principal.SecurityIdentifier($AdminGroupSID)
    $FolderAcl = Get-Acl -Path $FolderPath
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($AdminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $NewAcl = New-Object System.Security.AccessControl.DirectorySecurity
    $NewAcl.SetAccessRuleProtection($true, $false)
    $NewAcl.AddAccessRule($AccessRule)
    Set-Acl -Path $FolderPath -AclObject $NewAcl
    (Get-Acl -Path $FolderPath).AccessToString

    Invoke-WebRequest -Uri $urlfileversion -OutFile $outputfileversion

    $severlastversion = Get-Content "$latest_version"

    if ((Test-Path $file_path)) {
        $file_version = (Get-Item $file_path).VersionInfo.FileVersion
    } else {
        $file_version = "0.0.0.0"
    }

    # Check the file version and run the corresponding function
    if ($file_version -lt $severlastversion) {
        install_srm
    } else {
        Write-Host "ok"
    }
     Write-Output -InputObject "### SIP EVENT BEGINS ###`nThis device has been successfully onboarded to Secure DX`n### SIP EVENT ENDS ###"
}
catch {
   Write-Output -InputObject "### SIP EVENT BEGINS ###`Oh no! your install has failed!n### SIP EVENT ENDS ###"
}
    Write-Output("### SIP EVENT BEGINS ###")
    # Write event text to stdout here
    Write-Output("### SIP EVENT ENDS ###")
} else {
    Write-Host "Service CUPSDXAgent already exists."
}

