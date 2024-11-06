@echo off

REM Drive Windows install media:
echo.
echo Drive Windows install media:
echo ===============================
wmic logicaldisk get name,volumename
echo ===============================
set /p _INSTALL_MEDIA_=select drive: 

REM Type install file (WIM/ESD):
if exist %_INSTALL_MEDIA_%\sources\install.esd (
	set _TYPE_FILE_=esd
) else (
	set _TYPE_FILE_=wim
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
dism /Apply-Image /ImageFile:%_INSTALL_MEDIA_%\sources\install.%_TYPE_FILE_% /index:%_INSTALL_EDITION_% /ApplyDir:C:

REM Setup UEFI Boot:
echo.
C:\Windows\System32\bcdboot C:\Windows /s Z: /f UEFI

REM Unattend.xml:
If %_SYS_LANG_% == [] (
	type unattend\header.txt unattend\footer.txt > unattend.xml
) else (
	if %_SYS_LANG_% == 1 (
		type unattend\header.txt unattend\en.txt unattend\footer.txt > unattend.xml
	)
	if %_SYS_LANG_% == 2 (
		type unattend\header.txt unattend\cz.txt unattend\footer.txt > unattend.xml
	)
	if %_SYS_LANG_% == 3 (
		type unattend\header.txt unattend\sk.txt unattend\footer.txt > unattend.xml
	)
	if %_SYS_LANG_% == X (
		type unattend\header.txt unattend\footer.txt > unattend.xml
	)
)

mkdir C:\Windows\Panther
copy unattend.xml C:\Windows\Panther

REM Finish:
C:\Windows\System32\shutdown.exe /r /t 0
 