## Start Query and Site Settings Service Instance

Write-Host "
Starting Search Query and Site Settings Service Instance on" $hostA.server.Name "and" $hostB.server.Name
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $hostA.server.Name
Do { Start-Sleep 3;
Write-host -NoNewline "."  } 

While ((Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance | Where {$_.Server.Name -eq $hostA.server.Name}).status -ne 'Online')
Write-Host -ForegroundColor Green "
    Query and Site Settings Service Instance Started on" $hostA.Server.Name

<#
 
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $hostB.server.Name
Do { Start-Sleep 3;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance | Where {$_.Server.Name -eq $hostB.server.Name}).status -ne 'Online')
Write-Host -ForegroundColor Green "
    Query and Site Settings Service Instance Started on" $hostB.Server.Name 
  #>