@echo off
:: В начале и конце FMTS - обязательно пробелы
set "FMTS= .wav "
set "EOUT=opus"
set "QUAL=128"

set "DO=All%FMTS%to .%EOUT%"
title %DO%
set "VRS=Froz %DO% v15.08.2025"
echo(%VRS%
echo.

set "EX=%~dp0bin\opusenc.exe"
if not exist "%EX%" (
    echo(%EX% не найден, выходим.
    echo.
    pause
    exit /b
)
if "%~1"=="" (
    echo Поддерживаемые форматы:%FMTS%
    echo Перетащите на скрипт файлы или одну папку.
    echo.
    pause
    exit /b
)
:: Проверка длины аргументов CMD через VBS
:: так как в CMD нет безопасного способа парсить строку с &)(
set "TV=%temp%\%~nx0_len_%random%.vbs"
set "TO=%temp%\%~nx0_out_%random%.txt"
:: Подсчёт длины всех аргументов с пробелами - для проверки лимита CMD (8191)
:: Массив + Join, т.к. WScript.Arguments не совместим с Join напрямую
:: Проверка на "%~1"=="" выше гарантирует a.Count >= 1 , значит ReDim безопасен
echo Set a=WScript.Arguments.Unnamed:ReDim b(a.Count-1)>"%TV%"
echo For i=0To a.Count-1:b(i)=a(i):Next>>"%TV%"
echo WScript.Echo Len(Join(b," "))>>"%TV%"
cscript //nologo "%TV%" %* >"%TO%"
set "ALEN=0"
set /p "ALEN=" <"%TO%"
del "%TV%" & del "%TO%"
if %ALEN% gtr 7500 (
    echo ВНИМАНИЕ: слишком длинная команда.
    echo Общая длина путей к файлам больше 7500 символов - возможна потеря данных.
    echo Ограничение Windows - 8191 символ, остальное будет обрезано.
    echo.
    echo Перетащите папку вместо отдельных файлов, или подавайте частями. Выходим.
    echo.
    pause
    exit /b
)
:: Флаг: был ли обработан хотя бы один файл - для сообщения о пустом результате.
set FOUND=
:: Проверяем первый аргумент - папка или файл
set "ATR=%~a1"
if /I "%ATR:~0,1%"=="d" goto folder
echo Обработка файлов...
echo.
:loop
if "%~1"=="" goto e
set "FNF=%~f1"
set "FN=%~n1"
set "EXT=%~x1"
set "OUTF=%~dp1%~n1.%EOUT%"
call :go
shift
goto loop

:folder
echo(Обработка папки "%~n1"
echo.
cd /d "%~f1"
for /f "delims=" %%F in ('dir /b /a-d 2^>nul') do (
    set "FNF=%%~fF"
    set "FN=%%~nF"
    set "EXT=%%~xF"
    set "OUTF=%%~nF.%EOUT%"
    call :go
)
echo.
echo Папка "%~n1" обработана.
goto e

:go
if not exist "%FNF%" goto skip
if /i "%EXT%"=="" goto skip
echo %FMTS% | findstr /i /c:" %EXT% " >nul
if errorlevel 1 goto skip
if /i "%EXT%"==".%EOUT%" goto skip
if exist "%OUTF%" goto skip
echo(Конвертируем: "%FN%%EXT%" -^> "%FN%.%EOUT%"
"%EX%" --bitrate 128 "%FNF%" "%OUTF%"
echo.
set "FOUND=1"
exit /b
:skip
echo("%FN%%EXT%" - пропущен (неподдерживаемый или уже обработан)
echo.
exit /b


:e
if not defined FOUND echo Нет файлов поддерживаемых форматов.
set "EV=%temp%\%~nx0-end-%random%.vbs"
set "EMSG=Все файлы обработаны."
chcp 1251 >nul
echo MsgBox "%EMSG%",,"%~nx0">"%EV%"
chcp 866 >nul
"%EV%" & del "%EV%"
pause