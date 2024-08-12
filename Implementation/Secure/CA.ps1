$cahost = "a.b.c.d"
$centralAdminPort = "1234"
$fullurl = "https://"+$cahost+":"+$centralAdminPort
New-SPCentralAdministration -Port $centralAdminPort -WindowsAuthProvider "NTLM" -SecureSocketsLayer
-Ur $fullurl -HostHeader $cahost