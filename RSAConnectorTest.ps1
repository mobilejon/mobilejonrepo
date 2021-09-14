#----------------------------------------------------------[Declarations]----------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#-----------------------------------------------------------[Functions]------------------------------------------------------------
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("client-key", "CLIENTKEY")
$headers.Add("Content-Type", "application/json")
$body = "`n{`n  `"authnAttemptTimeout`": 10,`n  `"clientId`": `"vidm01.mobilejon.com`",`n  `"subjectName`": `"mobilejon`",`n  `"lang`": `"en_US`",`n  `"assurancePolicyId`": `"aea87a57-f349-4fee-b615-15447d88e7b9`",`n  `"sessionAttributes`": [],`n  `"subjectCredentials`": [`n    {`n      `"methodId`": `"SECURID`",`n      `"collectedInputs`": [`n        {`n          `"name`": `"SECURID`",`n          `"value`": `"03538482`",`n          `"dataType`": `"STRING`"`n        }`n      ]`n    }`n  ],`n  `"context`": {`n    `"messageId`": `"50542c7b-86f3-45a9-8d6b-7500b9130047`"`n  },`n  `"keepAttempt`": false`n}"
$response = Invoke-RestMethod 'https://rsaserver.mobilejon.com:5555/mfa/v1_1/authn/initialize' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json
