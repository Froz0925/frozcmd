@echo off
set "DO=JPG-Progressive marker"
title Froz %DO%
set "VRS=Froz %DO% v29.09.2025"
echo(%VRS%
echo(
if not "%~1"=="" goto exchk
echo(�஢�ઠ JPG �� ०�� Progressive (SOF2 � ���������)
echo(� ���������� � ����� ⠪�� 䠩��� ���䨪� _PROGR.
echo(
echo(Progressive-JPG � ��᮪�� ࠧ�襭�� �������� ���뢠���� �� ����.
echo(��⪠ �������� ����� ����⭮ �����࠭��� �� � ������ ०��.
echo(���ਬ�� � ������� Faststone Image Viewer.
echo(
echo(������ ����� ��� 䠩�� �� �ਯ�.
echo(��ࠡ��뢠���� ⮫쪮 .jpg � .jpeg.
echo(
pause
exit /b

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

set "CNTALL=0"
set "CNTP=0"
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto mode_folder

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
    echo(���� ����� ��⥩ � 䠩��� ����� 7500 ᨬ�����.
    echo(������ ����� ��� �������� ���ﬨ. ��室��.
    echo(
    pause
    exit /b
)

set "FLD=%~dp1"
pushd "%FLD%"
echo(��ࠡ�⪠ ᯨ᪠ JPG-䠩���...
echo(

:loop
if "%~1"=="" goto done
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto next
set "FN=%~nx1"
call :go
:next
shift
goto loop

:mode_folder
pushd "%~f1"
echo(��ࠡ�⪠ ����� "%~f1"...
echo(
:: ��ࠡ�⪠ 䠩��� � ����� (����� �।� ��� ���� 㦥 �� ����� - �� 䨫����� dir /a-d)
for /f "delims=" %%i in ('dir /b /a-d') do (
    set "FN=%%i"
    call :go
)
goto done

:go
for %%f in ("%FN%") do (
    set "BASE=%%~nf"
    set "EXT=%%~xf"
)
if "%EXT%"=="" exit /b
if /i "%EXT%"==".jpg" goto jpg_ok
if /i "%EXT%"==".jpeg" goto jpg_ok
exit /b

:jpg_ok
set /a CNTALL+=1
:: �� ��ࠡ��뢠��, �᫨ 㦥 ���� _PROGR
if /i not "%BASE:~-6%"=="_PROGR" goto no_progr
echo(%FN% - �ய�饭 - _PROGR 㦥 ����
echo(
exit /b
:no_progr

:: �஢��塞 SOF2 �१ exiv2
"%EX%" -pS "%FN%" | find "SOF2" >nul
if %ERRORLEVEL% NEQ 0 exit /b

:: �஡㥬 ������� ��� + _PROGR
set "NEWNAME=%BASE%_PROGR%EXT%"
if not exist "%NEWNAME%" goto do_rename

:: �஢�ઠ ���䫨�� ���
set "I=1"
:conflict_loop
set "NEWNAME=%BASE%_%I%_PROGR%EXT%"
if exist "%NEWNAME%" (
    set /a I+=1
    goto conflict_loop
)

:do_rename
ren "%FN%" "%NEWNAME%"
echo(%FN% -^> %NEWNAME%
echo(
set /a CNTP+=1
exit /b

:done
popd
set "TXT_ALL="
set "TXT_PROGR="
echo(
echo(--- ��⮢� ---
if %CNTALL% GTR 0 set "TXT_ALL=��ࠡ�⠭� JPG: %CNTALL%"
if %CNTP% GTR 0 set "TXT_PROGR=����祭� ��� PROGR: %CNTP%"
if %CNTALL% GTR 0 echo(%TXT_ALL%
if %CNTP% GTR 0 echo(%TXT_PROGR%
set "HF=%temp%\%CMDN%-hlp-%random%%random%.txt"
set "VB=%temp%\%CMDN%-hlp-%random%%random%.vbs"
>"%HF%" echo(%VRS%
>>"%HF%" echo(%CMDN% �����稫 ࠡ���.
>>"%HF%" echo(
>>"%HF%" echo(%TXT_ALL%
>>"%HF%" echo(%TXT_PROGR%
>"%VB%" echo(With CreateObject("ADODB.Stream"):.Type=2:.Charset="cp866"
>>"%VB%" echo(.Open:.LoadFromFile"%HF%":MsgBox .ReadText,,"%CMDN%":.Close:End With
cscript //nologo "%VB%"
del "%VB%" & del "%HF%"
pause
exit /b