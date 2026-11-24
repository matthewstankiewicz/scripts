$credPath = "C:\SecureCreds"

$files = @(
    "Server1-creds.xml",
    "Server2-creds.xml",
    "Server3-creds.xml"
)

foreach ($file in $files) {

    $fullPath = Join-Path $credPath $file

    # Read existing credential
    $oldCred = Import-Clixml $fullPath

    Write-Host ""
    Write-Host "Updating $file"
    Write-Host "Username: $($oldCred.UserName)"

    # Backup
    Copy-Item $fullPath "$fullPath.bak" -Force

    # Prompt for the new password for this specific account
    $newPassword = Read-Host "Enter NEW password for $($oldCred.UserName)" -AsSecureString

    # Create updated credential
    $newCred = New-Object System.Management.Automation.PSCredential (
        $oldCred.UserName,
        $newPassword
    )

    # Save updated credential
    $newCred | Export-Clixml $fullPath

    Write-Host "Updated $file"
}

Write-Host "`nAll credential files updated."