@echo off
set "IN=.apk"
set "DO=APK min version extract"
title %DO%
set "VRS=Froz %DO% v15.08.2025"
echo(%VRS%
echo.

set "EX=%~dp0bin\aapt2_64.exe"
if not exist "%EX%" (
    echo(%EX% �� ������, ��室��.
    echo.
    pause
    exit /b
)

if "%~1"=="" (
    echo(�� 㪠������ %IN% ����������� �������쭠� ����� Android.
    echo(� ����� � %IN%-䠩���� �㤥� ᮧ��� 䠩� %~n0-log.txt.
    echo(������ %IN%-䠩�� �� �ਯ�.
    echo.
    pause
    exit /b
)

set "TMPF=%temp%\aapt_%random%.tmp"
set "DST=%~dp1%~n0-log.txt"
set "HAS_DST="

:loop
set "FILE=%~1"
set "NAME=%~nx1"

if "%~1"=="" goto finish

if not exist "%FILE%" (
    echo("%NAME%" - ���������, �ய�饭.
    echo.
    shift
    goto loop
)

if /i not "%~x1"=="%IN%" (
    echo("%NAME%" - �������ন����� �ଠ� 䠩��, �ய�饭.
    echo.
    shift
    goto loop
)
:: �᫨ �� �����, ����� ������ APK-���� ��� ��ࠡ�⪨
:: �᫨ 䠩� %DST% 㦥 �������, � ��१����뢠�� ��� ⮫쪮 �᫨ �� ��ࠡ�⠭ ��� �� ���� APK
:: HAS_DST = 1 ����砥�, �� ��������� 㦥 ����ᠭ (� ��� ��१���ᠭ)
:: �� �।���頥� ������� ������ ��������� � ���頥� ���� ���, �᫨ �� ���� 䠩� �� �㤥� ��ࠡ�⠭
if not defined HAS_DST (
    echo %date%, %time%>"%DST%"
    echo APK filename, min. Android version, APK CPU architectures:>>"%DST%"
    echo from 'minSDKversion' and 'native-code'>>"%DST%"
    echo ---------------------------------------------------------->>"%DST%"
    echo.>>"%DST%"
    set "HAS_DST=1"
)

echo(��ࠡ�⪠ "%NAME%" ...

"%EX%" dump badging "%FILE%">"%TMPF%"

set "SDKLINE="
set "SDKF=%TMPF%.sdk"
findstr /c:"minSdkVersion" "%TMPF%" >"%SDKF%"
set /p "SDKLINE=" <"%SDKF%"
del "%SDKF%"

if not defined SDKLINE (
    set "SDK=??"
    set "ANDR=not found"
    goto after_sdk
)

:: ��१��� minSdkVersion:'xxx' -> xxx
set "SDK=%SDKLINE:*minSdkVersion:'=%"
set "SDK=%SDK:'=%"
set "SDK=%SDK:~0,2%"

:after_sdk

:: ��।������ Android-���ᨨ �� SDK
set "ANDR="
if "%SDK%"=="14" set "ANDR=<4.0.3"
if "%SDK%"=="15" set "ANDR=4.0.3"
if "%SDK%"=="16" set "ANDR=4.1"
if "%SDK%"=="17" set "ANDR=4.2"
if "%SDK%"=="18" set "ANDR=4.3"
if "%SDK%"=="19" set "ANDR=4.4"
if "%SDK%"=="21" set "ANDR=5.0"
if "%SDK%"=="22" set "ANDR=5.1"
if "%SDK:~0,1%"=="2" if %SDK% GTR 22 set "ANDR=6.0+"
if "%SDK:~0,1%"=="3" set "ANDR=6.0+"
if not defined ANDR set "ANDR=unknown (SDK=%SDK%)"

:: �����祭�� native-code
set "ARCHF=%TMPF%.arch"
findstr /c:"native-code" "%TMPF%" >"%ARCHF%"
set "ARCH="
set /p "ARCH=" <"%ARCHF%"
del "%ARCHF%"

if not defined ARCH (
    set "ARCH='native-code' key is missing !"
    goto after_arch
)
set "ARCH=%ARCH:*native-code: =%"
:after_arch
echo("%NAME%">>"%DST%"
echo(Min. android version: %ANDR% (SDK=%SDK%).>>"%DST%"
echo(CPU_arch: %ARCH%.>>"%DST%"
echo.>>"%DST%"

shift
goto loop

:finish
if exist "%TMPF%" del "%TMPF%"
if not defined HAS_DST (
    echo.
    echo �� ������ APK-䠩�� �� ��ࠡ�⠭�.
    echo ��� �� ᮧ���, ���� 䠩� �� ������.
    goto e
)
set "EV=%temp%\%~n0_%random%.vbs"
set "EMSG=������ 䠩� '%~nx0' �����稫 ࠡ���."
chcp 1251 >nul
echo MsgBox "%EMSG%",,"%~nx0">"%EV%"
chcp 866 >nul
"%EV%" & del "%EV%"
echo.
echo ��⮢�. ������ 䠩�:
echo("%DST%"
:e
pause