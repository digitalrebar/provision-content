$FormatEnumerationLimit = -1

function Write-Title($title) {
    Write-Output "`n#`n# $title`n#"
}

function Get-DotNetVersion {
    # see https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#net_d
    $release = [int](Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release).Release
    if ($release -ge 528040) {
        return '4.8 or later'
    }
    if ($release -ge 461808) {
        return '4.7.2'
    }
    if ($release -ge 461308) {
        return '4.7.1'
    }
    if ($release -ge 460798) {
        return '4.7'
    }
    if ($release -ge 394802) {
        return '4.6.2'
    }
    if ($release -ge 394254) {
        return '4.6.1'
    }
    if ($release -ge 393295) {
        return '4.6'
    }
    if ($release -ge 379893) {
        return '4.5.2'
    }
    if ($release -ge 378675) {
        return '4.5.1'
    }
    if ($release -ge 378389) {
        return '4.5'
    }
    return 'No 4.5 or later version detected'
}

Write-title 'Firmware'
Get-ComputerInfo `
    -Property `
        BiosFirmwareType,
        BiosManufacturer,
        BiosVersion `
    | Format-List

Write-Title 'Device Drivers'
driverquery.exe /fo csv /v `
    | ConvertFrom-Csv `
    | Where-Object {$_.State -ne 'Stopped'} `
    | Select-Object -Property 'Module Name','Path','Display Name' `
    | Sort-Object -Property 'Module Name'

Write-Title 'Operating System version (from Get-ComputerInfo)'
Get-ComputerInfo `
    -Property `
        WindowsProductName,
        WindowsInstallationType,
        OsVersion,
        BuildVersion,
        WindowsBuildLabEx `
    | Format-List

Write-Title 'Operating System version (from registry)'
$currentVersionKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
Write-Output "$($currentVersionKey.CurrentMajorVersionNumber).$($currentVersionKey.CurrentMinorVersionNumber).$($currentVersionKey.CurrentBuildNumber).$($currentVersionKey.UBR)"

Write-Title '.NET Framework version'
Get-DotNetVersion

Write-Title 'PowerShell version'
$PSVersionTable.GetEnumerator() `
    | Sort-Object Name `
    | Format-Table -AutoSize `
    | Out-String -Stream -Width ([int]::MaxValue) `
    | ForEach-Object {$_.TrimEnd()}

Write-Title 'Network Interfaces'
Get-NetAdapter `
    | ForEach-Object {
        New-Object PSObject -Property @{
            Name = $_.Name
            Description = $_.InterfaceDescription
            MacAddress = $_.MacAddress
            IpAddress = ($_ | Get-NetIPConfiguration | ForEach-Object { $_.IPv4Address.IPAddress })
        }
    } `
    | Sort-Object -Property Name `
    | Format-Table Name,Description,MacAddress,IpAddress `
    | Out-String -Stream -Width ([int]::MaxValue) `
    | ForEach-Object {$_.TrimEnd()}

Write-Title 'Environment Variables'
dir env: `
    | Sort-Object -Property Name `
    | Format-Table -AutoSize `
    | Out-String -Stream -Width ([int]::MaxValue) `
    | ForEach-Object {$_.TrimEnd()}

Write-Title 'Installed Windows Features'
if (Get-Command -ErrorAction SilentlyContinue Get-WindowsFeature) {
    # for Windows Server.
    Get-WindowsFeature `
        | Where Installed `
        | Format-Table -AutoSize `
        | Out-String -Stream -Width ([int]::MaxValue) `
        | ForEach-Object {$_.TrimEnd()}
} else {
    # for Windows Client.
    Get-WindowsOptionalFeature -Online `
        | Where-Object {$_.State -eq 'Enabled'} `
        | Sort-Object -Property FeatureName `
        | Format-Table -AutoSize `
        | Out-String -Stream -Width ([int]::MaxValue) `
        | ForEach-Object {$_.TrimEnd()}
}

# see https://gist.github.com/IISResetMe/36ef331484a770e23a81
function Get-MachineSID {
    param(
        [switch]$DomainSID
    )

    # Retrieve the Win32_ComputerSystem class and determine if machine is a Domain Controller
    $WmiComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $IsDomainController = $WmiComputerSystem.DomainRole -ge 4

    if ($IsDomainController -or $DomainSID) {
        # We grab the Domain SID from the DomainDNS object (root object in the default NC)
        $Domain    = $WmiComputerSystem.Domain
        $SIDBytes = ([ADSI]"LDAP://$Domain").objectSid | %{$_}
        New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ([Byte[]]$SIDBytes),0
    } else {
        # Going for the local SID by finding a local account and removing its Relative ID (RID)
        $LocalAccountSID = Get-WmiObject -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" | Select-Object -First 1 -ExpandProperty SID
        $MachineSID      = ($p = $LocalAccountSID -split "-")[0..($p.Length-2)]-join"-"
        New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $MachineSID
    }
}
Write-Title 'Windows SID'
Write-Output "$(Get-MachineSID)"

Write-Title 'Windows License'
cscript -nologo c:/windows/system32/slmgr.vbs -dlv

Write-Title 'Windows Product-Key'
# NB this C# code came from
#       https://github.com/mrpeardotnet/WinProdKeyFinder/blob/d05bd525214d571a24298830cccaa466b22f3c87/WinProdKeyFind/KeyDecoder.cs
#    and was slightly modified to work only in Windows8+/PowerShell.
Add-Type @'
using System;
using Microsoft.Win32;

namespace WinProdKeyFind
{
    public static class KeyDecoder
    {
        public static string GetWindowsProductKeyFromRegistry()
        {
            var localKey =
                RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, Environment.Is64BitOperatingSystem
                    ? RegistryView.Registry64
                    : RegistryView.Registry32);
            var registryKeyValue = localKey.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue("DigitalProductId");
            if (registryKeyValue == null)
                return "Failed to get DigitalProductId from registry";
            var digitalProductId = (byte[])registryKeyValue;
            localKey.Close();
            return DecodeProductKeyWin8AndUp(digitalProductId);
        }

        /// <summary>
        /// Decodes Windows Product Key from the DigitalProductId.
        /// This method applies to DigitalProductId from Windows 8 or newer versions of Windows.
        /// </summary>
        /// <param name="digitalProductId">DigitalProductId to decode</param>
        /// <returns>Decoded Windows Product Key as a string</returns>
        public static string DecodeProductKeyWin8AndUp(byte[] digitalProductId)
        {
            var key = String.Empty;
            const int keyOffset = 52;
            var isWin8 = (byte)((digitalProductId[66] / 6) & 1);
            digitalProductId[66] = (byte)((digitalProductId[66] & 0xf7) | (isWin8 & 2) * 4);

            const string digits = "BCDFGHJKMPQRTVWXY2346789";
            var last = 0;
            for (var i = 24; i >= 0; i--)
            {
                var current = 0;
                for (var j = 14; j >= 0; j--)
                {
                    current = current*256;
                    current = digitalProductId[j + keyOffset] + current;
                    digitalProductId[j + keyOffset] = (byte)(current/24);
                    current = current%24;
                    last = current;
                }
                key = digits[current] + key;
            }

            var keypart1 = key.Substring(1, last);
            var keypart2 = key.Substring(last + 1, key.Length - (last + 1));
            key = keypart1 + "N" + keypart2;

            for (var i = 5; i < key.Length; i += 6)
            {
                key = key.Insert(i, "-");
            }

            return key;
        }
    }
}
'@
function Get-WindowsProductKey {
    [WinProdKeyFind.KeyDecoder]::GetWindowsProductKeyFromRegistry()
}
Get-WindowsProductKey

Write-Title 'Installed Windows Updates'
function Get-InstalledWindowsUpdates {
    $session = New-Object -ComObject 'Microsoft.Update.Session'
    $searcher = $session.CreateUpdateSearcher()
    $totalHistoryCount = $searcher.GetTotalHistoryCount()
    if ($totalHistoryCount -eq 0) {
        # on recent windows updates (e.g. 2019-09) after we optimize the SxS,
        # the searcher no longer returns any results, despite the cummulative
        # updates being installed.
        return
    }
    $session.QueryHistory($null, 0, $totalHistoryCount) | Where-Object {$_.ResultCode} | ForEach-Object {
        New-Object PSObject -Property @{
            Date = $_.Date
            Title = $_.Title
            Status = switch ($_.ResultCode) {
                0 {"NotStarted"}
                1 {"InProgress"}
                2 {"Succeeded"}
                3 {"SucceededWithErrors"}
                4 {"Failed"}
                5 {"Aborted"}
                default {"Unknown #$($_.ResultCode)"}
            }
            Product = $_.Categories | Where-Object {$_.Type -eq 'Product'} | Select-Object -First 1 -ExpandProperty Name
        }
    }
}
Get-InstalledWindowsUpdates

Write-Title 'Partitions'
Get-Partition `
    | Format-Table -AutoSize `
    | Out-String -Stream -Width ([int]::MaxValue) `
    | ForEach-Object {$_.TrimEnd()}

Write-Title 'Volumes'
Get-Volume `
    | Format-Table -AutoSize `
    | Out-String -Stream -Width ([int]::MaxValue) `
    | ForEach-Object {$_.TrimEnd()}
