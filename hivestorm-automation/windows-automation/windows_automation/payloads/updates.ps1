# update windows
# update all programs installed

param (
    [Array]$chocolateyUpgrades
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # use strong encryption
Set-ExecutionPolicy -ExecutionPolicy "RemoteSigned" -Force
Install-PackageProvider -Name NuGet -Force
Install-Module PSWindowsUpdate -Force

# install chocolatey
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    foreach($update in $chocolateyUpgrades)
    {
        Invoke-Expression "choco upgrade $update -y"
    }
}
catch [System.Management.Automation.RuntimeException] {
    Write-Host "[!] Must install NET Framework, rebooting now"
    Restart-Computer -Force
}

Set-ExecutionPolicy -ExecutionPolicy "Restricted" -Force

# restart and update
Get-WindowsUpdate -AcceptAll -Install -AutoReboot