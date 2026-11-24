# List of vCenter servers
$vCenterServers = @("Server1", "Server2", "Server3")

# Distribute variables to groups.
$vCenterServers | ForEach-Object {

$vCenter = $_

# Get credentials
$creds = Get-Credential -Message "Enter credentials for vCenter server: $_"

$creds | Export-Clixml -Path "C:\SecureCreds\$_-creds.xml"

}

