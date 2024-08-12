Add-Type -AssemblyName 'System.Web'
import-module activedirectory
$domain = 'domain'
function genpass {
    $minLength = 14
    $maxLength = 16
    $length = Get-Random -Minimum $minLength -Maximum $maxLength
    $nonAlphaChars = 5
    $password = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
   return $password
}


$Users = Import-Csv -Delimiter "," -Path "J:\Scripts\in\SACcin.csv"
$OutputFileLocation = "j:\Scripts\Out\NewPass-"+(Get-Date -Format "yyyy-MM-dd-HHmm")+".csv"

     
foreach ($user in $Users)
{
     
    $userName = $user.user
    $oldPassword = $user.oldpass
    $newPassword = genpass

    Write-host "Changing $userName"

    $SoldPassword = ConvertTo-SecureString -AsPlainText -Force -String $oldPassword
    $SnewPassword = ConvertTo-SecureString -AsPlainText -Force -String $newPassword
    $Credential = New-Object System.Management.Automation.PSCredential ("$domain\$userName", $SoldPassword)
    Set-ADAccountPassword -Credential $Credential -Server $domain -Identity $userName -OldPassword $SoldPassword -NewPassword $SnewPassword
    
    $psObject = New-Object psobject
    Add-Member -InputObject $psObject -MemberType NoteProperty -Name "Username" -Value $userName
    Add-Member -InputObject $psObject -MemberType NoteProperty -Name "Password" -Value $newPassword
    $psObject| Export-Csv $OutputFileLocation -Append -NoTypeInformation
}
