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


## check if we joining to a farm
if ($xmldata.values.JoinFarm.'#text' -eq $true) {
Write-Host "Force upgrade.."
psconfig -cmd upgrade -inplace b2b -wait -force
Write-host "Joining of exsiting farm"
Connect-SPConfigurationDatabase -DatabaseServer $DatabaseInstance -DatabaseName (“$farmName" + "_SharePoint_Config”) -Passphrase $Passphrase -LocalServerRole $Localserverrole
#New-SPConfigurationDatabase -DatabaseServer $DatabaseInstance -DatabaseName (“$farmName" + "_SharePoint_Config”) -AdministrationContentDatabaseName ("$farmName" + "_SharePoint_AdminContent”) -Passphrase $Passphrase -FarmCredentials $farmAcc -localserverrole $Localserverrole
$farm = Get-SPFarm
if (!$farm -or $farm.Status -ne "Online") {
    Write-Output "Farm was not created or is not running"
    exit
}
}