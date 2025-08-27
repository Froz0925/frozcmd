@echo off
:: FMTS: список поддерживаемых расширений. Обязательны пробелы по краям и между, и точки.
:: EOUT: выходное расширение - без точки.
set "FMTS= .aac "
set "EOUT=m4a"

set "DO=AAC mux to M4A"
title %DO%
set "VRS=Froz %DO% v27.08.2025"
echo(%VRS%
echo(
set "CMDN=%~n0"
set "EX=%~dp0bin\ffmpeg.exe"
if not exist "%EX%" echo("%EX%" не найден, выходим.& echo(& pause & exit /b
if "%~1"=="" (
    echo(Поддерживаемые форматы:%FMTS%
    echo(Перетащите на скрипт файлы или одну папку.
    echo(
    pause
    exit /b
)
:: Проверка длины аргументов: лимит Windows 8191 символ - путь может быть обрезан, а остальные утеряны
:: CMD ломается при передаче &)( в %* - используем VBS
:: Нельзя удалять проверку "%~1"=="" - VBS не сможет посчитать длину
set "TV=%temp%\%CMDN%_len_%random%%random%.vbs"
set "TO=%temp%\%CMDN%_out_%random%%random%.txt"
>"%TV%" echo(Set a=WScript.Arguments.Unnamed:ReDim b(a.Count-1)
>>"%TV%" echo(For i=0To a.Count-1:b(i)=a(i):Next
>>"%TV%" echo(WScript.Echo Len(Join(b," "))
cscript //nologo "%TV%" %* >"%TO%"
set "ALEN=0"
set /p "ALEN=" <"%TO%"
del "%TV%" & del "%TO%"
if %ALEN% gtr 7500 (
    echo(ВНИМАНИЕ: слишком длинная команда.
    echo(Общая длина путей к файлам больше 7500 символов - возможна потеря данных.
    echo(Ограничение Windows - 8191 символ, остальное будет обрезано.
    echo(
    echo(Перетащите папку вместо отдельных файлов, или подавайте частями. Выходим.
    echo(
    pause
    exit /b
)
:: Флаг: был ли обработан хотя бы один файл - для сообщения о пустом результате.
set FOUND=
:: Проверяем первый аргумент - папка или файл
set "ATR=%~a1"
if /I "%ATR:~0,1%"=="d" goto folder
echo(Обработка файлов...
echo(
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
echo(
:: Используем pushd+popd, а не cd /d на случай обработки файлов в сетевых папках \\server\share\file.ext
pushd "%~f1"
for /f "delims=" %%F in ('dir /b /a-d') do (
    set "FNF=%%~fF"
    set "FN=%%~nF"
    set "EXT=%%~xF"
    set "OUTF=%%~nF.%EOUT%"
    call :go
)
popd
echo(
echo(Папка "%~n1" обработана.
goto e

:go
if not exist "%FNF%" goto skip
if /i "%EXT%"=="" goto skip
echo(%FMTS% | findstr /i /c:" %EXT% " >nul
if errorlevel 1 goto skip
if /i "%EXT%"==".%EOUT%" goto skip
if exist "%OUTF%" goto skip
echo(Конвертируем: "%FN%%EXT%" -^> "%FN%.%EOUT%"
"%EX%" -hide_banner -i "%FNF%" -c copy "%OUTF%"
echo(
set "FOUND=1"
exit /b
:skip
echo("%FN%%EXT%" - пропущен (неподдерживаемый или уже обработан)
echo(
exit /b


:e
if not defined FOUND echo(Нет файлов поддерживаемых форматов.
set "EV=%temp%\%CMDN%-end-%random%%random%.vbs"
set "EMSG=Все файлы обработаны."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
pause