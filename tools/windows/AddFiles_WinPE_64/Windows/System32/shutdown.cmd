@echo %* | find /i "/s" > nul
@if %errorlevel% equ 0 (wpeutil Shutdown) else (wpeutil Reboot)