## Set Search Admin Component
Write-Host "Set Search Admin Component..."
$AdminComponent =  Get-SPEnterpriseSearchAdministrationComponent -SearchApplication $searchApp | Set-SPEnterpriseSearchAdministrationComponent -SearchServiceInstance $hostA 