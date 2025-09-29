@echo off
set "DO=Media Renamer"
title Froz %DO%
set "VRS=Froz %DO% v29.09.2025"
echo(%VRS%
echo(
if not "%~1"=="" goto exchk
echo(����⭮� ��२��������� 䠩��� �� ��᪥: ����-��-��_������_���.ext
echo(
echo(������ ����� ��� 䠩�� �� �ਯ�.
echo(�᫨ ���� ��㬥�� - �����, ��ࠡ�⠥� �� 䠩�� � ���.
echo(
echo(����⠥� �:
echo(  - EXIF � JPG (DTO) - �ਮ���
echo(  - ��⮩ � ����� 䠩�� (ࠧ�� �ଠ��, �஡���, ࠧ����⥫�)
echo(  - ��⮩ ��������� 䠩�� (DLM)
echo(
echo(�ᮡ������:
echo(  - ������ ��䨪��: IMG_, VID_, DSC_, PIC_
echo(  - �� ��२�����뢠�� 䠩��, 㦥 ᮮ⢥�����騥 ��᪥
echo(  - �� ���䫨��� ��� �������� _1, _2 � �.�.
echo(  - �ਮ���: EXIF ^> ��� ^> DLM
echo(
echo(
pause
exit /b

:: === ����������� � ������ ������ ===
:: �ਮ��� ���: EXIF.DTO > ��� (���_�६�) > ��� (���) + DLM > DLM
:: DTOALL: 䫠� ��᫥ [a] - ��⮬���᪨ ���� EXIF � JPG ��� DTO
:: ���䫨���: �������� _1, _2...

:exchk
set "CMDN=%~n0"
set "EX=%~dp0bin\exiv2.exe"
if exist "%EX%" goto exok
echo(
echo(�訡��: �� ������ "%EX%".
echo(������� exiv2.exe � exiv2.dll � ����� bin �冷� � cmd-䠩���
echo(
pause
exit /b
:exok





:: ������ ���� ࠧ VBS-��� ��� ����� DLM � �⤥��� ��६����, ᯮᮡ�� �� ������騬 �� ������
:: ��ଠ� �뤠� VBS: ���� �� �� �� �� ��
set "DLMV=%temp%\%CMDN%-dlm-%random%%random%.vbs"
>"%DLMV%"  echo(With CreateObject("Scripting.FileSystemObject")
>>"%DLMV%" echo(Set f=.GetFile(WScript.Arguments.Item(0)):dt=f.DateLastModified
>>"%DLMV%" echo(Y=Year(dt):M=Right("0"^&Month(dt),2):D=Right("0"^&Day(dt),2)
>>"%DLMV%" echo(H=Right("0"^&Hour(dt),2):N=Right("0"^&Minute(dt),2):S=Right("0"^&Second(dt),2)
>>"%DLMV%" echo(WScript.Echo Y^&" "^&M^&" "^&D^&" "^&H^&" "^&N^&" "^&S:End With

:: �������� ����稪�: CNT=��२��������, CNTALL=�ᥣ�, CNTT=EXIF ����ᠭ�
:: DTOALL - 䫠� ������� � ஬ "������� DTO �� �� ��᫥���騥 䠩�� ��� DTO"
set "CNT=0"
set "CNTALL=0"
set "CNTT=0"
set "DTOALL="

:: ��।������ ०��� ࠡ��� - '�����' ��� '䠩��'
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto mode_folder

:: ����� ࠡ���: ���᮪ 䠩���
:: �஢�ઠ ����� ��㬥�⮢ CMD �१ VBS
:: ⠪ ��� � CMD ��� ������᭮�� ᯮᮡ� ������ ��ப� � &)(
:: �஢�ઠ �� "%~1"=="" ��� - ��࠭���� a.Count >= 1, ����� ReDim ������ᥭ
set "CTV=%temp%\%CMDN%-len-%random%%random%.vbs"
set "CTO=%temp%\%CMDN%-out-%random%%random%.txt"
>"%CTV%" echo(Set a=WScript.Arguments.Unnamed:ReDim b(a.Count-1)
>>"%CTV%" echo(For i=0To a.Count-1:b(i)=a(i):Next:WScript.Echo Len(Join(b," "))
cscript //nologo "%CTV%" %* >"%CTO%"
set "ALEN=0"
set /p "ALEN=" <"%CTO%"
del "%CTV%" & del "%CTO%"
if %ALEN% GTR 7500 (
    echo(��������: ᫨誮� ������� �������.
    echo(���� ����� ��⥩ � 䠩��� ����� 7500 ᨬ����� - �������� ����� ������.
    echo(��࠭�祭�� Windows - 8191 ᨬ���, ��⠫쭮� �㤥� ��१���.
    echo(
    echo(������ ����� ����� �⤥���� 䠩���, ��� �������� ���ﬨ. ��室��.
    echo(
    pause
    exit /b
)

set "FLD=%~dp1"
pushd "%FLD%"
echo(��ࠡ�⪠ ᯨ᪠ 䠩���...
echo(

:: ���� ࠡ��� �� 䠩���
:loop
if "%~1"=="" goto done
:: �᫨ �।� 䠩��� �������� ����� - �ய�᪠�� ��
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto next
set "FN=%~nx1"
call :process_file
:next
shift
goto loop

:: ����� ࠡ���: �����
:mode_folder
pushd "%~f1"
echo(��ࠡ�⪠ ����� "%~f1"...
echo(
:: ��ࠡ�⪠ 䠩��� � ����� (����� �।� ��� ���� �� ����� - �� �᪫�砥� dir /a-d)
for /f "delims=" %%i in ('dir /b /a-d') do (
    set "FN=%%i"
    call :process_file    
)
goto done
:: ����ணࠬ�� ������ ���� �� done - ���� CMD �� ������ ��⪨ �� �맮�� �� for /f.
:: === ���������� ��������� ���� ===







:: === ������������ ===
:process_file
:: ���㫥��� ��६�����:
set "BASE="
set "EXT="
set "DTO="
set "Y=" & set "M=" & set "D=" & set "HH=" & set "MM=" & set "SS="
set "NAME_Y=" & set "NAME_M=" & set "NAME_D=" & set "NAME_HH=" & set "NAME_MM=" & set "NAME_SS="
set "Y_DLM=" & set "M_DLM=" & set "D_DLM=" & set "HH_DLM=" & set "MM_DLM=" & set "SS_DLM="
set "JPG_MATCH="
set "DTO_COMP="
set "DTO_DATE="

for %%f in ("%FN%") do (
    set "BASE=%%~nf"
    set "EXT=%%~xf"
)

if "%EXT%"=="" exit /b

set /a CNTALL+=1

:: �ᯮ��㥬 䫠�, �.�. �� �㤥� �㦥� ��� ��᪮�쪮 ࠧ
set "ISJPG="
if /i "%EXT%"==".jpg" set "ISJPG=1"
if /i "%EXT%"==".jpeg" set "ISJPG=1"
if defined ISJPG goto jpg_file
goto choose_date

:jpg_file
:: ��� JPEG �஡㥬 ������� EXIF
:: 1. ��⠥� EXIF.DateTimeOriginal
:: 2. �᫨ ��� - ��� � choose_date
:: 3. �᫨ ���� - �ࠢ������ � ��⮩ �� �����
:: 4. �᫨ �� ᮢ������ - ��२�����뢠��
:: 5. �᫨ ᮢ������ - ��⠢�塞
:: ��⠥��� �ᯮ�짮���� EXIF.DateTimeOriginal ��� �ਮ���� ���筨�
:: ��������� EXIF DTO � ������� exiv2

set "TDTO=%temp%\%CMDN%-dto-%random%%random%.txt"
"%EX%" -q -g Exif.Photo.DateTimeOriginal -Pv "%FN%" >"%TDTO%"
set /p "DTO=" <"%TDTO%"
if exist "%TDTO%" del "%TDTO%"

if not defined DTO goto choose_date

:: ��������� ���� �� EXIF � �⤥��� ��६����
:: DTO ����� �ਮ��� ��� ������ - �᫨ ᮢ������, 䠩� �ய�᪠����
set "Y=%DTO:~0,4%"
set "M=%DTO:~5,2%"
set "D=%DTO:~8,2%"
set "HH=%DTO:~11,2%"
set "MM=%DTO:~14,2%"
set "SS=%DTO:~17,2%"

:: �஢�ઠ ���४⭮�� EXIF-����. �᫨ ��� ��������� - �ᯮ��㥬 DLM
:: ���� EXIF: 0000:00:00, 2023:00:45, 9999:99:99 - ����뢠��, �ᯮ��㥬 ��� ��� DLM
if "%Y%"=="" goto choose_date
if "%M%"=="" goto choose_date
if "%D%"=="" goto choose_date
if %M% LSS 1 goto choose_date
if %M% GTR 12 goto choose_date
if %D% LSS 1 goto choose_date
if %D% GTR 31 goto choose_date
if %HH% GTR 23 goto choose_date
if %MM% GTR 59 goto choose_date
if %SS% GTR 59 goto choose_date

set "DTO_COMP=%Y%-%M%-%D% %HH%:%MM%:%SS%"
set "DTO_DATE=%Y%-%M%-%D%"
call :try_name_date

:: �஢�ઠ: ᮢ������ �� ������ ��� � �६� � EXIF � �ଠ⮬ ��᪨?
call :check_jpg_match full
if defined JPG_MATCH goto file_skip

:: �஢�ઠ: ᮢ������ �� ⮫쪮 ��� (��� �६���) � �ଠ�?
call :check_jpg_match date
if defined JPG_MATCH goto file_skip

:: ��祣� �� ᮢ������ - ���室�� � ��२���������
goto build_name






:try_name_date
:: ��� ��ଠ������ BASE (��䨪��, ��१��, YYYYMMDD_, YYYY-MM-DDHHMMSS) �⫮���� �.
:: �믮������ ������ �᫨ 䠩� �� �ய�饭.
:: "��ଠ������" = �ਢ������ BASE � ������� �ଠ��.
:: "����⪠" = �����祭�� ����/�६��� �� 㦥 ��ଠ����������� BASE.

:: ���㫥��� ��६�����
set "DATE_VALID="
set "TIME_VALID="

:: ����塞 ��䨪�� (ॣ���஭�����ᨬ�) �᫨ ��� ��稭����� �� � ����
if "%BASE:~0,1%" GTR "9" goto do_prefixes
if "%BASE:~0,1%" LSS "0" goto do_prefixes
goto skip_prefixes
:do_prefixes
if /i "%BASE:IMG_=%" NEQ "%BASE%" set "BASE=%BASE:IMG_=%" & goto skip_prefixes
if /i "%BASE:VID_=%" NEQ "%BASE%" set "BASE=%BASE:VID_=%" & goto skip_prefixes
if /i "%BASE:DSC_=%" NEQ "%BASE%" set "BASE=%BASE:DSC_=%" & goto skip_prefixes
if /i "%BASE:PIC_=%" NEQ "%BASE%" set "BASE=%BASE:PIC_=%" & goto skip_prefixes
:skip_prefixes

:: ��⠥��� ������� ���� � �६� �� ����� 䠩��.

:: --- ��ଠ������ 1: YYYYMMDD[ࠧ����⥫�]HHMMSS -> YYYY-MM-DD_HHMMSS ---
:: �ਢ���� ࠧ����⥫� ����� ��⮩ � �६���� � '_', �⮡� ����� ��� ���񦭮 �뤥���� HHMMSS
set "TEST=%BASE:~0,8%"

:: ������ �஢�ઠ: ���� ᨬ��� ������ ���� ��ன, � ��ப� ������ ���� ������ 8
if "%TEST:~7,1%"=="" goto check_yyyymmdd_try
if "%TEST:~0,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~0,1%" LSS "0" goto check_yyyymmdd_try

:: �஢��塞 ��⠫�� ᨬ���� �������쭮 (⮫쪮 ���� ᨬ��� ������ ����)
if "%TEST:~1,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~1,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~2,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~2,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~3,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~3,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~4,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~4,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~5,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~5,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~6,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~6,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~7,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~7,1%" LSS "0" goto check_yyyymmdd_try

:: �᫨ ��᫥ YYYYMMDD ��祣� ��� - �� ��⠥��� ��⠢���� _
set "REST=%BASE:~8%"
if not defined REST goto check_yyyymmdd_try

:: �ய�᪠�� �஡���, _, - � ��砫� REST
set "JUNK=%REST%"
:skip_junk_try
if not defined JUNK goto check_yyyymmdd_try
if "%JUNK:~0,1%"==" " set "JUNK=%JUNK:~1%" & goto skip_junk_try
if "%JUNK:~0,1%"=="_" set "JUNK=%JUNK:~1%" & goto skip_junk_try
if "%JUNK:~0,1%"=="-" set "JUNK=%JUNK:~1%" & goto skip_junk_try

:: �஢��塞, ��稭����� �� ���⮪ � 6 ���
set "HMSCAND=%JUNK:~0,6%"
if "%HMSCAND:~5,1%"=="" goto check_yyyymmdd_try
if "%HMSCAND:~0,1%" GTR "9" goto check_yyyymmdd_try
if "%HMSCAND:~0,1%" LSS "0" goto check_yyyymmdd_try

:: ��� �� - ��⠢�塞 _ ��᫥ YYYYMMDD, �� ��頥� REST �� ��砫��� �஡����/ᨬ�����
set "CLEAN_REST=%REST%"
:clean_rest_junk_try
if not defined CLEAN_REST goto after_date_fix_try
if "%CLEAN_REST:~0,1%"==" " set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk_try
if "%CLEAN_REST:~0,1%"=="_" set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk_try
if "%CLEAN_REST:~0,1%"=="-" set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk_try

:: �८�ࠧ㥬 YYYYMMDD � YYYY-MM-DD � ��⠢�塞 _ ��᫥ ����
set "BASE=%BASE:~0,4%-%BASE:~4,2%-%BASE:~6,2%_%CLEAN_REST%"
goto after_date_fix_try

:: --- ��ଠ������ 2: YYYY-MM-DDHHMMSS (��� ࠧ����⥫�) -> YYYY-MM-DD_HHMMSS ---
:check_yyyymmdd_try
set "TEST=%BASE:~0,10%"
if not defined TEST goto after_date_fix_try
if not "%TEST:~4,1%"=="-" goto after_date_fix_try
if not "%TEST:~7,1%"=="-" goto after_date_fix_try

:: �஢��塞, �� ��᫥ ���� ���� ��� ������ 6 ᨬ�����
if "%BASE:~15,1%"=="" goto after_date_fix_try

:: �஢��塞, �� ���� 6 ᨬ����� ��᫥ ���� - ����
set "TIME_CAND=%BASE:~10,6%"
if "%TIME_CAND:~5,1%"=="" goto after_date_fix_try
if "%TIME_CAND:~0,1%" GTR "9" goto after_date_fix_try
if "%TIME_CAND:~0,1%" LSS "0" goto after_date_fix_try

:: �஢��塞, �� �� �������� �६� (HH:MM:SS)
set "HH_TMP=%TIME_CAND:~0,2%"
set "MM_TMP=%TIME_CAND:~2,2%"
set "SS_TMP=%TIME_CAND:~4,2%"

:: ��室 ���쬥�筮� �訡��: 08 -> 108 %% 100 = 8
set /a HH_CHK=1%HH_TMP% %% 100
set /a MM_CHK=1%MM_TMP% %% 100
set /a SS_CHK=1%SS_TMP% %% 100

if %HH_CHK% GTR 23 goto after_date_fix_try
if %MM_CHK% GTR 59 goto after_date_fix_try
if %SS_CHK% GTR 59 goto after_date_fix_try

:: ��� �� - ��⠢�塞 _ ��᫥ ����
set "BASE=%BASE:~0,10%_%BASE:~10%"
:after_date_fix_try
:: --- �ᯮ����⥫쭠� ��⪠ ��� ���室� �� try_name_date ---
:: �ᯮ������ ⮫쪮 �᫨ BASE �� ������ � ����⪥ 1 ��� 2
:: ��᫥ ��ଠ����樨 � YYYY-MM-DD_... - ��������� ���� � �६�
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
call :check_date_format
:: ����塞 NAME_* �� ���������� ���, ���� ���� �த� "0110"/"no"/"TO"
:: ������� choose_date � ����⠢�� Y=0110 ����� DLM -> ��⮥ ���.
if not defined DATE_VALID (
    set "NAME_Y="
    set "NAME_M="
    set "NAME_D="
    exit /b
)

:: ��� ������� - �஡㥬 ������� �६� �� ����樨 11 (��᫥ YYYY-MM-DD_) ⮫쪮 �᫨ �� ���
set "HMSCAND=%BASE:~11,6%"
if "%HMSCAND:~5,1%"=="" exit /b
if "%HMSCAND:~0,1%" GTR "9" exit /b
if "%HMSCAND:~0,1%" LSS "0" exit /b
call :check_time_format
if not defined TIME_VALID exit /b

:: ��� �� - ��� � �६� �������
set "NAME_HH=%HH%"
set "NAME_MM=%MM%"
set "NAME_SS=%SS%"
exit /b








:check_jpg_match
:: �஢��塞, ᮮ⢥����� �� ��� 䠩�� EXIF-��� � ��᪥ ����-��-��_������ - �᫨ ��, �ய�᪠��
:: %1 = full (�ॡ���� ���+�६� � �����) ��� date (�����筮 ����)
if not defined NAME_Y exit /b
:: �᫨ ०�� �� "full" (�.�. "date") - �ய�᪠�� �஢��� �६���
if /i not "%~1"=="full" goto check_time_skip
:: � ०��� "full" �६� � ����� ��易⥫쭮
if not defined NAME_HH exit /b
:check_time_skip

:: �஢�ઠ �ଠ� ���� � �����: YYYY-MM-DD
set "PART=%FN:~0,10%"

:: �஢��塞 ����� � ࠧ����⥫�
if "%PART:~4,1%" NEQ "-" exit /b
if "%PART:~7,1%" NEQ "-" exit /b

:: ��������� ���
set "Y_PART=%PART:~0,4%"
set "M_PART=%PART:~5,2%"
set "D_PART=%PART:~8,2%"

if "%Y_PART:~0,1%" GTR "9" exit /b
if "%Y_PART:~0,1%" LSS "0" exit /b
if "%M_PART:~0,1%" GTR "9" exit /b
if "%M_PART:~0,1%" LSS "0" exit /b
if "%D_PART:~0,1%" GTR "9" exit /b
if "%D_PART:~0,1%" LSS "0" exit /b

:: �஢�ઠ: ��᫥ ���� - �����ન�����
set "UNDERSCORE=%FN:~10,1%"
if not defined UNDERSCORE exit /b
if not "%UNDERSCORE%"=="_" exit /b

:: �஢�ઠ ᮢ������� ���� � EXIF
set "NAME_DATE=%NAME_Y%-%NAME_M%-%NAME_D%"
if not "%NAME_DATE%"=="%DTO_DATE%" exit /b

:: �᫨ ०�� "⮫쪮 ���" - ᮢ������� �������
if /i "%~1"=="date" set "JPG_MATCH=1" & exit /b

:: ����� "full": �஢��塞 �६�
set "TIME_PART=%FN:~11,6%"
:: �஢��塞 ����� �६��� (������ ���� 6 ᨬ�����)
if "%TIME_PART:~5,1%"=="" exit /b

:: �஢��塞, �� ���� ᨬ��� �६��� - ���
if "%TIME_PART:~0,1%" GTR "9" exit /b
if "%TIME_PART:~0,1%" LSS "0" exit /b

:: �஢�ઠ ᮢ������� ������ ����+�६��� � EXIF
set "NAME_COMP=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"
if not "%NAME_COMP%"=="%DTO_COMP%" exit /b

:: ������ ᮢ�������
set "JPG_MATCH=1"
exit /b







:choose_date
:: ���筨�� �� �ਮ����: ���, DLM
:: �� DTOALL=1: ��⮬���᪨ �����뢠�� EXIF � JPG ��� DTO � �ய�᪠�� ������

:: ��������� ���� � �६� �� �����
call :try_name_date

:: --- DTOALL: 䫠� ��� ��⮬���᪮� ��ࠡ�⪨ ---
:: ��⠭���������� � [a], �� EXIF �����뢠���� ������ � handle_a_choice
:: ����� - �� ��뢠�� :do_write, ⮫쪮 �஢��塞, �㦭� �� �����뢠�� ������
if not defined DTOALL goto check_jpg
:: DTOALL=1: �� ��᫥���騥 JPG ��� DTO ���� ��ࠡ�⠭� ��⮬���᪨ (��᫥ [a])
if not defined ISJPG goto check_jpg
if defined DTO goto check_jpg
:: �᫨ DTOALL=1 � �� JPG ��� DTO - �����뢠�� EXIF � �ᯮ��㥬 DLM
call :do_write
call :load_dlm_vars
goto build_name

:: --- JPG: �蠥�, ��訢��� �� ���짮��⥫� ---
:check_jpg
if not defined ISJPG goto use_name_or_dlm

:: �᫨ �� JPG ��� EXIF � � ������ ��⮩ � ����� - �ᯮ��㥬 ��, �� ��訢��
if not defined DTO goto ask_user
if not defined NAME_Y goto ask_user
if not defined NAME_HH goto ask_user
goto use_name_full

:: --- �᭮���� ������ �롮� ���� (��� ��-JPG � �������� JPG) ---
:use_name_or_dlm
:: �᫨ � ����� ���� ������ ��� � �६� - �ᯮ��㥬 ��
if not defined NAME_Y goto use_dlm
if not defined NAME_HH goto use_name_date_dlm_time
goto use_name_full

:: --- ������ ��� � �६� ������� � ����� 䠩�� - �ᯮ��㥬 �� ---
:: �ਬ��: 2021-07-04_174724.txt - Y=2021, M=07, D=04, HH=17, MM=47, SS=24
:use_name_full
set "Y=%NAME_Y%"
set "M=%NAME_M%"
set "D=%NAME_D%"
set "HH=%NAME_HH%"
set "MM=%NAME_MM%"
set "SS=%NAME_SS%"
goto build_name

:: --- ��� � ����� ����, �� �६��� ��� - ����⠢�塞 �६� �� DLM ---
:: �ਬ��: 2021-07-04_Photo.txt - Y=2021, M=07, D=04, HH=12, MM=34, SS=56 (�� DLM)
:use_name_date_dlm_time
call :get_dlm
set "Y=%NAME_Y%"
set "M=%NAME_M%"
set "D=%NAME_D%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
goto build_name

:: --- �� ����, �� �६��� �� ������� � ����� - �ᯮ��㥬 ����� DLM ---
:: �ਬ��: Photo_001.jpg - ��� �� DateLastModified
:use_dlm
call :load_dlm_vars
goto build_name






:ask_user
:: ��������� DLM ⥪�饣� 䠩�� � �⤥��� ��६����� �१ VBS-��� ᮧ����� � ��砫� ࠡ���
:: ����: ��࠭�஢��� ����㯭���� Y_DLM, HH_DLM � �.�. � ask_user � ��㣨� ������
call :get_dlm

:: --- ��ନ�㥬 ��ப� ��� �⮡ࠦ���� ���짮��⥫� ---
:: ��ਠ���:
:: 1. ������ ��� � �६� � ����� - ���� ��� �� �����
:: 2. ���쪮 ��� � ����� - ��� �� �����, �६� �� DLM
:: 3. ��祣� �� �����祭� - ⮫쪮 DLM
:: ��६����� YMDHMS_NAME �ᯮ������ ������ ��� �뢮��, �� ����� �� ��२���������
echo(--- ��� EXIF.DateTimeOriginal (DTO) � "%FN%" ---
echo(
set "YMDHMS_NAME="

:: �� ����, �� �६��� �� �����祭� �� ����� - �����뢠�� DLM
if not defined NAME_Y (
    set "YMDHMS_NAME=%Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%"
    goto show_user
)

:: --- ��� � ����� ����, �� �६��� ��� - �����뢠��: ��� �� �����, �६� �� DLM
if not defined NAME_HH (
    set "YMDHMS_NAME=%NAME_Y%-%NAME_M%-%NAME_D% %HH_DLM%:%MM_DLM%:%SS_DLM%"
    goto show_user
)

:: ���� � ���, � �६� � ����� - �����뢠�� ��
set "YMDHMS_NAME=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"

:: YMDHMS_NAME - ⮫쪮 ��� �⮡ࠦ����, �� ����� �� ������
:show_user
echo(�।�������� ���-�६�: %YMDHMS_NAME%
echo(��� ��������� 䠩�� (DLM): %Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%
echo(
echo([a] - ������� �।�������� � EXIF ��� ��� JPG ��� DTO
echo([w] - ������� �।�������� � EXIF
echo([m] - ����� DTO ������
echo(�� ��㣠� ������ - �ய�����
set /p "USRCHOICE=�롮�: "

if /i "%USRCHOICE%"=="a" goto handle_a_choice
if /i "%USRCHOICE%"=="w" (
    call :do_write
    goto build_name
)
if /i "%USRCHOICE%"=="m" goto manual_input_start
echo(�⬥���� ������ � EXIF.
goto file_skip

:manual_input_start
:: ��筮� ���� ���짮��⥫�
set "MANUAL="
echo(
echo(������ ���� ����-��-�� ��:��:�� ��� [q] ��� �⬥��
set /p "MANUAL=���: "
if /i not "%MANUAL%"=="q" goto chk_man
echo(�⬥�� ��筮� ����.
goto file_skip

:chk_man
:: �஢�ઠ �ଠ� �१ �६���� 䠩�
set "MAN=%temp%\%CMDN%-man-%random%%random%.tmp"
echo(%MANUAL%>"%MAN%"
:: �� ���뢠�� ��ப� findstr �� errorlevel
findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]$" "%MAN%" >nul
if %ERRORLEVEL% EQU 1 (
    echo(
    echo(������ �ଠ�. �ਬ��: 2023-12-31 23:59:59
    echo(
    goto manual_input_start
)
if exist "%MAN%" del "%MAN%"

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

:: ���� � ᥪ㭤� - 㤠�塞 �஡���: " 8" -> "8" - �⮡� ��ࠡ���� ���� ��� ������ �㫥�
set "H_TMP=%H_TMP: =%"
set "S_TMP=%S_TMP: =%"

:: �஢��塞 - �᫨ ��ன ᨬ��� ��������� - �����, �᫮ �������筮�
:: ����⠭�������� ����騩 ���� ��� ���������� �ᮢ: "8" -> "08", "12" -> "12"
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
:: �� �஢��塞 ��᮪��� ���� ��� ��� � ����� - ᫨誮� ᫮��� ��� CMD
:: �����筮 �஢�ન ����������: 1-31 ����, 1-12 �����
if %M% LSS 1 set "DT_VALID=0"
if %M% GTR 12 set "DT_VALID=0"
if %D% LSS 1 set "DT_VALID=0"
if %D% GTR 31 set "DT_VALID=0"
if %HH% GTR 23 set "DT_VALID=0"
if %MM% GTR 59 set "DT_VALID=0"
if %SS% GTR 59 set "DT_VALID=0"

:: --- �᫨ ��� �����४⭠ - �����頥��� � ����� ---
:: ���짮��⥫� ����� ��ࠢ��� �訡��
if %DT_VALID% EQU 0 (
    echo(�������⨬� ���祭�� ����/�६���.
    echo(
    goto manual_input_start
)
:: ���� �ᯥ襭 � �஢�७ - ���室�� � ����� EXIF � ��२��������� 䠩��
call :do_write
goto build_name

:: --- ��ࠡ�⪠ �-�롮� [a] ---
:handle_a_choice
:: ��᫥ [a] - DTOALL=1, � �� ��᫥���騥 JPG ��� DTO ���� ��ࠡ�⠭� ��⮬���᪨
set "DTOALL=1"
if not defined ISJPG goto skip_a_write
if defined DTO goto skip_a_write
call :do_write
:skip_a_write
call :load_dlm_vars
goto build_name








:do_write
echo(�����뢠�� DateTimeOriginal=%Y%-%M%-%D% %HH%:%MM%:%SS% � %FN%
"%EX%" -M"set Exif.Photo.DateTimeOriginal %Y%-%M%-%D% %HH%:%MM%:%SS%" "%FN%"
set /a CNTT+=1
exit /b







:check_date_format
:: �஢��塞, �� ���� ᨬ���� - ���� (�������쭠� ����)
if "%NAME_Y:~0,1%" GTR "9" exit /b
if "%NAME_Y:~0,1%" LSS "0" exit /b
if "%NAME_M:~0,1%" GTR "9" exit /b
if "%NAME_M:~0,1%" LSS "0" exit /b
if "%NAME_D:~0,1%" GTR "9" exit /b
if "%NAME_D:~0,1%" LSS "0" exit /b

set "Y_CHK="
set "M_CHK="
set "D_CHK="

:: ��室 �訡�� ���쬥���� �ᥫ: 08 -> 10008 %% 10000 = 8
set /a Y_CHK=1%NAME_Y% %% 10000
set /a M_CHK=1%NAME_M% %% 100
set /a D_CHK=1%NAME_D% %% 100

:: ��������� � ���ᨬ���� ���
if %Y_CHK% LSS 1900 exit /b
if %Y_CHK% GTR 2100 exit /b
if %M_CHK% LSS 1 exit /b
if %M_CHK% GTR 12 exit /b
if %D_CHK% LSS 1 exit /b
if %D_CHK% GTR 31 exit /b

set "DATE_VALID=1"
exit /b






:check_time_format
:: �����祭�� �ᮢ/�����/ᥪ㭤 �� 6-ᨬ���쭮� ��ப� (���ਬ��, 081234)
:: �஢��塞 ����� - ������ ���� ������ 6 ᨬ�����
if "%HMSCAND:~5,1%"=="" exit /b

:: �������쭠� �஢�ઠ - ���� ᨬ��� ������ ���� ������ ���� ��ன
if "%HMSCAND:~0,1%" GTR "9" exit /b
if "%HMSCAND:~0,1%" LSS "0" exit /b
if "%HMSCAND:~2,1%" GTR "9" exit /b
if "%HMSCAND:~2,1%" LSS "0" exit /b
if "%HMSCAND:~4,1%" GTR "9" exit /b
if "%HMSCAND:~4,1%" LSS "0" exit /b

:: ��������� HH, MM, SS � ��室�� ������ �㫥�
set "HH_CHK="
set "MM_CHK="
set "SS_CHK="

:: ��室 �訡�� ���쬥���� �ᥫ - 08 -> 10008 %% 100 = 8
:: �஡���� - set /a �� �ਭ����� "08" ��� �᫮ (���� 08 - �訡�� � ���쬥�筮� ��⥬�)
:: ��襭�� - �ਯ��뢠�� 100 ᯥ।� - "10008", ���� mod 100 (����� �� 100) - 8
:: ��� ��室�� ����騥 �㫨 ��� if � ��� �訡��. �ਬ�� - %HMSCAND:~0,2% = "08" - 10008 %% 100 = 8
set /a HH_CHK=100%HMSCAND:~0,2% %% 100
set /a MM_CHK=100%HMSCAND:~2,2% %% 100
set /a SS_CHK=100%HMSCAND:~4,2% %% 100

:: �஢��塞 ���������
if %HH_CHK% GTR 23 exit /b
if %MM_CHK% GTR 59 exit /b
if %SS_CHK% GTR 59 exit /b

:: ��ଠ��㥬 � ����騬� ��ﬨ
set "HH=%HH_CHK%"
if %HH_CHK% LSS 10 set "HH=0%HH_CHK%"
set "MM=%MM_CHK%"
if %MM_CHK% LSS 10 set "MM=0%MM_CHK%"
set "SS=%SS_CHK%"
if %SS_CHK% LSS 10 set "SS=0%SS_CHK%"

set "TIME_VALID=1"
exit /b






:build_name
:: --- ��ନ஢���� YMDHMS ---
:: � �⮬� ������� Y, M, D, HH, MM, SS ��࠭�஢���� �������:
::  - �� EXIF (� �஢�મ� ����������)
::  - �� ����� (�१ check_date_format � check_time_format )
::  - �� DLM (�१ VBS)
set "YMDHMS=%Y%-%M%-%D%_%HH%%MM%%SS%"

:: �������� ��室��� "�㡫��" - ��� + 1 ᨬ��� (�� ࠧ����⥫�), ��⥬ �६�
if "%BASE:~0,10%"=="%Y%-%M%-%D%" set "BASE=%BASE:~11%"
if "%BASE:~0,6%"=="%HH%%MM%%SS%" set "BASE=%BASE:~6%"

:: ��ࠡ�⪠ ��ࢮ�� ᨬ���� BASE: ⮫쪮 ���� ��⪠ �ࠡ��뢠��
if "%BASE:~0,1%"=="_" goto plain_base
if "%BASE:~0,1%"==" " set "BASE=_%BASE:~1%" & goto plain_base
if "%BASE:~0,1%"=="-" set "BASE=_%BASE:~1%" & goto plain_base
:: �� 㬮�砭�� - ������塞 _ ����� ��⮩ � ������
set "NAMEBASE=%YMDHMS%_%BASE%"
goto after_base
:plain_base
set "NAMEBASE=%YMDHMS%%BASE%"
:after_base

:: �᫨ ��� �� ���������� - �ய�᪠��
set "FINALNAME=%NAMEBASE%%EXT%"
if /i "%FINALNAME%"=="%FN%" goto file_skip
if not exist "%FINALNAME%" goto do_rename

:: �᫨ ��� ����� - �饬 _1, _2 � �.�. �� ᢮�������
set "I=1"
:conflict_loop
set "FINALNAME=%NAMEBASE%_%I%%EXT%"
if exist "%FINALNAME%" (
    set /a I+=1
    goto conflict_loop
)

:do_rename
ren "%FN%" "%FINALNAME%"
echo(%FN% -^> %FINALNAME%
set /a CNT+=1
exit /b






:load_dlm_vars
call :get_dlm
set "Y=%Y_DLM%"
set "M=%M_DLM%"
set "D=%D_DLM%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
exit /b






:get_dlm
:: �����祭�� DateLastModified �१ VBS, ������ᨬ� �� ������ ��
:: �஢��塞 ����� �� 㦥 ��� - �� ���� �� ����୮�� �맮�� VBS
if defined Y_DLM exit /b
for /f "tokens=1-6" %%a in ('cscript //nologo "%DLMV%" "%FN%"') do (
    set "Y_DLM=%%a"
    set "M_DLM=%%b"
    set "D_DLM=%%c"
    set "HH_DLM=%%d"
    set "MM_DLM=%%e"
    set "SS_DLM=%%f"
)
exit /b






:file_skip
:: ������ �窠 ��室� ��� ��� ��砥� �ய�᪠ 䠩��
echo(%FN% - �ய�饭, ��२��������� �� �ॡ����.
exit /b
:: === ���������� ����� ����������� ===






:: === ����������� ��������� ���� ===
:done
:: ��⪠ done �᭮����� ���� ��६�饭� � �����, �⮡� CMD "㢨���" �� ��⪨ ����ணࠬ� �� �� �맮��
:: �� ��࠭�祭�� �������� CMD - ��⪨ ��� �맮�� ������ ���� ������ �� �� �맮��.
popd
if exist "%DLMV%" del "%DLMV%"
set "TXT_ALL="
set "TXT_DTO="
echo(
echo(--- ��⮢� ---
if %CNT% gtr 0 set "TXT_ALL=��२�������� 䠩���: %CNT% �� %CNTALL%"
if %CNTT% gtr 0 set "TXT_DTO=��������� EXIF-��� � 䠩��: %CNTT%"
if %CNT% gtr 0 echo(%TXT_ALL%
if %CNTT% gtr 0 echo(%TXT_DTO%
set "HF=%temp%\%CMDN%-hlp-%random%%random%.txt"
set "VB=%temp%\%CMDN%-hlp-%random%%random%.vbs"
>"%HF%" echo(%VRS%
>>"%HF%" echo(%CMDN% �����稫 ࠡ���.
>>"%HF%" echo(
>>"%HF%" echo(%TXT_ALL%
>>"%HF%" echo(
>>"%HF%" echo(%TXT_DTO%
>"%VB%" echo(With CreateObject("ADODB.Stream"):.Type=2:.Charset="cp866"
>>"%VB%" echo(.Open:.LoadFromFile"%HF%":MsgBox .ReadText,,"%CMDN%":.Close:End With
cscript //nologo "%VB%"
del "%VB%" & del "%HF%"
pause
exit /b
