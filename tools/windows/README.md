# Windows PE Boot Image#

This directory contains the script needed to build a Windows PE
ISO image that can be booted sued for management tasks that require
a Windows environment.

## Prerequisites Required to Create Image ##

* A Windows 7, 8, or 10 system to act as a technician workstation.
* The technician workstation must have the Windows 8.1 AIK installed
  to the default location.  You can download the AIK from:
  https://www.microsoft.com/en-us/download/details.aspx?id=39982
* Any drivers needed to enable WinPE to function on target systems.

## Creating a Rebar-compatible Windows PE boot image ##
All these steps should take place on the technician workstation, and
assume that the user is logged in to the Administrator account.  They
also assume that you are working from
`C:\Users\Administrator\Desktop\winpe`, and they will refer to it as `winpe`.

* Copy the entire contents of the directory containing this README into `winpe`.

* Copy any drivers that are required to run WinPE on your target hardware 
  into winpe/Drivers.  You can copy any number of drivers into that directory,
  as long as they are for Windows winpe amd64.  The drivers must be expanded -- 
  they should have the .inf and .sys files, and there should be one driver per 
  directory under the Drivers directory.  The drivers will be installed by the
  Add-WindowsDriver powershell cmdlet -- see the documentation for that cmdlet
  if you encounter any difficulties.  If you will be testing in a VM, you will
  need to include the appropriate drivers.  For KVM or Xen-based vms, the 
  virtio drivers from https://fedoraproject.org/wiki/Windows_Virtio_Drivers
  will come in handy.
  
* Ensure that the `build-winpe-iso.ps1` command from this directory is
  present in `winpe`.
  
* Open a command prompt, and cd into `winpe`.

* Run the following command:
  `powershell -executionpolicy bypass build-winpe-iso.ps1`
  
  It will take several minutes to finish, and at the end you will have an
  ISO named `winpe.iso`. Upload this ISO to a Digital Rebar endpoint, and you should
  be able to boot to the `windows-pe` boot environment

* Note: This image is not compatible with UEFI Secure Boot for now.

