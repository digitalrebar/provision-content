# Windows PE Boot Image

This directory contains the script needed to build a Windows PE
ISO image that can be booted and used for management tasks that require
a Windows environment.

## Prerequisites Required to Create Image

* A Windows 10 or newer system to act as a technician workstation.
* The technician workstation must have the Windows ADK as well as the
  WinPE add-on for ADK installed to the default location.
  You can download the ADK from:
  https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install
  The latest version of ADK for Windows 10 or newer is fine.
* Any drivers needed to enable WinPE to function on target systems.

## Creating a Rebar-compatible Windows PE boot image
All these steps should take place on the technician workstation, and
assume that the user is able to open up an elevated instance of the Command
Prompt.  They also assume that you are working from
`C:\Users\Administrator\Desktop\winpe`, and they will refer to it as `winpe`.

* Copy the entire contents of the directory containing this README into `winpe`.
* Copy any drivers that are required to run WinPE on your target hardware 
  into `winpe\Drivers_WinPE_v10_64`.  You can copy any number of drivers 
  into that directory, as long as they are for Windows winpe amd64.
  The drivers must be expanded -- they should have the .inf and .sys files, 
  and there should be one driver per directory under the Drivers directory.
  The drivers will be installed by DISM  -- see [the documentation](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-and-remove-drivers-to-an-offline-windows-image)
  for that tool if you encounter any difficulties.

  > If you will be testing in a VM, you will need to include the appropriate
  > drivers.  For KVM or Xen-based hypervisors, the virtio drivers from
  > https://fedoraproject.org/wiki/Windows_Virtio_Drivers will come in handy.
* If you need to add any additional executables to the WinPE image, they
  can be placed in the `winpe\AddFiles_WinPE_64` folder. Just be mindful
  that any executable you add to the image must be a true 64-bit application.
* Ensure that the `build-winpex64.cmd` script from this directory is
  present in `winpe`.
* Open an administrative command prompt, and cd into `winpe`.
* Run the script:
  `build-winpex64.cmd`

  It will take several minutes to finish, and at the end you will have an
  ISO named `winpe.iso`. Upload this ISO to a Digital Rebar endpoint, and you should
  be able to boot to the `windows-pe` boot environment
* The script will also output the SHA256 hash which you will need to provide when
  uploading the ISO.
* **Note:** This ISO is compatible with UEFI Secure Boot, but the `wimboot` method
  of loading it, is not.
