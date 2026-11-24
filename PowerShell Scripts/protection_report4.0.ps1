# Initialize groups
# $vCenterServers = @("1", "2", "3")
$vCenterServers = @("Server1", "Server2", "Server3")

# Create a list to collect all results
$allResults = @()

# Distribute variables to groups.
$vCenterServers | ForEach-Object {

    $vCenter = $_

    # Get credentials
     $creds = Import-Clixml -Path "C:\SecureCreds\$vCenter-creds.xml"

    # Connect to server
    Connect-VIServer -Server $vCenter -Credential $creds -ErrorAction Stop

    # Tag to exclude
    $excludedTagName = "veeam_excluded"

    # Define the name of the existing custom attribute
    $customAttrName = 'last_veeam_backup'

    # Get all VMs up front
    $allVMs = Get-VM

    # Build a lookup table of tag assignments (if any)
    $tagAssignments = $allVMs | Get-TagAssignment | Select-Object Entity, Tag

    # Group tag assignments by VM entity
    $tagsGroupedByEntity = $tagAssignments | Group-Object Entity

    # Prepare property name list with base fields
    $propertyNames = @('Entity', $customAttrName, 'ProvisionedSpaceGB', 'vCenterServer')

    # Build a dictionary of VMName → tag group for easy lookup
    $tagMap = @{}
    foreach ($group in $tagsGroupedByEntity) {
        $tagMap[$group.Name] = $group.Group
    }

    # Now process every VM, even those without tags
    $results = $allVMs | ForEach-Object {
        $vm = $_
        $vmName = $vm.Name

        # Get custom attribute value
        $customAttrValue = ($vm | Get-Annotation -CustomAttribute $customAttrName).Value

        # Start building result object
        $resultRecord = [ordered]@{
            Entity = $vmName
            $customAttrName = $customAttrValue
            ProvisionedSpaceGB = [math]::Round($vm.ProvisionedSpaceGB, 2)
            vCenterServer = $vCenter
        }

        # If tags exist for this VM, process them
        if ($tagMap.ContainsKey($vmName)) {
            $categoryMap = @{}

            foreach ($tagRecord in $tagMap[$vmName]) {
                $category, $content = $tagRecord.Tag -split '/', 2
                if ($categoryMap.ContainsKey($category)) {
                    $categoryMap[$category] += $content
                } else {
                    $categoryMap[$category] = @($content)
                }
            }

            foreach ($category in $categoryMap.Keys) {
                $joinedTags = ($categoryMap[$category] | Sort-Object -Unique) -join ', '
                $resultRecord[$category] = $joinedTags

                if ($category -notin $propertyNames) {
                    $propertyNames += $category
                }
            }
        }

        [pscustomobject]$resultRecord
    }

    # Add results to the master list
    $allResults += $results

    # Disconnecting from the vCenter Server
    Disconnect-VIServer -Server $global:DefaultVIServers -Force -Confirm:$false

    Write-Host "Disconnected from vCenter Server: $vCenter" -ForegroundColor Green
}

# Export to CSV
$csvPath = "C:\Temp\protection_report.csv"
$allResults | Select-Object -Property $propertyNames | Export-Csv -Path $csvPath -NoTypeInformation
#$allResults | Sort-Object 'VM Backup Protection Status', 'Backup Policy', Entity, ProvisionedSpaveGB, $customAttrName -Descending | Select-Object -Property $propertyNames | Format-Table
Write-Host "Exported report to $csvPath" -ForegroundColor Cyan
