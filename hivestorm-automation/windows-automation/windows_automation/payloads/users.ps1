# remove unauthorized users
# change user permissions that need to be changed
# create strong password policy
# find non-compliant passwords and change them
# create necessary users
# configure group policies
param (
    [Hashtable]$authorized_users
)

$passwordLength = 8
$maxAge = 30
$minAge = 1
$uniquePw = 30

$accounts = Get-WmiObject -Class Win32_UserAccount
$accountNames = Get-WmiObject -Class Win32_UserAccount | Select-Object -ExpandProperty name
$admins = Get-LocalGroupMember -Name Administrators | Select-Object -ExpandProperty name
$users = Get-LocalGroupMember -Name Users | Select-Object -ExpandProperty name

# check for accounts in the users list that shouldnt be there
Write-Output "[+] Checking for unauthorized users"
foreach ($user in $accounts) {
    $name = $user.Name
    if($authorized_users.ContainsKey($name)){
        continue
    }
    Write-Output "[!] Removing the user $name"
    Remove-LocalUser -Name $name
}

# check for and remove users not authorized to have admin priveleges
Write-Output "[+] Checking unauthorized admins"
foreach ($admin in $admins) {
    $adminName = $admin -match '(?<=\\).*'
    if(!$adminName -eq 'Administrator' -and !$authorized_users[$adminName]['permission'] -eq 'admin')
    {
        Write-Output "[!] Removinig the user $adminName from admins"
        NET LOCALGROUP Users $adminName /ADD
        NET LOCALGROUP Administrators $adminName /DELETE
    }
}

# check for users that should have admin priveleges and add them to admin group
Write-Output "[+] Checking for users that should have admin priveleges"
foreach ($user in $users) {
    $userName = $user -match '(?<=\\).*'
    if($authorized_users[$userName]['permission'] -eq "admin")
    {
        Write-Output "[!] adding $userName to admins"
        NET LOCALGROUP Administrators $adminName /ADD
        NET LOCALGROUP Users $adminName /DELETE
    }
}

# Set password policies
NET ACCOUNTS /minpwlen:$passwordLength
NET ACCOUNTS /MAXPWAGE:$maxAge
NET ACCOUNTS /MINPWAGE:$minAge
NET ACCOUNTS /UNIQUEPW:$uniquePw

# check for users that dont exist, and create them
# check for non-compliant passwords
Write-Output "[+] Creating required users"
foreach ($user in $authorized_users.GetEnumerator())
{
    if(!$accountNames -contains $user -or $authorized_users[$user]['password'].Length -lt $passwordLength)
    {
        Write-Output "[!] User $user needs a password!"
        while(1)
        {
            $password = Read-Host -AsSecureString -Prompt "Password"
            $confirmation = Read-Host -AsSecureString -Prompt "Confirm Password"
            if($password -eq $confirmation)
            {
                $confirmation = ""
                try 
                {
                    if(!$accountNames -contains $user){
                        New-LocalUser -Name $user -Description "added courtesy of Zubr" -Password $password
                        Write-Output "[+] User $user successfully created"
                    }
                    elseif($authorized_users[$user]['password'].Length -lt $passwordLength){
                        Set-LocalUser -Name $user -Password $password -PasswordNeverExpires $false
                        Write-Output "[+] User $user password updated to meet standards successfully"
                    }
                    $password = ""
                }
                catch
                {
                    Write-Output "[!] The password does not meet complexity requirements. Try again"
                    continue
                }
                break
            }
            Write-Output "[!] Passwords do not match!"
        }
    }
}