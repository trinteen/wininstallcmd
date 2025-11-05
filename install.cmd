@echo off
setlocal EnableExtensions

REM Drive Windows install media:
echo.
echo Drive Windows install media:
echo ===============================
wmic logicaldisk get name,volumename
echo ===============================
set /p _INSTALL_MEDIA_=select drive (e.g. D:): 

REM Type install file (WIM/ESD):
if exist "%_INSTALL_MEDIA_%\sources\install.esd" (
	set _TYPE_FILE_=esd
) else if exist "%_INSTALL_MEDIA_%\sources\install.wim" (
	set _TYPE_FILE_=wim
) else (
	echo "[ERROR] %_INSTALL_MEDIA_%\sources\install.esd/wim not found."
    goto :EOF
)

REM Language:
echo.
echo System language:
echo ===============================
echo 1. English
echo 2. Czech
echo 3. Slovak
echo X. Default
echo ===============================
set /p _SYS_LANG_=Select language:

REM Select index Windows Edition:
echo.
echo Choose Windows edition:
echo ===============================
dism /Get-WimInfo /WimFile:%_INSTALL_MEDIA_%\sources\install.%_TYPE_FILE_%
if errorlevel 1 (
	echo "[ERROR] Failed to read image indexes. Check the media path."
    goto :EOF
)

echo ===============================
set /p _INSTALL_EDITION_=Index edition (number):

for /f "delims=0123456789" %%A in ("%_INSTALL_EDITION_%") do (
    echo "[ERROR] Index must be a number."
    goto :EOF
)

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
echo assign letter=W >> script.txt
diskpart /s script.txt
if errorlevel 1 (
	echo "[ERROR] Disk partitioning failed."
    goto :EOF
)

REM Install Windows to selected drive:
dism /Apply-Image /ImageFile:%_INSTALL_MEDIA_%\sources\install.%_TYPE_FILE_% /index:%_INSTALL_EDITION_% /ApplyDir:W:
if errorlevel 1 (
	echo "[ERROR] Image apply failed."
    goto :EOF
)

REM Setup UEFI Boot:
echo.
W:\Windows\System32\bcdboot W:\Windows /s Z: /f UEFI
if errorlevel 1 (
    echo "[ERROR] bcdboot failed."
    goto :EOF
)

REM Unattend.xml:
if "%_SYS_LANG_%"=="" set _SYS_LANG_=X
if /I "%_SYS_LANG_%" == "1" (
	type unattend\part1.txt unattend\en.txt unattend\part2.txt unattend\en.txt unattend\part3.txt > unattend.xml
) else if /I "%_SYS_LANG_%" == "2" (
	type unattend\part1.txt unattend\cz.txt unattend\part2.txt unattend\cz.txt unattend\part3.txt > unattend.xml
) else if /I "%_SYS_LANG_%" == "3" (
	type unattend\part1.txt unattend\sk.txt unattend\part2.txt unattend\sk.txt unattend\part3.txt > unattend.xml
) else (
	type unattend\part1.txt unattend\part2.txt unattend\part3.txt > unattend.xml
)

mkdir W:\Windows\Panther 2>nul
copy /y unattend.xml W:\Windows\Panther >nul

REM Finish:
W:\Windows\System32\shutdown.exe /r /t 0
 