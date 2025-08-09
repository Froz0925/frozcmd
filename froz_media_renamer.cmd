@echo off
set "VERS=Froz media renamer v09.08.2025"

if not "%~1"=="" goto chk
echo(%VERS%
echo.
echo ����⭮� ��२��������� 䠩��� �� ��᪥: YYYY-MM-DD_HHMMSS_���_[PROGR].ext
echo.
echo ����⠥� �:
echo   - EXIF � JPG ^(DTO^) - �ਮ���
echo   - ��⮩ � ����� 䠩�� ^(ࠧ�� �ଠ��, �஡���, ࠧ����⥫�^)
echo   - ��⮩ ��������� 䠩�� ^(DLM^)
echo.
echo �ᮡ������:
echo   - ����砥� Progressive JPEG ��� _PROGR
echo   - ������ ��䨪��: IMG_, VID_, DSC_, PIC_
echo   - �� ��२�����뢠�� 䠩��, 㦥 ᮮ⢥�����騥 ��᪥
echo   - �� ���䫨��� ��� �������� _1, _2 � �.�.
echo   - �ਮ���: EXIF ^> ��� ^> DLM
echo.
echo ��� �ᯮ�짮����:
echo   ������ ����� ��� 䠩�� �� �ਯ�.
echo   �᫨ ���� ��㬥�� - �����, ��ࠡ�⠥� �� 䠩�� � ���.
echo.
echo.
pause
exit /b

:chk
set "CMD=%*"
if "%CMD:~7000,1%" neq "" (
    echo.
    echo ��������: ��।��� �祭� ����� 䠩��� - ����� 8100 ᨬ�����.
    echo Windows ����� ��१��� ᯨ᮪ - ���� 䠩��� �� �㤥� ��ࠡ�⠭�.
    echo.
    echo ������������ ������� ����� � 䠩����, � �� �⤥��� 䠩��.
    echo.
    pause
)

set "EXV=%~dp0bin\exiv2.exe"
if not exist "%EXV%" (
    echo.
    echo(�訡��: �� ������ "%EXV%".
    echo ������� exiv2.exe � exiv2.dll � ����� bin �冷� � cmd-䠩���
    echo.
    pause
    exit /b
)

set "TV=%temp%\dltm$.vbs"
> "%TV%" echo Wscript.Echo CreateObject("Scripting.FileSystemObject").GetFile(WScript.Arguments.Item(0)).DateLastModified

set "CNT=0"
set "CNTALL=0"
set "CNTP=0"
set "CNTT=0"
set "DTOALL="

set "CMDN=%~nx0"
set "ATTR=%~a1"
set "ATTR=%ATTR:~,1%"
if /i "%ATTR%"=="d" goto mode_folder
goto mode_files


:: ����� ࠡ���: ���᮪ 䠩���
:mode_files
set "FLD=%~dp1"
pushd "%FLD%"
echo ��ࠡ�⪠ ᯨ᪠ 䠩���...
echo --------------------------
goto start_loop



:: ���� �� 䠩���
:start_loop
if "%~1"=="" goto done
set "ATTR=%~a1"
set "ATTR=%ATTR:~,1%"
if /i "%ATTR%"=="d" goto next_arg
set "FN=%~nx1"
set /a CNTALL+=1
call :process_file
:next_arg
shift
goto start_loop


:: ����� ࠡ���: �����
:mode_folder
set "FLD=%~f1"
pushd "%FLD%"
echo(��ࠡ�⪠ ����� "%FLD%"...
echo --------------------------------------------
echo.
set "LIST=%temp%\list_%random%.tmp"
dir /b /a-d "%FLD%\*" > "%LIST%" 2>nul
if not exist "%LIST%" goto done
for /f "usebackq delims=" %%i in ("%LIST%") do call :process_file_in_folder "%%i"
del "%LIST%"
goto done

:: ��� ����ணࠬ�� ��諮�� �१��� � ⥫� �᭮����� ��⮪� ��� ��⪨ done ���� �ਯ� �� ����� ��� ����
:process_file_in_folder
set "FN=%~1"
set /a CNTALL+=1
call :process_file
exit /b




:: === ����������� ��������� ������ ===
:done
popd
if exist "%TV%" del "%TV%" >nul

set "TXT_ALL="
set "TXT_PROGR="
set "TXT_DTO="
echo.
echo(--- ��⮢� ---
if %CNT% gtr 0 set "TXT_ALL=��२��������: %CNT% �� %CNTALL% 䠩���."
if %CNTP% gtr 0 set "TXT_PROGR=����祭� ��� PROGR: %CNTP% 䠩���."
if %CNTT% gtr 0 set "TXT_DTO=��������� EXIF-���: %CNTT% 䠩���."
if %CNT% gtr 0 echo(%TXT_ALL%
if %CNTP% gtr 0 echo(%TXT_PROGR%
if %CNTT% gtr 0 echo(%TXT_DTO%

set "HF=%temp%\%CMDN%-hlp_%random%.txt"
set "VB=%temp%\%CMDN%-hlp_%random%.vbs"
if exist "%HF%" del "%HF%"
if exist "%VB%" del "%VB%"
>nul chcp 1251&>>"%HF%" (
  cmd /c echo(%CMDN% �����稫 ࠡ���.
  cmd /c echo.
  cmd /c echo(%TXT_ALL%
  cmd /c echo.
  cmd /c echo(%TXT_PROGR%
  cmd /c echo(%TXT_DTO%
)&>nul chcp 866
echo MsgBox CreateObject("Scripting.FileSystemObject").OpenTextFile("%HF%").ReadAll,,"%CMDN%">"%VB%"
start "" /wait "%VB%"
if exist "%VB%" del "%VB%"
if exist "%HF%" del "%HF%"
pause
exit /b 0
:: === ����� ��������� ������ ===






:: === ������������ ===
:process_file
:: ���樠������ ��६�����
set "BASE="
set "EXT="
set "DTO="
set "ISJPG="
set "Y=" & set "M=" & set "D=" & set "HH=" & set "MM=" & set "SS="

:: ����砥� ������� ��� � ���७��
for %%f in ("%FN%") do set "BASE=%%~nf"
for %%f in ("%FN%") do set "EXT=%%~xf"

:: �ய�᪠�� 䠩�� ��� ���७��
if "%EXT%"=="" exit /b

:: ����塞 ��䨪�� (ॣ���஭�����ᨬ�)
if /i "%BASE:IMG_=%" neq "%BASE%" set "BASE=%BASE:IMG_=%"
if /i "%BASE:VID_=%" neq "%BASE%" set "BASE=%BASE:VID_=%"
if /i "%BASE:DSC_=%" neq "%BASE%" set "BASE=%BASE:DSC_=%"
if /i "%BASE:PIC_=%" neq "%BASE%" set "BASE=%BASE:PIC_=%"

:: --- ����⪠ ��⠢��� _ ����� ��⮩ � �६���� ---
:: ��ଠ�: YYYYMMDD[ࠧ����⥫�]HHMMSS
set "TEST=%BASE:~0,8%"
echo(%TEST%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto check_yyyymmdd

set "REST=%BASE:~8%"
if not defined REST goto check_yyyymmdd

:: �ய�᪠�� �஡���, _, - � ��砫� REST
set "JUNK=%REST%"
:skip_junk
if not defined JUNK goto check_yyyymmdd
if "%JUNK:~0,1%"==" " set "JUNK=%JUNK:~1%" & goto skip_junk
if "%JUNK:~0,1%"=="_" set "JUNK=%JUNK:~1%" & goto skip_junk
if "%JUNK:~0,1%"=="-" set "JUNK=%JUNK:~1%" & goto skip_junk

:: �஢��塞, ��稭����� �� ���⮪ � 6 ���
if "%JUNK:~5,1%"=="" goto check_yyyymmdd
set "HMSCAND=%JUNK:~0,6%"
echo(%HMSCAND%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto check_yyyymmdd

:: ��� �� - ��⠢�塞 _ ��᫥ YYYYMMDD, �� ��頥� REST �� ��砫��� �஡����/ᨬ�����
set "CLEAN_REST=%REST%"
:clean_rest_junk
if not defined CLEAN_REST goto after_clean_rest
if "%CLEAN_REST:~0,1%"==" " set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk
if "%CLEAN_REST:~0,1%"=="_" set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk
if "%CLEAN_REST:~0,1%"=="-" set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk
:after_clean_rest
set "BASE=%BASE:~0,8%_%CLEAN_REST%"
goto after_date_fix

:check_yyyymmdd
:: ��ଠ�: YYYY-MM-DDHHMMSS
set "TEST=%BASE:~0,10%"
if not "%TEST:~4,1%"=="-" goto after_date_fix
if not "%TEST:~7,1%"=="-" goto after_date_fix
set "REST=%BASE:~10%"
if not defined REST goto after_date_fix
set "FIRST=%REST:~0,1%"
echo(%FIRST%| findstr "^[0-9]$" >nul
if errorlevel 1 goto after_date_fix
set "BASE=%BASE:~0,10%_%REST%"

:after_date_fix
:: ����塞 ��砫�� ᨬ����: �஡��, _, -
:trim_start
if "%BASE:~0,1%"==" " set "BASE=%BASE:~1%" & goto trim_start
if "%BASE:~0,1%"=="_" set "BASE=%BASE:~1%" & goto trim_start
if "%BASE:~0,1%"=="-" set "BASE=%BASE:~1%" & goto trim_start

:: ��⠭�������� SUFFIX
set "SUFFIX=%BASE%"

:: ��� JPEG �஡㥬 ������� EXIF �����
if /i "%EXT%"==".jpg" set "ISJPG=1"
if /i "%EXT%"==".jpeg" set "ISJPG=1"
if defined ISJPG goto ext_jpg

:: ��� ��⠫��� 䠩��� �ᯮ��㥬 ���� ���������
goto choose_date




:ext_jpg
:: ��� �� ࠡ�⠥�:
:: 1. ��⠥� EXIF.DateTimeOriginal
:: 2. �᫨ ��� - goto choose_date
:: 3. �᫨ ���� - �ࠢ������ � ��⮩ �� �����
:: 4. �᫨ �� ᮢ������ - ��२�����뢠��
:: 5. �᫨ ᮢ������ - ��⠢�塞
set "TMP=%temp%\dto_%random%.txt"
"%EXV%" -q -g Exif.Photo.DateTimeOriginal -Pv "%FN%" > "%TMP%"
set /p "DTO=" < "%TMP%"
if exist "%TMP%" del "%TMP%" >nul

:: �᫨ DTO ��� - ���室�� � DLM
if not defined DTO goto choose_date

:: ��������� ���� �� EXIF
set "Y=%DTO:~0,4%"
set "M=%DTO:~5,2%"
set "D=%DTO:~8,2%"
set "HH=%DTO:~11,2%"
set "MM=%DTO:~14,2%"
set "SS=%DTO:~17,2%"

:: �஢�ઠ ���४⭮�� EXIF-����
:: �ਬ�� ����� ���祭��: 0000:00:00, 2023:00:45, 9999:99:99
:: �᫨ ��� ��������� - �ᯮ��㥬 DLM
if "%Y%"=="" goto choose_date
if "%M%"=="" goto choose_date
if "%D%"=="" goto choose_date
if %M% lss 1 goto choose_date
if %M% gtr 12 goto choose_date
if %D% lss 1 goto choose_date
if %D% gtr 31 goto choose_date
if %HH% gtr 23 goto choose_date
if %MM% gtr 59 goto choose_date
if %SS% gtr 59 goto choose_date

set "DTO_COMP=%Y%-%M%-%D% %HH%:%MM%:%SS%"
set "DTO_DATE=%Y%-%M%-%D%"

call :extract_date_from_name

:: �᫨ ��� � ����� �����祭� - �ࠢ������
if not defined NAME_Y goto build_name
:: �᫨ �६� � ����� �� �����祭� - �ࠢ������ ⮫쪮 ����
if not defined NAME_HH goto ext_jpg_compare_date_only

:: --- �஢�ઠ: ᮢ������ �� ��� � ������� ��᪮�? ---
:: ��ଠ�: YYYY-MM-DD_HHMMSS_...
set "MASK_PATTERN=____-__-__"
set "PART=%FN:~0,10%"
if not "%PART:~4,1%"=="-" goto build_name
if not "%PART:~7,1%"=="-" goto build_name
echo(%PART%| findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" >nul
if errorlevel 1 goto build_name

:: �஢��塞, �� ��᫥ ���� - �����ન�����
if "%FN:~10,1%" neq "_" goto build_name

:: �஢��塞, �� ��᫥ ���� - 6 ��� �६���
set "TIME_PART=%FN:~11,6%"
echo(%TIME_PART%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto build_name

:: --- ������ �஢��塞 ᮢ������� ���� ---
set "NAME_COMP=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"
if not "%NAME_COMP%"=="%DTO_COMP%" goto build_name

:: --- ���� 㦥 ᮮ⢥����� ��᪥ ---
echo(%FN% - �ய�饭, ��२��������� �� �ॡ����.
echo.
exit /b



:ext_jpg_compare_date_only
:: �ࠢ������ ⮫쪮 ���� (�६� �� ����� �� �����祭�)
set "NAME_DATE=%NAME_Y%-%NAME_M%-%NAME_D%"
if not "%NAME_DATE%"=="%DTO_DATE%" goto build_name

:: --- �஢�ઠ �ଠ� ��᪨ ��� ���� ��� �६��� ---
set "PART=%FN:~0,10%"
if not "%PART:~4,1%"=="-" goto build_name
if not "%PART:~7,1%"=="-" goto build_name
echo(%PART%| findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" >nul
if errorlevel 1 goto build_name
if "%FN:~10,1%" neq "_" goto build_name

:: --- ���� 㦥 ᮮ⢥����� ��᪥ ---
echo(%FN% - �ய�饭, ��२��������� �� �ॡ����.
echo.
exit /b





:choose_date
:: ���筨�� �� �ਮ����: ���, DLM
:: �� DTOALL=1: ��⮬���᪨ �����뢠�� EXIF � JPG ��� DTO � �ய�᪠�� ������

:: ��������� DLM
for /f "delims=" %%t in ('cscript //nologo "%TV%" "%FN%"') do set "DT=%%t"

:: ���ᨬ DLM: DD.MM.YYYY H:MM:SS ��� HH:MM:SS
set "D=%DT:~0,2%"
set "M=%DT:~3,2%"
set "Y=%DT:~6,4%"
set "HH=%DT:~11,2%"
set "MM=%DT:~14,2%"
set "SS=%DT:~17,2%"
:: �᫨ ��������� �� (���ਬ��, "8:08:08")
if not "%HH%"=="%HH::=%" (
    set "HH=0%HH:~0,1%"
    set "MM=%DT:~13,2%"
    set "SS=%DT:~16,2%"
)

:: ���࠭塞 DLM
set "Y_DLM=%Y%"
set "M_DLM=%M%"
set "D_DLM=%D%"
set "HH_DLM=%HH%"
set "MM_DLM=%MM%"
set "SS_DLM=%SS%"

:: ��������� ���� � �६� �� �����
call :extract_date_from_name

:: --- DTOALL: 䫠� ��� ��⮬���᪮� ��ࠡ�⪨ ---
:: ��⠭���������� � [a], �� EXIF �����뢠���� ������ � handle_a_choice
:: ����� - �� ��뢠�� :do_write, ⮫쪮 �஢��塞, �㦭� �� �����뢠�� ������
if not defined DTOALL goto check_jpg_dialog
if not defined ISJPG goto check_jpg_dialog
if defined DTO goto check_jpg_dialog

:: �᫨ DTOALL=1 � �� JPG ��� DTO - �����뢠�� EXIF � �ᯮ��㥬 DLM
call :do_write
set "Y=%Y_DLM%"
set "M=%M_DLM%"
set "D=%D_DLM%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
goto build_name

:check_jpg_dialog
:: --- ��।��塞, �㦭� �� �����뢠�� ������ ��� JPG ---
if not defined ISJPG goto use_name_or_dlm

:: �᫨ �� JPG � ��� ������ ���� � ����� - �����뢠�� ������
if not defined NAME_Y goto ask_user
if not defined NAME_HH goto ask_user

:: � JPG ���� ������ ��� � ����� - �ᯮ��㥬 ��, �� �����뢠�� ������
goto use_name_full

:: --- �᭮���� ������ �롮� ���� ---
:use_name_or_dlm
:: �᫨ ���� ������ ��� � �६� � ����� - �ᯮ��㥬 ��
if not defined NAME_Y goto use_name_date_dlm_time
if not defined NAME_HH goto use_name_date_dlm_time

:use_name_full
:: --- ������ ��� � �६� ������� � ����� 䠩�� - �ᯮ��㥬 �� ---
:: �ਬ��: 2021-07-04_174724.txt - Y=2021, M=07, D=04, HH=17, MM=47, SS=24
set "Y=%NAME_Y%"
set "M=%NAME_M%"
set "D=%NAME_D%"
set "HH=%NAME_HH%"
set "MM=%NAME_MM%"
set "SS=%NAME_SS%"
goto build_name

:use_name_date_dlm_time
:: --- ��� � ����� ����, �� �६��� ��� - ��������㥬: ��� �� �����, �६� �� DLM ---
:: �ਬ��: 2021-07-04_Photo.txt - Y=2021, M=07, D=04, HH=12, MM=34, SS=56 (�� DLM)
:: � �᫨ ��� � ���� - ���室�� � �ᯮ�짮����� ������� DLM
if not defined NAME_Y goto use_dlm
set "Y=%NAME_Y%"
set "M=%NAME_M%"
set "D=%NAME_D%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
goto build_name

:: --- ��ନ�㥬 ��ப� ��� �⮡ࠦ���� ���짮��⥫� ---
:: ��ਠ���:
:: 1. ������ ��� � �६� � ����� - ���� ��� �� �����
:: 2. ���쪮 ��� � ����� - ��� �� �����, �६� �� DLM
:: 3. ��祣� �� �����祭� - ⮫쪮 DLM
:: ��६����� YMDHMS_NAME �ᯮ������ ������ ��� echo, �� ����� �� ��२���������
:ask_user
echo(--- ��� EXIF.DateTimeOriginal ^(DTO^) � %FN% ---
echo.
set "YMDHMS_NAME="

if not defined NAME_Y goto show_user_use_dlm_fallback
if not defined NAME_HH goto show_user_use_name_date_dlm_time

set "YMDHMS_NAME=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"
goto show_user_suggestion

:show_user_use_name_date_dlm_time
:: --- ��� � ����� ����, �� �६��� ��� - �ᯮ��㥬 ��� �⮡ࠦ����: ��� �� �����, �६� �� DLM ---
:: ���쪮 ��� ������ ���짮��⥫�; ॠ�쭮� ��᢮���� - � use_name_date_dlm_time
set "YMDHMS_NAME=%NAME_Y%-%NAME_M%-%NAME_D% %HH_DLM%:%MM_DLM%:%SS_DLM%"
goto show_suggestion

:show_user_use_dlm_fallback
:: --- �� ����, �� �६��� �� �����祭� �� ����� - �ᯮ��㥬 ⮫쪮 DLM ---
:: �ਬ��: Photo123.txt - ��� ������� �� ���� ��������� 䠩��
set "YMDHMS_NAME=%Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%"

:show_user_suggestion
echo(�।�������� ���-�६�: %YMDHMS_NAME%
echo(��� ��������� 䠩�� ^(DLM^): %Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%
echo.
echo([a] - ������� �।�������� � EXIF ��� ��� JPG ��� DTO
echo([w] - ������� �।�������� � EXIF
echo([m] - ����� DTO ������
echo(�� ��㣠� ������ - �ய�����
set /p "USRCHOICE=�롮�: "
if /i "%USRCHOICE%"=="a" goto handle_a_choice
if /i "%USRCHOICE%"=="w" goto handle_w_choice
if /i not "%USRCHOICE%"=="m" (
    echo.
    echo �⬥���� ������ � EXIF.
    echo(%FN% �ய�饭.
    echo.
    exit /b
)
goto manual_input_start

:manual_input_start
set "MANUAL="
echo.
echo(������ ���� ����-��-�� ��:��:�� ��� [q] ��� �⬥��
set /p "MANUAL=���: "
set "MANUAL=%MANUAL:"=%"
if /i "%MANUAL%"=="q" (
    echo.
    echo �⬥�� ��筮� ����.
    echo(%FN% �ய�饭.
    echo.
    exit /b
)

set "TMP=%temp%\man_%random%.tmp"
echo(%MANUAL%>"%TMP%"
findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]$" "%TMP%" >nul
set "ERR=%errorlevel%"
if exist "%TMP%" del "%TMP%" >nul
if %ERR% equ 1 (
    echo.
    echo(������ �ଠ�. �ਬ��: 2023-12-31 23:59:59
    echo.
    goto manual_input_start
)
:: --- ��砫� ��ࠡ�⪨ ��筮�� ����� ---
:: �஢��塞, �� ��� � �ଠ� ����-��-�� ��:��:��
:: ����塞 ����窨 � �஢��塞 �ଠ� �१ �६���� 䠩�
set "DT_VALID=1"
set "Y=%MANUAL:~0,4%"
set "M=%MANUAL:~5,2%"
set "D=%MANUAL:~8,2%"
set "H_TMP=%MANUAL:~11,2%"
set "MM=%MANUAL:~14,2%"
set "S_TMP=%MANUAL:~17,2%"
:: --- ����塞 �஡��� � ��� � ᥪ㭤�� (�� ��砩 " 8" ��� " 5") ---
:: �⮡� ���४⭮ ��ࠡ��뢠�� ���� � ��������묨 �ᠬ�/ᥪ㭤���
set "H_TMP=%H_TMP: =%"
set "S_TMP=%S_TMP: =%"
:: --- ������塞 ����騩 ���� ��� ���������� �ᮢ (���ਬ��, "8" - "08") ---
:: �᫨ ��ன ᨬ��� ��������� - �����, �᫮ �������筮�
if "%H_TMP:~1,1%"=="" set "HH=0%H_TMP%" & goto after_hh_manual
set "HH=%H_TMP%"
:after_hh_manual
:: --- ������塞 ����騩 ���� ��� ���������� ᥪ㭤 ---
:: �������筮 �ᠬ
if "%S_TMP:~1,1%"=="" set "SS=0%S_TMP%" & goto after_ss_manual
set "SS=%S_TMP%"
:after_ss_manual
:: --- �஢�ઠ ���४⭮�� ���� � �६��� ---
:: �����: 1-12, ����: 1-31, ��: 0-23, ������/ᥪ㭤�: 0-59
:: �� �஢��塞 ��᮪��� ���� ��� �筮� ������⢮ ���� � �����
if %M% LSS 1 set "DT_VALID=0"
if %M% GTR 12 set "DT_VALID=0"
if %D% LSS 1 set "DT_VALID=0"
if %D% GTR 31 set "DT_VALID=0"
if %HH% GTR 23 set "DT_VALID=0"
if %MM% GTR 59 set "DT_VALID=0"
if %SS% GTR 59 set "DT_VALID=0"
:: --- �᫨ ��� �����४⭠ - �����頥��� � ����� ---
:: ���짮��⥫� ����� ��ࠢ��� �訡��
if %DT_VALID% equ 0 (
    echo(�������⨬� ���祭�� ����/�६���.
    echo.
    goto manual_input_start
)

call :do_write
goto build_name

:: --- ��ࠡ�⪠ [a] ---
:handle_a_choice
:: ��᫥ [a] - DTOALL=1, � �� ��᫥���騥 JPG ��� DTO ���� ��ࠡ�⠭� ��⮬���᪨
set "DTOALL=1"
if not defined ISJPG goto skip_a_write
if defined DTO goto skip_a_write
call :do_write
:skip_a_write
goto use_dlm

:: --- ��ࠡ�⪠ [w] ---
:handle_w_choice
call :do_write
goto build_name

:use_dlm
set "Y=%Y_DLM%"
set "M=%M_DLM%"
set "D=%D_DLM%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
goto build_name






:do_write
echo(�����뢠�� DateTimeOriginal=%Y%-%M%-%D% %HH%:%MM%:%SS% � %FN%
"%EXV%" -M"set Exif.Photo.DateTimeOriginal %Y%-%M%-%D% %HH%:%MM%:%SS%" "%FN%"
set /a CNTT+=1
exit /b





:extract_date_from_name
:: ��⠥��� ������� ���� � �६� �� ����� 䠩��.
:: HMSCAND - "HMS Candidate" - ����� ���� ����, ����஢�, ��� ���������
set "NAME_Y=" & set "NAME_M=" & set "NAME_D=" & set "NAME_HH=" & set "NAME_MM=" & set "NAME_SS="

:: --- ����⪠ 1: �ଠ� YYYYMMDD_HHMMSS (� �����ન������)
set "YMD=%BASE:~0,8%"
set "HMSCAND=%BASE:~9,6%"
echo(%YMD%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto try_yyyymmdd_hhmmss
if not "%BASE:~8,1%"=="_" goto try_yyyymmdd_hhmmss
echo(%HMSCAND%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto try_yyyymmdd_hhmmss
set "NAME_Y=%YMD:~0,4%"
set "NAME_M=%YMD:~4,2%"
set "NAME_D=%YMD:~6,2%"
call :check_date_format
if errorlevel 1 goto try_yyyymmdd_hhmmss
call :check_time_format
if %TIME_VALID% equ 1 (
    set "NAME_HH=%HH%"
    set "NAME_MM=%MM%"
    set "NAME_SS=%SS%"
)
exit /b

:try_yyyymmdd_hhmmss
:: --- ����⪠ 2: �ଠ� YYYY-MM-DD_HHMMSS
echo(%BASE%| findstr "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]" >nul
if errorlevel 1 goto try_yyyymmdd_only
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
set "HMSCAND=%BASE:~11,6%"
call :check_date_format
if errorlevel 1 goto try_yyyymmdd_only
call :check_time_format
if %TIME_VALID% equ 1 (
    set "NAME_HH=%HH%"
    set "NAME_MM=%MM%"
    set "NAME_SS=%SS%"
)
exit /b

:try_yyyymmdd_only
:: --- ����⪠ 3: �ଠ� YYYY-MM-DD_ (⮫쪮 ���)
echo(%BASE%| findstr "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_" >nul
if errorlevel 1 exit /b
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
call :check_date_format
if errorlevel 1 exit /b
exit /b

:try_yyyymmdd_no_sep
:: --- ����⪠ 4: �ଠ� YYYY-MM-DDhhmmss (��� ࠧ����⥫�)
echo(%BASE%| findstr "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]" >nul
if errorlevel 1 exit /b
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
set "HMSCAND=%BASE:~10,6%"
call :check_date_format
if errorlevel 1 exit /b
call :check_time_format
if %TIME_VALID% equ 1 (
    set "NAME_HH=%HH%"
    set "NAME_MM=%MM%"
    set "NAME_SS=%SS%"
)
exit /b





:check_date_format
set "DATE_VALID=0"
:: �஢��塞, �� Y - 4 ����, M � D - 2 ����
echo(%NAME_Y%| findstr /r "^[0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 exit /b
echo(%NAME_M%| findstr /r "^[0-9][0-9]$" >nul
if errorlevel 1 exit /b
echo(%NAME_D%| findstr /r "^[0-9][0-9]$" >nul
if errorlevel 1 exit /b
:: ���������
set "Y_CHK=" & set "M_CHK=" & set "D_CHK="
set /a Y_CHK=1%NAME_Y% %% 10000
set /a M_CHK=1%NAME_M% %% 100
set /a D_CHK=1%NAME_D% %% 100
:: ��������� � ���ᨬ���� ���
if %Y_CHK% lss 1900 exit /b
if %Y_CHK% gtr 2100 exit /b
if %M_CHK% lss 1 exit /b
if %M_CHK% gtr 12 exit /b
if %D_CHK% lss 1 exit /b
if %D_CHK% gtr 31 exit /b
set "DATE_VALID=1"
exit /b





:check_time_format
:: �����祭�� �ᮢ/�����/ᥪ㭤 �� 6-ᨬ���쭮� ��ப� (���ਬ��, 081234)
:: �஡����: set /a �� �ਭ����� "08" ��� �᫮ (���� 08 - �訡�� � ���쬥�筮� ��⥬�)
:: ��襭��: �ਯ��뢠�� 100 ᯥ।� - "10008", ���� mod 100 (����� �� 100) - 8
:: ��� ��室�� ����騥 �㫨 ��� if � ��� �訡��
:: �ਬ��: %HMSCAND:~0,2% = "08" - 10008 %% 100 = 8
set "TIME_VALID=0"
:: �஢��塞, �� HMSCAND - ஢�� 6 ���
echo(%HMSCAND%|findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 exit /b
:: ��������� HH, MM, SS � ��室�� ������ �㫥�
set "HH_CHK=" & set "MM_CHK=" & set "SS_CHK="
set /a HH_CHK=100%HMScand:~0,2% %% 100
set /a MM_CHK=100%HMScand:~2,2% %% 100
set /a SS_CHK=100%HMScand:~4,2% %% 100
:: �஢��塞 ���������
if %HH_CHK% gtr 23 exit /b
if %MM_CHK% gtr 59 exit /b
if %SS_CHK% gtr 59 exit /b
:: ��ଠ��㥬 � ����騬� ��ﬨ
set "HH=%HH_CHK%" & if %HH_CHK% lss 10 set "HH=0%HH_CHK%"
set "MM=%MM_CHK%" & if %MM_CHK% lss 10 set "MM=0%MM_CHK%"
set "SS=%SS_CHK%" & if %SS_CHK% lss 10 set "SS=0%SS_CHK%"
set "TIME_VALID=1"
exit /b





:build_name
set "YMDHMS=%Y%-%M%-%D%_%HH%%MM%%SS%"

:: --- ������ᠫ쭠� ���⪠ SUFFIX �� ��譨� ᨬ����� � __ ---
:clean_suffix
if not defined SUFFIX goto skip_suffix_processing
:clean_loop
:: ����塞 _ � �஡��� ⮫쪮 � ��砫�
if "%SUFFIX:~0,1%"=="_" set "SUFFIX=%SUFFIX:~1%" & goto clean_loop
if "%SUFFIX:~0,1%"==" " set "SUFFIX=%SUFFIX:~1%" & goto clean_loop
:: ����塞 _ � �஡��� ⮫쪮 � ����
if "%SUFFIX:~-1%"=="_" set "SUFFIX=%SUFFIX:~0,-1%" & goto clean_loop
if "%SUFFIX:~-1%"==" " set "SUFFIX=%SUFFIX:~0,-1%" & goto clean_loop
:: �����塞 ������ �����ન����� �� �������
set "OLD=%SUFFIX%"
set "SUFFIX=%SUFFIX:__=_%"
if not "%SUFFIX%"=="%OLD%" goto clean_loop

:: --- �������� �㡫�஢���� �६��� HHMMSS ---
set "TIME_PART=%HH%%MM%%SS%"
if "%SUFFIX:~0,6%"=="%TIME_PART%" (
    set "SUFFIX=%SUFFIX:~6%"
    goto clean_suffix
)

:: --- �������� �㡫�஢���� ���� YYYYMMDD ---
set "DT_PART=%Y%%M%%D%"
if "%SUFFIX:~0,8%"=="%DT_PART%" (
    set "SUFFIX=%SUFFIX:~8%"
    goto clean_suffix
)

:: --- �������� �㡫�஢���� ���� YYYY-MM-DD ---
set "DATE_PART=%YMDHMS:~0,10%"
if "%SUFFIX:~0,10%"=="%DATE_PART%" (
    set "SUFFIX=%SUFFIX:~11%"
    goto clean_suffix
)

:skip_suffix_processing

:: --- �஢�ઠ Progressive JPEG ---
if not defined ISJPG goto after_check_prog
:: �஢��塞, ���� �� _PROGR � SUFFIX - �⮡� �� ��������� ������
set "SUFFIX_PROGR="
echo(%SUFFIX%| findstr /i "_PROGR$" >nul
if not errorlevel 1 set "SUFFIX_PROGR=1"
if defined SUFFIX_PROGR goto after_check_prog
set "PJPG=0"
"%EXV%" -pS "%FN%" | find "SOF2" >nul
if not errorlevel 1 set "PJPG=1"
if %PJPG% equ 1 (
    set "SUFFIX_PROGR=1"
    set "SUFFIX=%SUFFIX%_PROGR"
    set /a CNTP+=1
)
:after_check_prog

:: --- ��ନ�㥬 ����� ��� ---
set "NEWNAME=%YMDHMS%"
if defined SUFFIX set "NEWNAME=%NEWNAME%_%SUFFIX%"
set "NEWNAME=%NEWNAME%%EXT%"

:: --- �᫨ ��� 㦥 �ࠢ��쭮� - �⬥砥� � ��室�� �१ ����� ���� ---
if /i "%NEWNAME%"=="%FN%" (
    echo(%FN% - �ய�饭, ��२��������� �� �ॡ����.
    echo.
    exit /b
)

:: --- �஢�ઠ �� ���䫨�� ��� ---
if not exist "%NEWNAME%" goto do_rename

set "I=1"
:conflict_loop
set "TESTNAME=%YMDHMS%"
if defined SUFFIX set "TESTNAME=%TESTNAME%_%SUFFIX%"
set "TESTNAME=%TESTNAME%_%I%%EXT%"
if exist "%TESTNAME%" (
    set /a I+=1
    goto conflict_loop
)
set "NEWNAME=%TESTNAME%"

:do_rename
ren "%FN%" "%NEWNAME%"
echo(%FN% -^> %NEWNAME%
echo.
set /a CNT+=1
exit /b