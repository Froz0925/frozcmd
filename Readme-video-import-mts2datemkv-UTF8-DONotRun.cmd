@echo off
set "DSTFLD=D:\Фотки\!разбирать\Видео"

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
    echo(%EX% не найден, выходим.
    echo(
    pause
    exit /b
)

:: Автоопределение съёмного носителя (DriveType=1 + Ready=True)
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
    echo(Не найден съёмный носитель с папкой %FLD%
    echo(
    pause
    goto help
)
if not exist "%USBDIR%\*%IN%" (
    echo(В %USBDIR% нет файлов %IN%, выходим.
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
set "EMSG=Все файлы обработаны. Проверьте корректность конвертации и удалите файлы %IN%."
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
>>"%HF%" echo Перенос .mts с фотоаппарата и ремукс в .mkv.
>>"%HF%" echo(
>>"%HF%" echo Подготовка:
>>"%HF%" echo 1. Открыть скрипт текстовым редактором с поддержкой кодовой страницы
>>"%HF%" echo    OEM866, например Far Manager, Total Commander, Notepad++
>>"%HF%" echo 2. Уточнить путь назначения DSTFLD: %DSTFLD%
>>"%HF%" echo(
>>"%HF%" echo Что делает:
>>"%HF%" echo 1. Ищет съёмный носитель с папкой %FLD%
>>"%HF%" echo 2. Переносит .mts в
>>"%HF%" echo    %DSTFLD%
>>"%HF%" echo 3. Переименовывает по маске ГГГГ-ММ-ДД_ЧЧММСС_имя.
>>"%HF%" echo 4. Удаляет папку %FLD2DEL% с носителя,
>>"%HF%" echo    чтобы на фотоаппарате не было ошибок просмотра "файл не найден".
>>"%HF%" echo 5. Ремуксит .mts в .mkv.
>"%VB%" echo(With CreateObject("ADODB.Stream"):.Type=2:.Charset="cp866"
>>"%VB%" echo(.Open:.LoadFromFile"%HF%":MsgBox .ReadText,,"%~n0":.Close:End With
cscript //nologo "%VB%"
del "%VB%" & del "%HF%"
exit /b
:: === Окончание основного кода ===


:: === Подпрограммы ===
:chkusb
if exist "%DL%\%FLD%" (
    set "USBDIR=%DL%\%FLD%"
    set "UD2DEL=%DL%\%FLD2DEL%"
)
exit /b

:go
:: Извлекаем DateLastModified
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
:: Коррекция однозначного часа (например, "8:08:08")
if not "%HH%"=="%HH::=%" (
    set "HH=0%HH:~0,1%"
    set "MM=%DT:~13,2%"
    set "SS=%DT:~16,2%"
)
set "DSTNAMEIN=%Y%-%M%-%D%_%HH%%MM%%SS%_%FNX%"
set "DSTNAME=%Y%-%M%-%D%_%HH%%MM%%SS%_%FN%%OUT%"
echo(Конвертация: "%FNX%" -^> "%DSTNAME%"...
if not exist "%DSTFLD%" md "%DSTFLD%"
move "%FNF%" "%DSTFLD%\%DSTNAMEIN%" >nul
"%EX%" -hide_banner -i "%DSTFLD%\%DSTNAMEIN%" -c copy "%DSTFLD%\%DSTNAME%"
echo(
exit /b
