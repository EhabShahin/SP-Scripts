## Activate Clone Search Topology
Write-Host "Activating Clone Search Topology...Please wait. This will take some time"
Set-SPEnterpriseSearchTopology -Identity $cloneTopology
 
## Remove Initial Search Topology
Write-Host "Removing Initial Search Topology..."
$initialTopology = Get-SPEnterpriseSearchTopology -SearchApplication $searchApp | where {($_.State) -eq "Inactive"}
Remove-SPEnterpriseSearchTopology -Identity $initialTopology -Confirm:$false 

