----------------------------------------------------------[Declarations]----------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#-----------------------------------------------------------[Functions]------------------------------------------------------------
$ConnectionServer = ""
$script:hvServer = Connect-HVServer -Server $ConnectionServer -User -Password  -Domain
$script:hvServices = $hvServer.ExtensionData
$script:connectionServers = $script:hvServices.connectionserver.ConnectionServer_List()
[System.Collections.ArrayList]$ws1array = @()
foreach($cs in $script:connectionServers){
$name = $cs.general.name
$id = $cs.id
$ws1mode = $cs.Authentication.SamlConfig.WorkspaceONEData.WorkspaceOneModeEnabled
$val = [pscustomobject]@{'Server Name'=$name ;'WS1 Status'=$ws1mode}
$ws1array.add($val) | Out-Null
$val=$null
##Send Email##$
}
​
$ws1status = $ws1array | Format-List | Out-String
If ($ws1array.("WS1 Status") -match 'False') {
$emailBody = ("Current WS1 Status of Connection Servers:" + $ws1status)
$emailFrom =""
$emailTo = ""
        $subject = "Horizon Workspace ONE Mode Health"
        $smtpServer = ""
        $smtp = new-object Net.Mail.SmtpClient($smtpServer)
        $smtp.Send($emailFrom, $emailTo, $subject, $emailBody)
}
