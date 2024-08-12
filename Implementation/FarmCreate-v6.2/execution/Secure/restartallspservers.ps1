$servers = Get-SPServer | ? { $_.Role -ne “Invalid” }
foreach ($server in $servers)
{
$servername = $server.Address
write-host "restart on server $servername"
shutdown /m $servername /f /r /t 20
}