@echo off

REM Drive Windows install media:
echo.
echo Drive Windows install media:
echo ===============================
wmic logicaldisk get name,volumename
echo ===============================
set /p _INSTALL_MEDIA_=select drive: 

REM Select index Windows Edition:
echo.
echo Choose Windows edition:
echo ===============================
dism /Get-WimInfo /WimFile:%_INSTALL_MEDIA_%\sources\install.esd
echo ===============================
set /p _INSTALL_EDITION_=Index edition: 

REM List driver to install Windows:
echo.
echo Select drive to install Windows
echo ===============================
wmic diskdrive get index,model,size
echo ===============================
set /p _INSTALL_DISK_=select drive: 

REM Diskpart script:
echo sel disk %_INSTALL_DISK_% > script.txt
echo clean >> script.txt
echo convert gpt >> script.txt
echo create partition efi size=100 >> script.txt
echo format fs=fat32 label=EFI quick >> script.txt
echo assign letter=Z >> script.txt
echo create partition primary >> script.txt
echo format fs=ntfs label=WINDOWS quick >> script.txt
echo assign letter=C >> script.txt
diskpart /s script.txt

REM Install Windows to selected drive:
dism /Apply-Image /ImageFile:%_INSTALL_MEDIA_%\sources\install.esd /index:%_INSTALL_EDITION_% /ApplyDir:C:

REM Setup UEFI Boot:
echo.
C:\Windows\System32\bcdboot C:\Windows /s Z: /f UEFI

REM Finish:
echo.
echo Finish! Reboot system please :) 