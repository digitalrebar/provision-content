Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Host
    Write-Host "ERROR: $_"
    Write-Host (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Host (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Write-Host
    Write-Host 'Sleeping for 60m to give you time to look around the virtual machine before self-destruction...'
    Start-Sleep -Seconds (60*60)
    Exit 1
}

## for troubleshoot purposes, save the current user details. this will be later displayed by provision.ps1.
#whoami /all >C:\whoami-autounattend.txt

if (![Environment]::Is64BitProcess) {
    throw 'this must run in a 64-bit PowerShell session'
}

if (!(New-Object System.Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'this must run with Administrator privileges (e.g. in a elevated shell session)'
}

# move all (non-domain) network interfaces into the private profile to make winrm happy (it needs at
# least one private interface; for vagrant its enough to configure the first network interface).
Get-NetConnectionProfile `
    | Where-Object {$_.NetworkCategory -ne 'DomainAuthenticated'} `
    | Set-NetConnectionProfile -NetworkCategory Private

# configure WinRM.
Write-Output 'Configuring WinRM...'
winrm quickconfig -quiet
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
# make sure the WinRM service startup type is delayed-auto
# even when the default config is auto (e.g. Windows 2019
# changed that default).
# WARN do not be tempted to change the default WinRM service startup type from
#      delayed-auto to auto, as the later proved to be unreliable.
$result = sc.exe config WinRM start= delayed-auto
if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
    throw "sc.exe config failed with $result"
}

## dump the WinRM configuration.
#winrm enumerate winrm/config/listener
#winrm get winrm/config
#winrm id

# disable UAC remote restrictions.
# see https://support.microsoft.com/en-us/help/951016/description-of-user-account-control-and-remote-restrictions-in-windows
# see https://docs.microsoft.com/en-us/windows/desktop/wmisdk/user-account-control-and-wmi#handling-remote-connections-under-uac
New-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
    -Name LocalAccountTokenFilterPolicy `
    -Value 1 `
    -Force

# make sure winrm can be accessed from any network profile.
$winRmFirewallRuleNames = @(
    'WINRM-HTTP-In-TCP',        # Windows Remote Management (HTTP-In)
    'WINRM-HTTP-In-TCP-PUBLIC'  # Windows Remote Management (HTTP-In)   # Windows Server
    'WINRM-HTTP-In-TCP-NoScope' # Windows Remote Management (HTTP-In)   # Windows 10
)
Get-NetFirewallRule -Direction Inbound -Enabled False `
    | Where-Object {$winRmFirewallRuleNames -contains $_.Name} `
    | Set-NetFirewallRule -Enable True
