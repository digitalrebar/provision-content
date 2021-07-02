# -*- powershell -*-
# To run this script:
# powershell -executionpolicy bypass -file winpe-iso.ps1
#
#
param(
    [Cmdletbinding(PositionalBinding = $false)]
)

function test-administrator {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function get-currentdirectory {
    $thisName = $MyInvocation.MyCommand.Name
    [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}

if (-not (test-administrator)) {
    write-error @"
You must be running as administrator for this script to function.
Unfortunately, we can't reasonable elevate privileges ourselves
so you need to launch an administrator mode command shell and then
re-run this script yourself.  
"@
    exit 1
}

$destisoname = 'winpe.iso'

# Check to see that the Windows 8.1 ADK is installed.
# This may need porting to whatever the current version of ADK is.
write-host "Looking for the Windows 8.1 ADK"
$adk = @([Environment]::GetFolderPath('ProgramFilesX86'),
         [Environment]::GetFolderPath('ProgramFiles')) |
           % { join-path $_ 'Windows Kits\8.1\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64' } |
           ? { test-path  $_ } |
           select-object -First 1
if(!$adk) {
    write-error "No ADK found in default location."
    write-error "Please download and install the Windows ADK for Windows 8.1 from:"
    write-error "  https://www.microsoft.com/en-us/download/details.aspx?id=39982"
    exit 1
} else {
    write-host "Found ADK for Windows 8.1 in the default install location."
}

# Set some basic location information 
$cwd    = get-currentdirectory
$output = join-path $cwd "winpe"
$mount  = join-path $cwd "winpe-mount"

# Path to the clean WinPE WIM file.
$wim = join-path $adk "en-us\winpe.wim"

# Root for the CAB files for optional features.
$packages = join-path $adk "WinPE_OCs"

write-host "Make sure our working and output directories exist."

if (test-path -path $mount) {
    Dismount-WindowsImage -path $mount -discard
    Remove-Item $mount -Recurse -Force
}
new-item -type directory $mount

if (test-path -path $output) {
    Remove-Item $output -Recurse -Force
}
new-item -type directory $output

#Copy the clean ADK WinPE image into our output area.
copy-item $wim $output
# Update our wim location...
$wim = join-path $output "winpe.wim"

# Start hacking up the WinPE image
import-module dism
write-host "Mounting the winpe.wim image."
mount-windowsimage -imagepath $wim -index 1 -path $mount -erroraction stop

write-host "Adding powershell and dependencies to winpe.wim"
# This order is documented in http://technet.microsoft.com/library/hh824926.aspx
@('WinPE-WMI',
  'WinPE-NetFX',
  'WinPE-Scripting',
  'WinPE-PowerShell',
  'WinPE-StorageWMI',
  'WinPE-DismCmdlets') | foreach {
    $item = $_
    write-host "installing $item to image"
    $pkg = join-path $packages "$item.cab"
    add-windowspackage -packagepath $pkg -path $mount
    $pkg = join-path $packages "en-us\${item}_en-us.cab"
    add-windowspackage -packagepath $pkg -path $mount
}
# Copy bootmgr.exe to root of winpe.wim, this is fix for ADK 8.1 & iPXE
# not supporting compression
$bootmgrsource = Join-Path $mount "Windows\Boot\PXE\bootmgr.exe"
if(Test-path $bootmgrsource) {
    Copy-Item $bootmgrsource $mount
    Write-Host "Copying bootmgr.exe to output"
    Copy-Item $bootmgrsource $output
} else {
    Write-error "Bootmgr.exe was not successfully copied."
    Write-error "If using windows 2012 R2, deployment will not succeed."
}

write-host "Adding Drivers to the image"
$drivers  = join-path $cwd "Drivers"
Add-WindowsDriver -Path $mount -Driver "$drivers" -Recurse
Copy-Item $drivers $mount

write-host "Writing Windows\System32\startnet.cmd script to winpe.wim"
$file = join-path $mount "Windows\System32\startnet.cmd"
set-content $file @'
@echo off
echo starting wpeinit to detect and boot network hardware
wpeinit
echo starting the rebar client
powershell -executionpolicy bypass -noninteractive -file %SYSTEMDRIVE%\Windows\System32\stage0.ps1
echo dropping to a command shell now...
'@

write-host "Unmounting and saving the Winpe.wim image"
dismount-windowsimage -save -path $mount -erroraction stop -loglevel WarningsInfo -logpath (Join-Path $cwd "winpe.log")
if (! $?) { exit 1 }

# Paranoia is the better part of virtue here.
Clear-WindowsCorruptMountPoint

$targetdirectory = Join-Path $cwd "\workingisofiles"
if (test-path $targetdirectory) {
    Remove-Item $targetdirectory -Recurse -Force
}

#Copy our updated boot.wim, install.wim, winpe.wim, and bootmgr.exe to image
$originalpe = $output + "\winpe.wim"
$bootmgrdir = $output + "\bootmgr.exe"
Copy-Item $originalpe $targetdirectory
Copy-Item $bootmgrdir $targetdirectory
write-host "Downloading current copy of wimboot"
Invoke-WebRequest -Uri 'https://github.com/ipxe/wimboot/releases/latest/download/wimboot' -Outfile "${targetdirectory}\wimboot"

#Build a new .iso
$destisodirectory = $cwd + '\' + $destisoname
$oscdimgloc = 'C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\oscdimg\oscdimg.exe'
$arg1 = '-m'
$arg2 = '-h'
$arg3 = '-o'
$arg4 = '-u2'
$arg5 = '-udfver102'
$arg6 = '-l<Windows>'
Write-Host "*************************"
Write-Host "Calling OSCDCMD: " + $oscdimgloc
& $oscdimgloc $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $targetdirectory $destisodirectory

#Cleanup unneeded files
Write-Host 'Deleting files no longer needed.'
Remove-Item $output -recurse -force
Remove-Item $mount -recurse -force
Remove-Item $targetdirectory -Recurse -Force
