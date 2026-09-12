@echo off
set "DO=JPG-Progressive marker"
title Froz %DO%
set "VRS=Froz %DO% v01.08.2026"
echo(%VRS%
echo(
set "VCR=%~dp0bin\VC_redist.x64.exe"
if exist "%SystemRoot%\System32\vcruntime140_1.dll" goto vcok
if not exist "%VCR%" (
    echo("%VCR%" не найден, выходим.
    echo(Ссылка для скачивания - в readme.txt.
    echo(& pause & exit /b
)
echo(Компоненты Visual C++ не найдены.
echo(Начата установка "%VCR%"...
echo(Потребуется подтверждение администратором в окне повышения прав!
echo(
rem Запуск установки в тихом режиме с ожиданием завершения
start /wait "" "%VCR%" /q /norestart
rem Повторная проверка после установки
if not exist "%SystemRoot%\System32\vcruntime140_1.dll" (
    echo(Установка "%VCR%" завершилась с ошибкой или требует перезагрузки, выходим.
    echo(& pause & exit /b
)
echo(Компоненты Visual C++ успешно установлены.
echo(
:vcok
set "EX=%~dp0bin\exiv2.exe"
if exist "%EX%" goto exok
echo(
echo(Ошибка: Не найден "%EX%".
echo(Положите exiv2.exe и exiv2.dll в папку bin рядом с cmd-файлом
echo(
pause
exit /b
:exok
if not "%~1"=="" goto work
echo(Проверка JPG на режим Progressive (SOF2 в заголовке)
echo(и добавление к имени таких файлов суффикса _PROGR.
echo(
echo(Progressive-JPG в высоком разрешении медленно открываются во вьюверах.
echo(Метка помогает позже пакетно пересохранить их в базовый режим.
echo(например с помощью Faststone Image Viewer.
echo(
echo(Перетащите папку или файлы на скрипт.
echo(Обрабатываются только .jpg и .jpeg.
echo(
pause
exit /b

:work
set "CMDN=%~n0"
set "CNTALL=0"
set "CNTP=0"
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto mode_folder

set "FLD=%~dp1"
pushd "%FLD%"
echo(Обработка списка JPG-файлов...
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
echo(Обработка папки "%~f1"...
echo(
rem Обработка файлов в папке (папок среди них быть уже не может - это фильтрует dir /a-d)
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
rem Не обрабатываем, если уже есть _PROGR
if /i not "%BASE:~-6%"=="_PROGR" goto no_progr
echo(%FN% - пропущен - _PROGR уже есть
echo(
exit /b
:no_progr

rem Проверяем SOF2 через exiv2
"%EX%" -pS "%FN%" | find "SOF2" >nul
if %ERRORLEVEL% NEQ 0 exit /b

rem Пробуем базовое имя + _PROGR
set "NEWNAME=%BASE%_PROGR%EXT%"
if not exist "%NEWNAME%" goto do_rename

rem Проверка конфликта имён
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
echo(--- Готово ---
if %CNTALL% GTR 0 set "TXT_ALL=Обработано JPG: %CNTALL%"
if %CNTP% GTR 0 set "TXT_PROGR=Помечено как PROGR: %CNTP%"
if %CNTALL% GTR 0 echo(%TXT_ALL%
if %CNTP% GTR 0 echo(%TXT_PROGR%
set "HF=%temp%\%CMDN%-hlp-%random%%random%.txt"
set "VB=%temp%\%CMDN%-hlp-%random%%random%.vbs"
>"%HF%" echo(%VRS%
>>"%HF%" echo(%CMDN% закончил работу.
>>"%HF%" echo(
>>"%HF%" echo(%TXT_ALL%
>>"%HF%" echo(%TXT_PROGR%
>"%VB%" echo(With CreateObject("ADODB.Stream"):.Type=2:.Charset="cp866"
>>"%VB%" echo(.Open:.LoadFromFile"%HF%":MsgBox .ReadText,,"%CMDN%":.Close:End With
cscript //nologo "%VB%"
del "%VB%" & del "%HF%"
pause