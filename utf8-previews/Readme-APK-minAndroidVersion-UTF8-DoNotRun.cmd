@echo off
set "IN=.apk"
set "DO=APK min version extract"
title %DO%
set "VRS=Froz %DO% v10.09.2025"
echo(%VRS%
echo(
set "CMDN=%~n0"
set "EX=%~dp0bin\aapt2_64.exe"
if not exist "%EX%" echo("%EX%" не найден, выходим.& echo(& pause & exit /b
if "%~1"=="" (
    echo(Из указанных %IN% извлекается минимальная версия Android.
    echo(В папке с %IN%-файлами будет создан файл %CMDN%-log.txt.
    echo(Перетащите %IN%-файлы на скрипт.
    echo(
    pause
    exit /b
)
:: Эти set нужно задать до входа в loop
set "TMPF=%temp%\aapt_%random%%random%.tmp"
set "DST=%~dp1%CMDN%-log.txt"
set "HAS_DST="

:loop
set "FILE=%~1"
set "NAME=%~nx1"
if "%~1"=="" goto finish
if not exist "%FILE%" (
    echo("%NAME%" - отсутствует, пропущен.
    echo(
    shift
    goto loop
)
if /i not "%~x1"=="%IN%" (
    echo("%NAME%" - неподдерживаемый формат файла, пропущен.
    echo(
    shift
    goto loop
)
:: Если мы здесь, значит найден APK-Файл для обработки
:: Если файл %DST% уже существует, то перезаписываем его только если был обработан хотя бы один APK
:: HAS_DST = 1 означает, что заголовок уже записан (и лог перезаписан)
:: Это предотвращает повторную перезапись заголовка и защищает старый лог, если ни один файл не будет обработан
if defined HAS_DST goto go
:: Начинаем новый лог с заголовком и поднимаем флаг
>"%DST%" echo(%date%, %time%
>>"%DST%" echo(APK filename, min. Android version, APK CPU architectures:
>>"%DST%" echo(from 'minSDKversion' and 'native-code'
>>"%DST%" echo(----------------------------------------------------------
>>"%DST%" echo(
set "HAS_DST=1"

:go
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
>>"%DST%" echo("%NAME%"
>>"%DST%" echo(Min. android version: %ANDR% (SDK=%SDK%).
>>"%DST%" echo(CPU_arch: %ARCH%.
>>"%DST%" echo(

shift
goto loop

:finish
if exist "%TMPF%" del "%TMPF%"
if not defined HAS_DST (
    echo(
    echo(Ни одного APK-файла не обработано.
    echo(Лог не создан, старый файл лога, если он был ранее - не изменён.
    echo(
    pause
    exit /b
)
set "EV=%temp%\%CMDN%_%random%%random%.vbs"
set "EMSG=Создан файл %DST%"
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"