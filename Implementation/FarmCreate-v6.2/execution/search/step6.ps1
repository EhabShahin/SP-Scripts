## Get Initial Search Topology
Write-Host "Get Initial Search Topology..."
$initialTopology = Get-SPEnterpriseSearchTopology -SearchApplication $searchApp
 
## Create Clone Search Topology
Write-Host "Creating Clone Search Topology..."
$cloneTopology = New-SPEnterpriseSearchTopology -SearchApplication $searchApp -Clone -SearchTopology $initialTopology 
