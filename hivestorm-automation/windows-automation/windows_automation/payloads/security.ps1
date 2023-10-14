# enable windows defender
# enable firewall
# enable auditing logs and such
# turn off remote registry

# Enable windows defender
# disable smbv1
# check services, purge bad services

$rules = @(
    @{
        DisplayName = "Block Samba v1"
        Direction = "Inbound"
        LocalPort = "137-139"
        Action = "Block"
        Protocol = "TCP"
    },
    @{
        DisplayName = "Block Samba v2"
        Direction = "Inbound"
        LocalPort = "445"
        Action = "Block"
        Protocol = "TCP"
    },
    @{
        DisplayName = "Block Telnet"
        Direction = "Inbound"
        LocalPort = "23"
        Action = "Block"
        Protocol = "TCP"
    },
    @{
        DisplayName = "KidNamedFinger (block finger)"
        Direction = "Inbound"
        LocalPort = "79"
        Action = "Block"
        Protocol = "TCP"
    }
    @{
        DisplayName = "Block RDP"
        Direction = "Inbound"
        LocalPort = "3389"
        Action = "Block"
        Protocol = "TCP"
    }
)

$registryKeys = @(
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        Name = "EnableSmartScreen"
        PropertyType = "DWord"
        Value = 1
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        Name = "ShellSmartScreenLevel"
        PropertyType = "String"
        Value = "Block"
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
        Name = "fDenyTSConnections" # disable rdp
        PropertyType = "Dword"
        Value = 1
    }
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        Name = "AUOptions" # enable auto update
        PropertyType = "Dword"
        Value = 2
    },
    @{
        Path = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319'
        Name = "SchUseStrongCrypto" # use strong crypto on 64 bit net framework
        PropertyType = "Dword"
        Value = 1
    },
    @{
        Path = 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' 
        Name = 'SchUseStrongCrypto' # strong crypto for 32 bit system
        PropertyType = "Dword"
        Value = 1
    }
    # [Net.ServicePointManager]::SecurityProtocol to see protocols used
)


# enable virus scanning
Set-MpPreference -DisableRealtimeMonitoring $false

# enable and configure firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
foreach($rule in $rules)
{
    New-NetFirewallRule @rule
}

# Registry configs
foreach($registry in $registryKeys)
{
    $name = $registry["Name"]
    try {
        New-ItemProperty @registry -ErrorAction Stop
    }
    catch [System.IO.IOException]
    {
        Write-Host "[+] Registry entry already complete for $name"
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        Write-Host "[!] Registry path not found for $name"
    }
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # use strong encryption