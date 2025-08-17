@echo off
set "IN=.apk"
set "DO=APK min version extract"
title %DO%
set "VRS=Froz %DO% v15.08.2025"
echo(%VRS%
echo.

set "EX=%~dp0bin\aapt2_64.exe"
if not exist "%EX%" (
    echo(%EX% не найден, выходим.
    echo.
    pause
    exit /b
)

if "%~1"=="" (
    echo(Из указанных %IN% извлекается минимальная версия Android.
    echo(В папке с %IN%-файлами будет создан файл %~n0-log.txt.
    echo(Перетащите %IN%-файлы на скрипт.
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
    echo("%NAME%" - отсутствует, пропущен.
    echo.
    shift
    goto loop
)

if /i not "%~x1"=="%IN%" (
    echo("%NAME%" - неподдерживаемый формат файла, пропущен.
    echo.
    shift
    goto loop
)
:: Если мы здесь, значит найден APK-Файл для обработки
:: Если файл %DST% уже существует, то перезаписываем его только если был обработан хотя бы один APK
:: HAS_DST = 1 означает, что заголовок уже записан (и лог перезаписан)
:: Это предотвращает повторную запись заголовка и защищает старый лог, если ни один файл не будет обработан
if not defined HAS_DST (
    echo %date%, %time%>"%DST%"
    echo APK filename, min. Android version, APK CPU architectures:>>"%DST%"
    echo from 'minSDKversion' and 'native-code'>>"%DST%"
    echo ---------------------------------------------------------->>"%DST%"
    echo.>>"%DST%"
    set "HAS_DST=1"
)

echo(Обработка "%NAME%" ...

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

:: Обрезаем minSdkVersion:'xxx' -> xxx
set "SDK=%SDKLINE:*minSdkVersion:'=%"
set "SDK=%SDK:'=%"
set "SDK=%SDK:~0,2%"

:after_sdk

:: Определение Android-версии по SDK
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

:: Извлечение native-code
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
    echo Ни одного APK-файла не обработано.
    echo Лог не создан, старый файл не изменён.
    goto e
)
set "EV=%temp%\%~n0_%random%.vbs"
set "EMSG=Пакетный файл '%~nx0' закончил работу."
chcp 1251 >nul
echo MsgBox "%EMSG%",,"%~nx0">"%EV%"
chcp 866 >nul
"%EV%" & del "%EV%"
echo.
echo Готово. Создан файл:
echo("%DST%"
:e
pause