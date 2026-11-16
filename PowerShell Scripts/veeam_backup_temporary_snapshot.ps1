# SMTP settings
$smtpServer = "server_name"
$senderEmail = "sendr_email_address"
$recipientEmail = @("recipient_email_address")
#$ccEmail = @("cc_email_address")
$subject = "Snapshot Report Across All vCenter Servers"

# List of vCenter servers
$vCenterServers = @("vCenterServer1", "vCenterServer2", "vCenterServer3")

# Optional CSS styling for the HTML email
$style = @"
<style>
body { font-family: Calibri, sans-serif; }
table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
th { background-color: #f2f2f2; }
h2 { color: #2a2a2a; }
</style>
"@

# Start building HTML body
$htmlBody = @"
<html>
<head>
$style
</head>
<body>
<h1>Snapshot Report</h1>
"@

foreach ($vCenter in $vCenterServers) {
    $creds = Import-Clixml -Path "C:\SecureCreds\$vCenter-creds.xml"

    try {
        # Connect to the vCenter
        $viServer = Connect-VIServer -Server $vCenter -Credential $creds -ErrorAction Stop

        # Get snapshot data scoped to the current server
        $snapshots = Get-VM -Server $viServer | Get-Snapshot -Server $viServer | `
            Where-Object { $_.Name -eq "VEEAM BACKUP TEMPORARY SNAPSHOT" } | `
            Select-Object `
                @{Name="VM Name"; Expression={$_.VM.Name}},
                Name,
                Description,
                Created,
                @{Name="Snapshot Age (Days)"; Expression={ [math]::Round(((Get-Date) - $_.Created).TotalDays, 1) }},
                SizeMB,
                Quiesced,
                PowerState,
                IsCurrent,
                @{Name="Needs Consolidation"; Expression={ $_.VM.ExtensionData.Runtime.ConsolidationNeeded }},
                @{Name="Snapshot State"; Expression={ $_.ExtensionData.State }}

        if ($snapshots) {
            $htmlBody += "<h2>Snapshots on $vCenter</h2>"
            $htmlBody += "<table><tr>
                <th>VM Name</th>
                <th>Snapshot Name</th>
                <th>Description</th>
                <th>Created</th>
                <th>Snapshot Age (Days)</th>
                <th>SizeMB</th>
                <th>Quiesced</th>
                <th>PowerState</th>
                <th>IsCurrent</th>
                <th>Needs Consolidation</th>
                <th>Snapshot State</th>
            </tr>"

            foreach ($snap in $snapshots) {
                $age = [math]::Round(((Get-Date) - $snap.Created).TotalDays, 1)
                $needsConsolidation = $snap.'Needs Consolidation'

                # Highlight row if age > 1 or needs consolidation
                $rowColor = ""
                if ($age -gt 1 -or $needsConsolidation) {
                    $rowColor = " style='background-color:#ffe6e6'"
                }

                $htmlBody += "<tr$rowColor>
                    <td>$($snap.'VM Name')</td>
                    <td>$($snap.Name)</td>
                    <td>$($snap.Description)</td>
                    <td>$($snap.Created)</td>
                    <td>$age</td>
                    <td>$($snap.SizeMB)</td>
                    <td>$($snap.Quiesced)</td>
                    <td>$($snap.PowerState)</td>
                    <td>$($snap.IsCurrent)</td>
                    <td>$needsConsolidation</td>
                    <td>$($snap.'Snapshot State')</td>
                </tr>"
            }

            $htmlBody += "</table>"
        } else {
            $htmlBody += "<h2>Snapshots on $vCenter</h2><p>No matching snapshots found.</p>"
        }

        # Disconnect from this vCenter only
        Disconnect-VIServer -Server $viServer -Confirm:$false
        Write-Host "Disconnected from vCenter Server: $viServer" -ForegroundColor Green
    }
    catch {
        $htmlBody += "<h2>$vCenter</h2><p style='color:red;'>Error: $($_.Exception.Message)</p>"
    }
}

# Close HTML body
$htmlBody += @"
</body>
</html>
"@

# Send the email
Send-MailMessage -SmtpServer $smtpServer -From $senderEmail -To $recipientEmail  -Subject $subject -Body $htmlBody -BodyAsHtml
