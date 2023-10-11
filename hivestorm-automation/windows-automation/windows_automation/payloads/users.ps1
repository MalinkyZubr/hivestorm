# remove unauthorized users
# change user permissions that need to be changed
# configure group policies
param (
    [Hashtable]$usersAndPermissions
)

$accounts = Get-WmiObject -Class Win32_UserAccount
$accountNames = Get-WmiObject -Class Win32_UserAccount | Select-Object -ExpandProperty name
$admins = Get-LocalGroupMember -Name Administrators | Select-Object -ExpandProperty name
$users = Get-LocalGroupMember -Name Users | Select-Object -ExpandProperty name

# check for accounts in the users list that shouldnt be there
echo "[+] Checking for unauthorized users"
foreach ($user in $accounts) {
    $name = $user.Name
    if($usersAndPermissions.ContainsKey($name)){
        continue
    }
    echo "[!] Removing the user $name"
    Remove-LocalUser -Name $name
}

# check for and remove users not authorized to have admin priveleges
echo "[+] Checking unauthorized admins"
foreach ($admin in $admins) {
    $adminName = $admin -match '(?<=\\).*'
    if(!$adminName -eq 'Administrator' -and !$usersAndPermissions[$adminName] -eq 'admin')
    {
        echo "[!] Removinig the user $adminName from admins"
        NET LOCALGROUP Users $adminName /ADD
        NET LOCALGROUP Administrators $adminName /DELETE
    }
}

# check for users that should have admin priveleges and add them to admin group
echo "[+] Checking for users that should have admin priveleges"
foreach ($user in $users) {
    $userName = $user -match '(?<=\\).*'
    if($usersAndPermissions[$userName] -eq "admin")
    {
        echo "[!] adding $userName to admins"
        NET LOCALGROUP Administrators $adminName /ADD
        NET LOCALGROUP Users $adminName /DELETE
    }
}

# check for users that dont exist, and create them
echo "[+] Creating required users"
foreach ($user in $usersAndPermissions.GetEnumerator())
{
    if(!$accountNames -contains $user)
    {
        echo "[!] User $user does not exist! Please create a password for $user"
        while(1)
        {
            $password = Read-Host -AsSecureString -Prompt "Password"
            $confirmation = Read-Host -AsSecureString -Prompt "Confirm Password"
            if($password -eq $confirmation)
            {
                $confirmation = ""
                try 
                {
                    echo "[+] User $user successfully created"
                    New-LocalUser -Name $user -Description "added courtesy of Zubr" -Password $password
                    $password = ""
                }
                catch [InvalidPasswordException]
                {
                    echo "[!] The password does not meet complexity requirements. Try again"
                    continue
                }
                break
            }
            echo "[!] Passwords do not match!"
        }
    }
}