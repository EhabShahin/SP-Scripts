## Create Search Service Application Proxy
Write-Host "Creating Search Service Application Proxy..."
$searchAppProxy = New-SPEnterpriseSearchServiceApplicationProxy -Name "$searchName Proxy" -SearchApplication $searchApp