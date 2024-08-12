#Section 1
# Start Loading SharePoint Snap-in
$snapin = (Get-PSSnapin -name Microsoft.SharePoint.PowerShell -EA SilentlyContinue)
IF ($snapin -ne $null){
write-host -f Green "SharePoint Snap-in is loaded... No Action taken"}
ELSE  {
write-host -f Yellow "SharePoint Snap-in not found... Loading now"
Add-PSSnapin Microsoft.SharePoint.PowerShell
write-host -f Green "SharePoint Snap-in is now loaded"}
# END Loading SharePoint Snapin
 #A and B is Crawl and Index, C and D is query
$hostA = Get-SPEnterpriseSearchServiceInstance -Identity "sp01"
#$hostB = Get-SPEnterpriseSearchServiceInstance -Identity "sp02"
$hostC = Get-SPEnterpriseSearchServiceInstance -Identity "sp03"
#$hostD = Get-SPEnterpriseSearchServiceInstance -Identity "sp04"

$farmname = (Get-SpFarm).Name.replace('_SharePoint_Config','')
$searchName = $farmname + " Search Service App"
$searchDB = $farmname +"_SearchServiceDB"
$searchAcct = "domain\SPPRDAPP"

$searchManagedAcct = Get-SPManagedAccount | Where {$_.UserName-eq $searchAcct}
$searchAppPoolName = "SharePoint Search App Pool Service"
IF((Get-spserviceapplicationPool | Where {$_.name -eq $searchAppPoolName}).name -ne $searchAppPoolName){
$searchAppPool = New-SPServiceApplicationPool -Name $searchAppPoolName -Account $searchManagedAcct} 
