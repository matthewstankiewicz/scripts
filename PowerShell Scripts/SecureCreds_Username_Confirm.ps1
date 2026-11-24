Get-ChildItem C:\SecureCreds\*-creds.xml | ForEach-Object {
    $cred = Import-Clixml $_.FullName

    [PSCustomObject]@{
        File     = $_.Name
        UserName = $cred.UserName
    }
}
