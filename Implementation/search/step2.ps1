## Start Search Service Instances
Write-Host "Starting Search Service Instances..."
# Server 1

IF((Get-SPEnterpriseSearchServiceInstance -Identity $hostA).Status -eq 'Disabled'){
Start-SPEnterpriseSearchServiceInstance -Identity $hostA 
Write-Host "Starting Search Service Instance on" $hostA.Server.Name
Do { Start-Sleep 5;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchServiceInstance -Identity $hostA).Status -eq 'Online')
Write-Host -ForegroundColor Green "Search Service Instance Started on" $hostA.Server.Name
} ELSE { Write-Host -f Green "Search Service Instance is already running on" $hostA.Server.Name  }

 
#Server 2
<#
IF((Get-SPEnterpriseSearchServiceInstance -Identity $hostB).Status -eq 'Disabled'){
Start-SPEnterpriseSearchServiceInstance -Identity $hostB 
Write-Host "Starting Search Service Instance on" $hostB.Server.Name
Do { Start-Sleep 5;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchServiceInstance -Identity $hostB).Status -eq 'Online')
Write-Host -ForegroundColor Green "Search Service Instance Started on" $hostB.Server.Name
} ELSE { Write-Host -f Green "Search Service Instance is already running on" $hostB.Server.Name  }

#>  

#Server 3

IF((Get-SPEnterpriseSearchServiceInstance -Identity $hostC).Status -eq 'Disabled'){
Start-SPEnterpriseSearchServiceInstance -Identity $hostC 
Write-Host "Starting Search Service Instance on" $hostC.Server.Name
Do { Start-Sleep 5;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchServiceInstance -Identity $hostC).Status -eq 'Online')
Write-Host -ForegroundColor Green "Search Service Instance Started on" $hostC.Server.Name
} ELSE { Write-Host -f Green "Search Service Instance is already running on" $hostC.Server.Name  }

 
<#

#Server 4
IF((Get-SPEnterpriseSearchServiceInstance -Identity $hostD).Status -eq 'Disabled'){
Start-SPEnterpriseSearchServiceInstance -Identity $hostD 
Write-Host "Starting Search Service Instance on" $hostD.Server.Name
Do { Start-Sleep 5;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchServiceInstance -Identity $hostD).Status -eq 'Online')
Write-Host -ForegroundColor Green "Search Service Instance Started on" $hostD.Server.Name
} ELSE { Write-Host -f Green "Search Service Instance is already running on" $hostD.Server.Name  }
 #>
