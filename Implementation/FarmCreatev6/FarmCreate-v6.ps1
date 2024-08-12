param ($xmlLocation)

if((Get-PSSnapin | Where {$_.Name -eq "Microsoft.SharePoint.PowerShell"}) -eq $null) 
{
  Add-PSSnapin Microsoft.SharePoint.PowerShell;
}

#$OutputFileLocation = "c:\logs\farmcreate-"+(Get-Date -Format "yyyy-MM-dd-HHmm")+".log"
#Start-Transcript -path $OutputFileLocation -append



if($xmlLocation -eq $null)
{
$xmlLocation = "$PSScriptRoot\FarmInfo.xml"
Write-host "No XML location given, using default of $xmlLocation"
}
else
{
Write-Host "Reading XML from: $xmlLocation"

}

[xml]$xmldata = get-content $xmlLocation
if ($xmldata -eq $null) {
write-host "Error reading XML file. Check location. Fatal error. Script aborting"
exit
}
else
{
#XML file reads HOWEVER - doesn't mean Tags and Values are correct
$DatabaseInstance = $xmldata.values.DatabaseInstance.'#text'
$SQLServerInstance = $xmldata.values.SQLServerInstance.'#text'
$centralAdminPort = $xmldata.values.centralAdminPort.'#text'
$farmName = $xmldata.values.FarmName.'#text'
$farmUser = $xmldata.values.FarmUserName.'#text'
$AppPoolUsername = $xmldata.values.SPAppPoolUsername.'#text'
$adminUser = $xmldata.values.AdminUser.'#text'
$SPSearchUsername = $xmldata.values.SPSearchUsername.'#text'
$Localserverrole = $xmldata.values.Localserverrole.'#text'
$rooturl = $xmldata.values.BaseURL.'#text'
$porturl = $xmldata.values.WebAppSSLPort.'#text'
$AppPoolName = $xmldata.values.SPAppPoolName.'#text'
$WebPoolName = $xmldata.values.SPWebPoolName.'#text'
$spWAName = $xmldata.values.SPWebAppDisplayName.'#text'
$PWADBname = $farmName+$xmldata.values.PWADBnameSuffix.'#text'
$wsscontentDBname = $farmName+$xmldata.values.SPwssContentDBnameSuffix.'#text'
$pwaurl = $rooturl+$xmldata.values.pwaURLSuffix.'#text'
$churl = $rooturl+$xmldata.values.ContentHubURLSuffix.'#text'
$secureStoreTAName = $xmldata.values.SecureStoreTargetAppName.'#text'
$secureStoreTAemail = $xmldata.values.SecureStoreTAemail.'#text'
$workflowhost = $xmldata.values.Workflowhost.'#text'


}

#get credentials for user accounts

##Provision SQL Alias (Registry)
if ($xmldata.values.provsqlalias.'#text' -eq $true) {
  
    $regroot = "HKLM:\Software\Microsoft"
    $regkeyloc = "MSSQLServer\Client\ConnectTo"
    $regfull = $regroot+"\"+$regkeyloc

    $parties=$regkeyloc.split("\")
    $pathbuild=$regroot
    foreach ($item in $parties) {
                $pathbuild += "\"+$item
                $looptime = (Get-Date).Add((New-TimeSpan -Seconds 5)) 
                 while ((test-path -path $pathbuild) -ne $True)
                    {
                        write-host "Creating Registy Location: "$pathbuild
                        New-Item $pathbuild

                      if ((get-date) -gt $looptime) 
                                {
                                write-host "time out, Breaking"
                                break
                                }
                    } 
                }
    $aliasserver="DBMSSOCN,"+$SQLServerInstance
    if ((get-ItemProperty $regfull -Name $DatabaseInstance) -eq $null) {
    write-host "Creating SQL Alias: $DatabaseInstance to SQL Server Instance: $SQLServerInstance" 
    New-ItemProperty $regfull -Name $DatabaseInstance -PropertyType String -Value $aliasserver
    }
    
    }

$farmpass =$null
while ($farmpass -eq $null) {

$farmpass = Get-PnPStoredCredential -Name "FarmPass"
if ($farmpass  -eq $null)
            {
                write-host "Farm User Credentials not found!"
                $securePasswordfarm = Read-Host -Prompt "Master Farm password:" -AsSecureString
                Add-PnPStoredCredential -name "FarmPass" -Username "FarmPass" -Password $securePasswordfarm

            }
    else {
        $Passphrase = $farmpass.Password
        write-host "Farm Pass $farmpass"
    }

    }



$farmAcc =$null
while ($farmAcc -eq $null) {

$farmAcc = Get-PnPStoredCredential -Name $farmUser
if ($farmAcc  -eq $null)
            {
                write-host "Farm User Credentials not found!"
                $securePasswordfarm = Read-Host -Prompt "Farm User - $farmUser password:" -AsSecureString
                Add-PnPStoredCredential -name $farmUser -Username $farmUser -Password $securePasswordfarm

            }
    else {
        write-host "Farm Cred $farmAcc"
    }

    }

$appPoolAcc =$null
while ($appPoolAcc -eq $null) {

$appPoolAcc = Get-PnPStoredCredential -Name $AppPoolUsername
if ($appPoolAcc  -eq $null)
            {
                write-host "Farm User Credentials not found!"
                $securePasswordapppool = Read-Host -Prompt "App Pool - $AppPoolUsername password:" -AsSecureString
                Add-PnPStoredCredential -name $AppPoolUsername -Username $AppPoolUsername -Password $securePasswordapppool

            }
    else {
        write-host "App Pool Cred $appPoolAcc"
    }

    }

$cahost = $null
if ($xmldata.values.causehost.'#text' -eq $true)
            {
                 $cahost = [System.Net.Dns]::GetHostByName($env:computerName).HostName
                 $cacert = New-SelfSignedCertificate -DnsName $cahost -CertStoreLocation "cert:\LocalMachine\My"
            } else {

                    
                $cahost = $xmldata.values.cahostname.'#text'
            }


## check if we building a farm from scratch
if ($xmldata.values.NewFarm.'#text' -eq $true) {
Write-Host "Force upgrade.."
psconfig -cmd upgrade -inplace b2b -wait -force
Write-host "Creating of new farm"
New-SPConfigurationDatabase -DatabaseServer $DatabaseInstance -DatabaseName (“$farmName" + "_SharePoint_Config”) -AdministrationContentDatabaseName ("$farmName" + "_SharePoint_AdminContent”) -Passphrase $Passphrase -FarmCredentials $farmAcc -localserverrole $Localserverrole
$farm = Get-SPFarm
if (!$farm -or $farm.Status -ne "Online") {
    Write-Output "Farm was not created or is not running"
    exit
}

Install-SPHelpCollection –All
Initialize-SPResourceSecurity
Install-SPService
Install-SPApplicationContent
Install-SPFeature -AllExistingFeatures -Force
$fullurl = "https://"+$cahost+":"+$centralAdminPort
New-SPCentralAdministration -Port $centralAdminPort -WindowsAuthProvider "NTLM" -SecureSocketsLayer
# -UseServerNameIndication -Url $fullurl -HostHeader $cahost

# Add managed accounts
Write-Output "Creating managed accounts ..."
New-SPManagedAccount -credential $appPoolAcc
New-SPManagedAccount -credential $unattendedAcc
}
else
{
$farm = Get-SPFarm
if (!$farm -or $farm.Status -ne "Online") {
    Write-Output "Farm is not running"
    exit
}
}

if ($AppPoolUserName -ne $appPoolAcc.UserName) {
write-host "App Pool Username in XML and supplied credentials don't match. Check Case. Aborting"
exit
}


## Check for App Pools and create if needed ##

#Services App Pool
$SAAppPool = Get-SPServiceApplicationPool -Identity $AppPoolName
if($SAAppPool -eq $null)
{
$AppPoolAccount = Get-SPManagedAccount -Identity $AppPoolUserName 
if($AppPoolAccount -eq $null)
{
$AppPoolCred = Get-Credential $AppPoolUserName
$AppPoolAccount = New-SPManagedAccount -Credential $AppPoolCred 
}
$AppPoolAccount = Get-SPManagedAccount -Identity $AppPoolUserName
if($AppPoolAccount -eq $null)
{
Write-Host “Cannot create or find the managed account $appPoolUserName, please ensure the account exists.”
Exit
}
Write-Host "Creating Service App $AppPoolName with account $AppPoolAccount"
New-SPServiceApplicationPool -Name $AppPoolName -Account $AppPoolAccount

}

#Web AppPool
$WAAppPool = Get-SPServiceApplicationPool -Identity $WebPoolName
if($WAAppPool -eq $null)
{
$AppPoolAccount = Get-SPManagedAccount -Identity $AppPoolUserName 
if($AppPoolAccount -eq $null)
{
$AppPoolCred = Get-Credential $AppPoolUserName
$AppPoolAccount = New-SPManagedAccount -Credential $AppPoolCred 
}
$AppPoolAccount = Get-SPManagedAccount -Identity $AppPoolUserName
if($AppPoolAccount -eq $null)
{
Write-Host “Cannot create or find the managed account $appPoolUserName, please ensure the account exists.”
Exit
}
Write-Host "Creating Service App $WebPoolName with account $AppPoolAccount"
New-SPServiceApplicationPool -Name $WebPoolName -Account $AppPoolAccount
}


## Force reload of all SharePoint modules

Remove-PSSnapin microsoft.sharepoint.powershell;
Add-PSSnapin Microsoft.SharePoint.PowerShell;

if ($xmldata.values.CreateServiceApps.'#text' -eq $true) {
## Create State Service Application
$stateName = $farmName + " State Service"
$stateDBName = $farmName + "_StateService_DB"
$stateDB = New-SPStateServiceDatabase -Name $stateDBName -DatabaseServer $DatabaseInstance
$state = New-SPStateServiceApplication -Name $stateName -Database $stateDB
New-SPStateServiceApplicationProxy -Name ”$stateName Proxy” -ServiceApplication $state –DefaultProxyGroup
## Managed Metadata Service  ##


$metadataSAName = “$farmName" + “ Managed Metadata Service”
$metaDataDBName = "$farmName" + "_Managed_MetaData_DB"
$mmsApp = New-SPMetadataServiceApplication -Name $metadataSAName –ApplicationPool $AppPoolName -DatabaseServer $DatabaseInstance -DatabaseName $metaDataDBName
New-SPMetadataServiceApplicationProxy -Name “$metadataSAName Proxy” -DefaultProxyGroup -ServiceApplication $metadataSAName
Get-SPServiceInstance | ? {$_.TypeName -eq "Managed Metadata Web Service"} | Start-SPServiceInstance

## Excel ##

$excelSAName = $farmName + " Excel Service Application"
$appexcel = New-SPExcelServiceApplication -name $excelSAName -ApplicationPool $AppPoolName -Default
Get-SPServiceInstance | ? {$_.TypeName -eq "Excel Calculation Services"} | Start-SPServiceInstance

## Word ##


$wordSAName = “$farmName" + “ Word Conversion Service Application”
$wordDBName = “$farmName" + “_Word_Conversion_DB”
Write-Host "Creating $wordSAName"
New-SPWordConversionServiceApplication –ApplicationPool $AppPoolName –DatabaseName $wordDBName –DatabaseServer $DatabaseInstance -Name $wordSAName -Default
Get-SPServiceInstance | ? {$_.TypeName -eq "Word Automation Services"} | Start-SPServiceInstance

## BDC ##

$bdcSAName = “$farmName" + “ BDC Service Application”
$bdcDBName = "$farmName" + "_BDC_DB"
Write-Host "Creating $bdcSAName"
$appBDC = New-SPBusinessDataCatalogServiceApplication –ApplicationPool $AppPoolName –DatabaseName $bdcDBName –DatabaseServer $DatabaseInstance –Name $bdcSAName
New-SPBusinessDataCatalogServiceApplicationProxy -Name $bdcSAName -ServiceApplication $appBDC
Get-SPServiceInstance | ? {$_.TypeName -eq "Business Data Connectivity Service"} | Start-SPServiceInstance

## Secure Store ##


$secureStoreSAName = “$farmName" + “ Secure Store Service Application”
$secureStoreDBName = "$farmName" + "_SecureStore_DB"
Write-Host "Creating $secureStoreSAName"
$appSS = New-SPSecureStoreServiceApplication –ApplicationPool $AppPoolName –AuditingEnabled:$false –DatabaseServer $DatabaseInstance –DatabaseName $secureStoreDBName –Name $secureStoreSAName
New-SPSecureStoreServiceApplicationProxy –Name $secureStoreSAName –ServiceApplication $appSS
Get-SPServiceInstance | ? {$_.TypeName -eq "Secure Store Service"} | Start-SPServiceInstance

## secure store - master key and app ##
    $appSSProxy = Get-SPServiceApplicationProxy | ? {$_.TypeName -eq "Secure Store Service Application Proxy"}
    Update-SPSecureStoreMasterKey -ServiceApplicationProxy $appSSProxy -Passphrase $Passphrase

    <#
    #Create ProjectServerApplication SecureStore
    $UserNameField = new-spsecurestoreapplicationfield -name "UserName" -type WindowsUserName -masked:$false
    $PasswordField = new-spsecurestoreapplicationfield -name "Password" -type WindowsPassword -masked:$true
    $fields = $UserNameField, $PasswordField
    $targetApp = new-spsecurestoretargetapplication -Name $secureStoreTAName -FriendlyName $secureStoreTAName -ContactEmail $secureStoreTAemail -ApplicationType Group
    $targetAppAdminAccount = New-SPClaimsPrincipal -Identity $adminUser -IdentityType WindowsSamAccountName
    $defaultServiceContext = Get-SPServiceContext $pwaurl
    $ownerClaims = New-SPClaimsPrincipal -EncodedClaim "c:0(.s|true"
    $ssApp = new-spsecurestoreapplication -ServiceContext $defaultServiceContext -TargetApplication $targetApp -Administrator $targetAppAdminAccount -Fields $fields -CredentialsOwnerGroup $ownerClaims
    # Convert values to secure strings
    $secureUserName = convertto-securestring $unattendedAcc.Username -asplaintext -force
    $securePassword = $unattendedAcc.Password
    $credentialValues = $secureUserName, $securePassword
    # Fill in the values for the fields in the target application
    Update-SPSecureStoreCredentialMapping -Identity $ssApp -Values $credentialValues -Principal $targetAppAdminAccount
    #>

## Performance Point ##

$perfPointSAName = “$farmName" + “ Performance Point Service Application”
$perfPointDBName = "$farmName" + "_PerformancePoint_DB"
Write-Host "Creating $perfPointSAName"

$appPerfPoint = New-SPPerformancePointServiceApplication -Name $perfPointSAName -ApplicationPool $AppPoolName -DatabaseServer $DatabaseInstance –DatabaseName $perfPointDBName
New-SPPerformancePointServiceApplicationProxy -Name $perfPointSAName -ServiceApplication $appPerfPoint -Default
Get-SPServiceInstance | ? {$_.TypeName -eq "PerformancePoint Service"} | Start-SPServiceInstance

## Visio ##
$visioSAName = “$farmName" +“ Visio Service Application”
Write-Host "Creating $visioSAName"
$appVisio = New-SPVisioServiceApplication -Name $visioSAName -ApplicationPool $AppPoolName -CreateDefaultProxy
##New-SPVisioServiceApplicationProxy -Name $visioSAName -ServiceApplication $appVisio
Get-SPServiceInstance | ? {$_.TypeName -eq "Visio Graphics Service"} | Start-SPServiceInstance

## Project Server ##
if ($xmldata.values.ProvisionProjSA.'#text' -eq $true) {
    $pwaSAName = “$farmName" +“ Project Web App Service Application”
    Write-Host "Creating $pwaSAName"
    New-SPProjectServiceApplication -name $pwaSAName -ApplicationPool $AppPoolName -Proxy
    Get-SPServiceInstance | ? {$_.TypeName -eq "Project Server Application Service"} | Start-SPServiceInstance
}
## Create Machine Translation Service ##

$MTSSAName = “$farmName" + “ Machine Translation Service”
$MTSDB = "$farmName" + "_MachineTranslation_DB”

$appMTS = New-SPTranslationServiceApplication -Name $MTSSAName -ApplicationPool $AppPoolName -DatabaseName $MTSDB
New-SPTranslationServiceApplicationProxy –Name $MTSName –ServiceApplication $appMTS –DefaultProxyGroup
Get-SPServiceInstance | ? {$_.TypeName -eq "Machine Translation Service"} | Start-SPServiceInstance

## Create User Profile Service ##

$UPSSAName = “$farmName" + “ User Profile Service”
$UPSProfileDBName = "$farmName" + "_UPS_Profile_DB"
$UPSocialDBName = "$farmName" + "_UPS_Social_DB"
$UPSSyncDBName = "$farmName" + "_UPS_Sync_DB"
Write-Host "Creating $UPSSAName"
$AppUPS = New-SPProfileServiceApplication -Name $UPSSAName -ApplicationPool $AppPoolName -ProfileDBServer $DatabaseInstance -ProfileDBName $UPSProfileDBName -SocialDBServer $DatabaseInstance -SocialDBName $UPSocialDBName -ProfileSyncDBServer $DatabaseInstance -ProfileSyncDBName $UPSSyncDBName
New-SPProfileServiceApplicationProxy -Name $UPSSAName -ServiceApplication $AppUPS -DefaultProxyGroup
Get-SPServiceInstance | ? {$_.TypeName -eq "User Profile Service"} | Start-SPServiceInstance
#>
## Start UPS SYNC ##
<#
#Start Synchronization service
Write-Host -f Cyan "Starting the User Profile Synchronization.."
$upsa = Get-SPServiceApplication | ?{$_.TypeName -like "*User Profile Serv*"}
 
$service2.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Provisioning
$service2.IsProvisioned = $false
$service2.UserProfileApplicationGuid = $upsa.Id
$service2.Update()
$upsa.SetSynchronizationMachine($hostname, $service2.Id, $farmUser, $farmPassword)
Start-SPServiceInstance $service2
 
Write-Host ""
$t = 0
$service2 = $(Get-SPServiceInstance | ? {$_.TypeName -eq "User Profile Synchronization Service" -and $_.Server -match $hostname})
 
#get the Forefront Identity Manager Synchronization service to monitor its status
$syncservice = Get-Service FIMSynchronizationService
 
while(-not ($service2.Status -eq "Online"))
{
    sleep 10;
    Write-Host "Be Patient...You have only waited $t seconds"
    $service2 = $(Get-SPServiceInstance | ? {$_.TypeName -match "User Profile Synchronization Service" -and $_.Server -match $hostname})
    $t = $t + 10
    if($service2.Status -eq "Disabled"){Write-Host -f Yellow "Sync start has failed, press the anykey to exit";read-host;exit}
}
  $t = $t - 10
  write-host ""
Write-Host -f Green "OK - Synchronization Service is Online!"
#>

## Create Subscription Settings and App Management Services ##

$SubSettingssName = “$farmName" + “ Subscription Settings Service”
$SubSettingsDatabaseName = "$farmName" + "_SubscriptionSettings_DB”
$AppManagementName = “$farmName" + “ App Management Service”
$AppManagementDatabaseName = "$farmName" + "_AppManagement_DB”

Write-Host “Creating Subscription Settings Service and Proxy”

$SubSvc = New-SPSubscriptionSettingsServiceApplication –ApplicationPool $AppPoolName –Name $SubSettingssName –DatabaseName $SubSettingsDatabaseName
$SubSvcProxy = New-SPSubscriptionSettingsServiceApplicationProxy –ServiceApplication $SubSvc
Get-SPServiceInstance | ? {$_.TypeName -eq "Microsoft SharePoint Foundation Subscription Settings Service"} | Start-SPServiceInstance
Write-Host “Creating App Management Service and Proxy…”

$AppManagement = New-SPAppManagementServiceApplication -Name $AppManagementName -DatabaseServer $DatabaseInstance -DatabaseName $AppManagementDatabaseName –ApplicationPool $AppPoolName
$AppManagementProxy = New-SPAppManagementServiceApplicationProxy -ServiceApplication $AppManagement -Name $AppManagementName
Get-SPServiceInstance | ? {$_.TypeName -eq "App Management Service"} | Start-SPServiceInstance
##Set-SPAppDomain <AppDomainName>
##Set-SPAppSiteSubscriptionName -Name “apps” -Confirm:$false

## Create Work Management Service ##
## 2013 only - not used on >2016

<#
$workManSAName = “$farmName" + “ Work Management Service Application”
$appworkMan = New-SPWorkManagementServiceApplication –Name $workManSAName –ApplicationPool $AppPoolName
New-SPWorkManagementServiceApplicationProxy -name $workManSAName -ServiceApplication $appworkMan
Get-SPServiceInstance | ? {$_.TypeName -eq "Work Management Service"} | Start-SPServiceInstance
}
#>
}

if ($xmldata.values.CreateWorkFlow.'#text' -eq $true) {
## Execure WF and SB
start-process powershell.exe -ArgumentList $xmlLocation -Credential $farmAcc -RunAs $wfsb 
}

if ($xmldata.values.ProvisionWebApp.'#text' -eq $true) {

write-host "Provision Web App"

## Create SP Web App ##

    $webappPoolAcc = Get-SPManagedAccount $appPoolAcc.UserName
    $ap = New-SPAuthenticationProvider
    $webappcert = New-SelfSignedCertificate -DnsName $rooturl.Split('//')[-1]
    New-SPWebApplication -Name $spWAName -port $porturl -SecureSocketsLayer -URL $rooturl -ApplicationPool $WebPoolName -ApplicationPoolAccount $webappPoolAcc -AuthenticationProvider $ap -DatabaseServer $DatabaseInstance -DatabaseName $wsscontentDBname -UseServerNameIndication -HostHeader $rooturl.Split('//')[-1]
}
if ($xmldata.values.ProvisionSites.'#text' -eq $true) {
write-host "Provision Site Collections"
## Check for Site Collection and create/provision if needed ##
$webroot = Get-SPWeb $rooturl
if ($webroot -eq $null) {
    new-spsite -Url $rooturl -Language 1033 -Template "STS#0" -OwnerAlias $adminUser
    }

## Content Hub
write-host "Provision Content Hub $churl"

$webchurl = Get-SPWeb $churl
if ($webchurl -eq $null) {
    new-spsite -Url $churl -Language 1033 -Template "STS#0" -OwnerAlias $adminUser
    }
#Enable Content Hub Feature and set content Hub in Managed Metadata Services
Enable-SpFeature -Identity 9a447926-5937-44cb-857a-d3829301c73b -Url $churl
$appMM = Get-SPServiceApplication | ? {$_.TypeName -eq "Managed Metadata Service"}
Set-SPMetadataServiceApplication -Identity $appMM -HubURI $churl 
}
if ($xmldata.values.ProvisionPWA.'#text' -eq $true) {
write-host "Provision Project Web App"
## Create Project PWA Site ##
    # This will error out if the Project PWA DB doesn't exist and go an create a new DB
    $pwadbmount = Mount-SPProjectDatabase $PWADBname -ServiceApplication $pwaSAName

    if($pwdbamount -eq $null)
    {
    New-SPProjectDatabase $PWADBname -ServiceApplication $pwaSAName -Tag "ProjectWebApp1DB"
    }

    #this will error out if the /pwa site collection doesn't exist in the content DB
    $pwainsmount = Mount-SPProjectWebInstance -SiteCollection $pwaurl -DatabaseName $PWADBname
    if($pwainsmount -eq $null)
    {
    #This is only needed if doing /pwa thing and not /sites/pwa
    #New-SPManagedPath "pwa" -WebApplication $rooturl -Explicit
    new-spsite -Url $pwaurl -Language 1033 -OwnerAlias $adminUser
    $web=Get-SPWeb $pwaurl
    $web.Properties["PWA_TAG"]="ProjectWebApp1DB"
    $web.Properties.Update()
    Enable-SPFeature pwasite -URL $pwaurl
    Set-SPweb -Identity $web -Template pwa#0
    sleep 3
    Upgrade-SPProjectWebInstance -Identity $pwaurl -Confirm:$False
    Set-SPProjectPermissionMode -Url $pwaurl -Mode ProjectServer -AdministratorAccount $adminUser


    }
}

##register Workflow ##
if ($xmldata.values.RegisterWF.'#text' -eq $true) {
    Register-SPWorkflowService –SPSite $pwaurl –WorkflowHostUri $workflowhost -AllowOAuthHttp -Force -ScopeName “SharePoint"
}

##Disable Loopback check (Registry)
if ($xmldata.values.disableloopback.'#text' -eq $true) {
    write-host "Disabling loopback Check...(Registry LSA)"
    New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name "DisableLoopbackCheck" -value "1" -PropertyType dword
    }