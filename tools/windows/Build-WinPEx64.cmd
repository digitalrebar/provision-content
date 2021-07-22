@ECHO OFF
REM This script is based on https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-mount-and-customize
REM This script will build a sample 64-bit WinPE ISO for use with RackN Digital Rebar

:VERIFY_ADMIN_PRIV
REM This script calls commands, like DISM, that require administrative privileges
REM This tries to get some output from NET SESSION which requires admin privileges and errors out if it doesn't
NET SESSION > nul 2>&1
IF ERRORLEVEL 1 GOTO NO_ADMIN_PRIV

:VERIFY_REQS
REM Even ADK for Windows 11 uses the below path currently. Might need to be adjusted at some point in time.
SET ADK_PATH=%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit
IF NOT EXIST "%ADK_PATH%\Deployment Tools\DandISetEnv.bat" GOTO NO_ADK_INSTALLED
IF NOT EXIST "%ADK_PATH%\Windows Preinstallation Environment\copype.cmd" GOTO NO_ADK_INSTALLED

:SET_PE_ENV
SETLOCAL

SET PEScriptRoot=%~dp0
CALL "%ADK_PATH%\Deployment Tools\DandISetEnv.bat"

IF EXIST "%DISMRoot%" GOTO HAVE_ADK_PE_ROOT

ECHO The ADK root folder could not be determined.
ECHO.
ECHO Is the correct version of ADK installed?
ECHO.
GOTO NO_ADK_INSTALLED

:HAVE_ADK_PE_ROOT
SET TEMP_PE_FOLDER=%SYSTEMDRIVE%\WINPE_X64_BUILDER
SET LOGFILE="%TEMP_PE_FOLDER%\winpe_log.txt"

IF EXIST "%TEMP_PE_FOLDER%" RMDIR /S /Q "%TEMP_PE_FOLDER%"

:COPY_WINPE_FILES
CALL "%WinPERoot%\copype.cmd" amd64 "%TEMP_PE_FOLDER%"

:MOUNT_WINPE
SET TEMP_MOUNT_FOLDER=%TEMP_PE_FOLDER%\mount
"%DISMRoot%\dism.exe" /Mount-Wim /LogPath:%LOGFILE% /WimFile:"%TEMP_PE_FOLDER%\media\sources\boot.wim" /index:1 /MountDir:"%TEMP_MOUNT_FOLDER%"

:ADD_PACKAGES
ECHO.
ECHO Adding WinPE component packages
ECHO.
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-WMI.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-NetFX.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-Scripting.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-PowerShell.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-DismCmdlets.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-SecureBootCmdlets.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-SecureStartup.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-PlatformId.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-MDAC.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-RNDIS.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-HTA.cab"
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-Dot3Svc.cab"

ECHO.
ECHO Verifying all installed component packages (Pending is OK)
"%DISMRoot%\dism.exe" /image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Get-Packages

:INJECT_DRIVERS
SET DRIVER_ROOT_FOLDER=%PEScriptRoot%Drivers_WinPE_v10_64
ECHO DRIVER_ROOT_FOLDER=%DRIVER_ROOT_FOLDER%
ECHO.
ECHO Injecting drivers, this will take even longer...
"%DISMRoot%\dism.exe" /Image:"%TEMP_MOUNT_FOLDER%" /LogPath:%LOGFILE% /Add-Driver /Driver:"%DRIVER_ROOT_FOLDER%" /Recurse /ForceUnsigned

:INJECT_ADDITIONAL_FILES
SET ADDEDFILES=%PEScriptRoot%AddFiles_WinPE_64
ECHO ADDEDFILES=%ADDEDFILES%
ECHO.
ECHO Adding additonal files to WinPE image
XCOPY "%ADDEDFILES%" "%TEMP_MOUNT_FOLDER%" /Y /E /I

IF EXIST "%TEMP_MOUNT_FOLDER%\Windows\System32\winpeshl.ini" REN "%TEMP_MOUNT_FOLDER%\Windows\System32\winpeshl.ini" winpeshl.ini.disabled

:UNMOUNT_WINPE
ECHO.
ECHO Committing and unmounting the modified WinPE
"%DISMRoot%\Dism" /unmount-Wim /LogPath:%LOGFILE% /MountDir:"%TEMP_MOUNT_FOLDER%" /Commit

:CREATE_ISO
ECHO.
CALL "%WinPERoot%\MakeWinPEMedia.cmd" /ISO /F "%TEMP_PE_FOLDER%" "%PEScriptRoot%winpe.iso"
ECHO SHA256 for %PEScriptRoot%winpe.iso:
PowerShell -NoProfile -Command "(Get-FileHash -Path '%PEScriptRoot%winpe.iso' -Algorithm SHA256).Hash.ToLower()"

:CLEANUP
ECHO.
ECHO The DISM log file is located at:
ECHO %LOGFILE%
ECHO.
ECHO Removing temporary folder and log files, press CTRL-C to abort or
PAUSE
RMDIR /S /Q "%TEMP_PE_FOLDER%"

ENDLOCAL
EXIT /B 0

:NO_ADK_INSTALLED
ECHO.
ECHO The ADK for Windows 10 or higher does not appear to be installed, exiting...
ECHO.
ECHO The ADK and WinPE add-on can be downloaded from
ECHO https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install
PAUSE
EXIT /B 1

:NO_ADMIN_PRIV
ECHO.
ECHO This script requires to be run with administrative privileges!
ECHO Run this script again as Administrator.
ECHO.
PAUSE
EXIT /B 1
