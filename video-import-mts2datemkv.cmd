@echo off
set "DSTFLD=D:\��⪨\!ࠧ�����\�����"

set "DO=Import .MTS to .MKV"
title %DO%
set "VRS=Froz %DO% v21.08.2025"
echo(%VRS%
echo(
set "IN=.mts"
set "OUT=.mkv"
set "FLD=PRIVATE\AVCHD\BDMV\STREAM"
set "FLD2DEL=PRIVATE"
set "EX=%~dp0bin\ffmpeg.exe"
if not exist "%EX%" (
    echo(%EX% �� ������, ��室��.
    echo(
    pause
    exit /b
)

:: ��⮮�।������ ��񬭮�� ���⥫� (DriveType=1 + Ready=True)
set "USBDIR="
set "TV=%temp%\%~n0_d_%random%%random%.vbs"
>"%TV%" echo(With CreateObject("Scripting.FileSystemObject"):For Each D In .Drives
>>"%TV%" echo(If D.DriveType=1 And D.IsReady Then Wscript.Echo D.DriveLetter
>>"%TV%" echo(Next:End With
for /f "delims=" %%D in ('cscript //nologo "%TV%"') do (
    if not defined USBDIR (
        set "DL=%%D:"
        call :chkusb
    )
)
del "%TV%"
if not defined USBDIR (
    echo(�� ������ ���� ���⥫� � ������ %FLD%
    echo(
    pause
    goto help
)
if not exist "%USBDIR%\*%IN%" (
    echo(� %USBDIR% ��� 䠩��� %IN%, ��室��.
    echo(
    pause
    goto help
)
for %%F in ("%USBDIR%\*%IN%") do (
    set "FN=%%~nF"
    set "FNX=%%~nxF"
    set "FNF=%%~fF"
    call :go
)
rd /s /q "%UD2DEL%"
set "EV=%temp%\%~nx0-end-%random%%random%.vbs"
set "EMSG=�� 䠩�� ��ࠡ�⠭�. �஢���� ���४⭮��� �������樨 � 㤠��� 䠩�� %IN%."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%~n0"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
pause
exit /b

:help
set "HF=%temp%\%~n0-hlp-%random%%random%.txt"
set "VB=%temp%\%~n0-hlp-%random%%random%.vbs"
>"%HF%" echo %VRS%
>>"%HF%" echo(
>>"%HF%" echo ��७�� .mts � �⮠����� � ६�� � .mkv.
>>"%HF%" echo(
>>"%HF%" echo �����⮢��:
>>"%HF%" echo 1. ������ �ਯ� ⥪�⮢� ।���஬ � �����প�� ������� ��࠭���
>>"%HF%" echo    OEM866, ���ਬ�� Far Manager, Total Commander, Notepad++
>>"%HF%" echo 2. ��筨�� ���� �����祭�� DSTFLD: %DSTFLD%
>>"%HF%" echo(
>>"%HF%" echo �� ������:
>>"%HF%" echo 1. ��� ���� ���⥫� � ������ %FLD%
>>"%HF%" echo 2. ��७��� .mts �
>>"%HF%" echo    %DSTFLD%
>>"%HF%" echo 3. ��२�����뢠�� �� ��᪥ ����-��-��_������_���.
>>"%HF%" echo 4. ������ ����� %FLD2DEL% � ���⥫�,
>>"%HF%" echo    �⮡� �� �⮠����� �� �뫮 �訡�� ��ᬮ�� "䠩� �� ������".
>>"%HF%" echo 5. ������ .mts � .mkv.
>"%VB%" echo(With CreateObject("ADODB.Stream"):.Type=2:.Charset="cp866"
>>"%VB%" echo(.Open:.LoadFromFile"%HF%":MsgBox .ReadText,,"%~n0":.Close:End With
cscript //nologo "%VB%"
del "%VB%" & del "%HF%"
exit /b
:: === ����砭�� �᭮����� ���� ===


:: === ����ணࠬ�� ===
:chkusb
if exist "%DL%\%FLD%" (
    set "USBDIR=%DL%\%FLD%"
    set "UD2DEL=%DL%\%FLD2DEL%"
)
exit /b

:go
:: ��������� DateLastModified
set "TV=%temp%\dlm-%random%%random%.vbs"
>"%TV%" echo(Wscript.Echo CreateObject("Scripting.FileSystemObject").GetFile(WScript.Arguments.Item(0)).DateLastModified
for /f "delims=" %%t in ('cscript //nologo "%TV%" "%FNF%"') do set "DT=%%t"
del "%TV%"
set "D=%DT:~0,2%"
set "M=%DT:~3,2%"
set "Y=%DT:~6,4%"
set "HH=%DT:~11,2%"
set "MM=%DT:~14,2%"
set "SS=%DT:~17,2%"
:: ���४�� �������筮�� �� (���ਬ��, "8:08:08")
if not "%HH%"=="%HH::=%" (
    set "HH=0%HH:~0,1%"
    set "MM=%DT:~13,2%"
    set "SS=%DT:~16,2%"
)
set "DSTNAMEIN=%Y%-%M%-%D%_%HH%%MM%%SS%_%FNX%"
set "DSTNAME=%Y%-%M%-%D%_%HH%%MM%%SS%_%FN%%OUT%"
echo(���������: "%FNX%" -^> "%DSTNAME%"...
if not exist "%DSTFLD%" md "%DSTFLD%"
move "%FNF%" "%DSTFLD%\%DSTNAMEIN%" >nul
"%EX%" -hide_banner -i "%DSTFLD%\%DSTNAMEIN%" -c copy "%DSTFLD%\%DSTNAME%"
echo(
exit /b
