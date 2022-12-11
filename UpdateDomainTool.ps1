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
        "Accept"         = "application/json;version=2";
	    "aw-tenant-code" = $apikey;
	    "Content-Type"   = "application/json";}
	 
	##Prompt for the API hostname##
	$apihost = Read-Host -Prompt 'Enter your API server hostname'
	 
    ##Prompt for Path for CSV Import of User List##
    $csv = Read-Host -Prompt 'Enter the Path of your User CSV Template'
    $userlist = import-csv $csv | foreach {Invoke-RestMethod -headers $header -Uri https://$apihost/API/system/users/search?username=$($_.username)}
	 
	##Prompt for the Username##
	 
	##$username = Read-Host -Prompt 'Enter the username for the device you want to migrate'
	 
	##Get the User ID##
	##$userresults = Invoke-RestMethod -headers $header -Uri https://$apihost/API/system/users/search?username=$username
	##$userid = $userresults.users.id.value
    ##$useruuid = $userresults.users.uuid
	##Define the Domain Attribute you want to update##
	    $UUIDs = $userlist.users.uuid    $domain = Read-Host -Prompt 'Enter the domain you want to migrate to'    ##Build the Body##     $script:body = @{
    "domain"  = $domain
        }    ##Convert Body to Json##    $body = $body | ConvertTo-Json    ##Update the Domain##   ## Invoke-RestMethod -Method Put -Headers $header -Uri https://$apihost/API/system/users/$useruuid -Body $body -ContentType application/json    ##Set the Domain for Each User#    foreach ($UUID in $UUIDs) {Invoke-RestMethod -Method Put -Headers $header -Uri https://$apihost/API/system/users/$uuid -Body $body -ContentType application/json}