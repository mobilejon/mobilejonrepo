$tenant = ""
$clientId = ""
$clientSecret = ""

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/x-www-form-urlencoded")

    $body = "grant_type=client_credentials&scope=https://graph.microsoft.com/.default"
    $body += -join ("&client_id=" , $clientId, "&client_secret=", $clientSecret)

    $response = Invoke-RestMethod "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token" -Method 'POST' -Headers $headers -Body $body

    #Get Token form OAuth.
    $token = -join ("Bearer ", $response.access_token)

    #Reinstantiate headers.
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $token)
    $headers.Add("Content-Type", "application/json")

# Initialize an array to store all users
$AllUsers = @()

# Initial Graph API request to get all users (handles pagination)
$uri = "https://graph.microsoft.com/v1.0/users"

do {
    # Get users
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

    # Append retrieved users to the list
    $AllUsers += $response.value

    # Check for pagination
    $uri = $response.'@odata.nextLink'
} while ($uri) # Continue if there's another page

Write-Host "Total Users Retrieved: $($AllUsers.Count)"

# Initialize an array to store MFA details
$MFAReport = @()

# Loop through each user to get authentication methods
foreach ($user in $AllUsers) {
    $userId = $user.Id
    $authUri = "https://graph.microsoft.com/v1.0/users/$userId/authentication/methods"

    try {
        # Get authentication methods for the user
        $authMethods = Invoke-RestMethod -Uri $authUri -Headers $headers -Method Get

        # Process each authentication method
        foreach ($method in $authMethods.value) {
            $methodType = $method.'@odata.type' -replace '.*\.', '' # Extract method type
            $methodDetails = ""

            # Initialize fields
            $phoneType = ""
            $phoneNumber = ""
            $windowsHelloDisplayName = ""
            $emailAddress = ""

            switch ($methodType) {
                "microsoftAuthenticator" { $methodDetails = "Microsoft Authenticator App" }
                "fido2SecurityKey" { $methodDetails = "FIDO2 Security Key" }
                "temporaryAccessPass" { $methodDetails = "Temporary Access Pass" }
                "emailAuthenticationMethod" { $methodDetails = "Email MFA" 
                $emailAddress = $method.emailAddress             
                }
                "phoneAuthenticationMethod" {
                    $phoneType = $method.phoneType
                    $phoneNumber = $method.phoneNumber
                    $methodDetails = "Phone ($phoneType): $phoneNumber"
                }
                "windowsHelloForBusinessAuthenticationMethod" {
                    $windowsHelloDisplayName = $method.displayName
                    $methodDetails = "Windows Hello for Business ($windowsHelloDisplayName)"
                }
                Default { $methodDetails = $methodType }
            }

            # Store results in the report array
            $MFAReport += [PSCustomObject]@{
                DisplayName        = $user.DisplayName
                UserPrincipalName  = $user.UserPrincipalName
                UserId             = $user.Id
                MFA_Method         = $methodDetails
                PhoneType          = $phoneType
                PhoneNumber        = $phoneNumber
                WindowsHelloDisplayName = $windowsHelloDisplayName
                EmailAddress = $emailAddress
            }
        }
    } catch {
        Write-Warning "Failed to retrieve authentication methods for user: $($user.UserPrincipalName)"
    }
}

# Export MFA methods report to CSV
$MFAReport | Export-Csv -Path "C:\temp\MFA_AuthMethods_Report.csv" -NoTypeInformation

Write-Host "MFA authentication methods report exported to MFA_AuthMethods_Report.csv"
