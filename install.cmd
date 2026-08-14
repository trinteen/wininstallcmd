@echo off
setlocal EnableExtensions

REM Drive Windows install media:
echo.
echo Drive Windows install media:
echo ===============================
wmic logicaldisk get name,volumename
echo ===============================
set /p _INSTALL_MEDIA_=select drive (e.g. D:): 

REM Type install file (WIM/ESD/SWM):
if exist "%_INSTALL_MEDIA_%\sources\install.esd" (
	set _TYPE_FILE_=esd
) else if exist "%_INSTALL_MEDIA_%\sources\install.wim" (
	set _TYPE_FILE_=wim
) else if exist "%_INSTALL_MEDIA_%\sources\install.swm" (
	set _TYPE_FILE_=swm
) else (
	echo "[ERROR] %_INSTALL_MEDIA_%\sources\install.esd/wim/swm not found."
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
if /I "%_TYPE_FILE_%"=="swm" (
	dism /apply-image /imagefile:%_INSTALL_MEDIA_%\sources\install.%_TYPE_FILE_% /swmfile:%_INSTALL_MEDIA_%\sources\install*.%_TYPE_FILE_%  /index:%_INSTALL_EDITION_% /ApplyDir:W:
) else (
	dism /Apply-Image /ImageFile:%_INSTALL_MEDIA_%\sources\install.%_TYPE_FILE_% /index:%_INSTALL_EDITION_% /ApplyDir:W:
)
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
	type assets\part1.txt assets\en.txt assets\part2.txt assets\en.txt assets\part3.txt > unattend.xml
) else if /I "%_SYS_LANG_%" == "2" (
	type assets\part1.txt assets\cz.txt assets\part2.txt assets\cz.txt assets\part3.txt > unattend.xml
) else if /I "%_SYS_LANG_%" == "3" (
	type assets\part1.txt assets\sk.txt assets\part2.txt assets\sk.txt assets\part3.txt > unattend.xml
) else (
	type assets\part1.txt assets\part2.txt assets\part3.txt > unattend.xml
)

mkdir W:\Windows\Panther
copy /y unattend.xml W:\Windows\Panther

REM OEM
mkdir W:\Windows\OEM
copy /y assets\logo.bmp W:\Windows\OEM

REM Wallpaper
rmdir /s /q W:\Windows\Web\
mkdir W:\Windows\Web\Wallpaper\unattend
if exist "usermod\wallpaper.jpg" (
	copy /y usermod\wallpaper.jpg W:\Windows\Web\Wallpaper\unattend\
)

REM Apps:
mkdir W:\Windows\Setup\Scripts\
if exist "usermod\Apps.txt" (
	copy /y usermod\Apps.txt W:\Windows\Setup\Scripts\InstallApps.txt
)

REM Screensaver:
for %%i in (W:\*) do (
	if /I not "%%~nxi"=="scrsave.scr" del /f /q "%%i"
)

REM Help:
rmdir /s /q W:\Windows\Help

REM Finish:
W:\Windows\System32\shutdown.exe /r /t 0
 