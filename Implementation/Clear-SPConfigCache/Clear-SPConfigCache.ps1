Add-PSSnapin -Name Microsoft.SharePoint.PowerShell –erroraction SilentlyContinue
write-host "CLEAR CONFIG CACHE ON FARM"
$servers = Get-SPServer | ? { $_.Role -ne “Invalid” }
foreach ($server in $servers)
{
$servername = $server.Address
write-host "Stop Timer Service on server $servername"
(Get-WmiObject Win32_Service -filter "name='SPTimerV4'" -ComputerName $servername).stopservice() | Out-Null
}

foreach ($server in $servers)
{
$servername = $server.Address
$folders = Get-ChildItem ("\\" + $servername + "\C$\ProgramData\Microsoft\SharePoint\Config")

foreach ($folder in $folders)
{
$items = Get-ChildItem $folder.FullName -Recurse
foreach ($item in $items)
{
if ($item.Name.ToLower() -eq “cache.ini”)
{
$cachefolder = $folder.FullName
}

}
}

write-host "Found CacheFolder on Server $servername = $cachefolder"
$cachefolderitems = Get-ChildItem $cachefolder -Recurse

write-host "Delete all XMQL Files inside this CacheFolder"
foreach ($cachefolderitem in $cachefolderitems)
{
if ($cachefolderitem -like “*.xml”)
{

$cachefolderitem.Delete()
}

}

$a = Get-Content $cachefolder\cache.ini
$a = 1
write-host "Creating a new Cache.ini File on server $servername"
Set-Content $a -Path $cachefolder\cache.ini

}

foreach ($server in $servers)
{
$servername = $server.Address
write-host "START Timer Service on server $servername"
(Get-WmiObject Win32_Service -filter "name='SPTimerV4'" -ComputerName $servername).startservice() | Out-Null
}
