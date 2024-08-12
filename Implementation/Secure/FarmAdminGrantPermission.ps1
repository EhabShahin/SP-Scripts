$user="discovery\khaya12admin"
Add-SPShellAdmin -UserName $user
$site = (Get-SPWebapplication -IncludeCentralAdministration | ?{$_.IsAdministrationWebApplication}).Sites[0]
$Web = Get-SPweb($site.url)
$FarmAdminGroup = $Web.SiteGroups["Farm Administrators"]
$FarmAdminGroup.users
$FarmAdminGroup.AddUser($user, "", $user, "")
$FarmAdminGroup.Update()
write-host "Done Farm Admin - Start Web Apps"
$wa=Get-SPWebApplication
foreach($w in $wa) {
$w.url
if ($w.url -eq 'https://my.discovery.co.za/') {} else {
write-host "processing $w.url"
$w.GrantAccessToProcessIdentity($user)
#$w.Update()
}
write-host "done"
}
$wa.update()