    ## Create Search Service Application
Write-Host "
Creating Search Service Application..."
 
$searchAppPool = Get-SPServiceApplicationPool -Identity $searchAppPoolName 
 
IF ((Get-SPEnterpriseSearchServiceApplication).Status -ne 'Online'){
Write-Host " Provisioning. Please wait..."
$searchApp = New-SPEnterpriseSearchServiceApplication -Name $searchName -ApplicationPool $searchAppPool -AdminApplicationPool $searchAppPool -DatabaseName $searchDB
DO {start-sleep 2;
write-host -nonewline "." } While ( (Get-SPEnterpriseSearchServiceApplication).status -ne 'Online')
Write-Host -f green " 
    Provisioned Search Service Application"
} ELSE {  write-host -f green "Search Service Application already provisioned."
$searchApp = Get-SPEnterpriseSearchServiceApplication
} 
