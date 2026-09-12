@echo off
set "DSTFLD=D:\Фотки\!разбирать\Видео"

set "DO=Import .MTS to .MKV"
title Froz %DO%
set "VRS=Froz %DO% v20.07.2026"
echo(%VRS%
echo(
set "IN=.mts"
set "OUT=.mkv"
set "FLD=PRIVATE\AVCHD\BDMV\STREAM"
set "FLD2DEL=PRIVATE"
set "EX=%~dp0bin\ffmpeg.exe"
if not exist "%EX%" echo(%EX% не найден, выходим.& echo(& pause & exit /b
set "CMDN=%~n0"

rem Поиск съёмного носителя (DriveType=1 + IsReady). Выводит подходящие буквы дисков по одной на строку.
set "DLV=%temp%\%CMDN%-USBDIR.vbs"
>"%DLV%"  echo(With CreateObject("Scripting.FileSystemObject"):For Each D In .Drives
>>"%DLV%" echo(If D.DriveType=1 And D.IsReady Then Wscript.Echo D.DriveLetter
>>"%DLV%" echo(Next:End With

rem Ищем первый диск с папкой %FLD%. Чтобы не делать ещё один if внутри if - используем call.
rem В cmd нельзя выйти из for (...) досрочно - goto запрещён, 
rem поэтому используем if not defined - обработается первое найденное совпадение.
rem а затем for "вхолостую докрутит" все оставшиеся буквы дисков без вызова call.
rem Двойная вложенность тут неизбежна: это минимально возможная структура.
rem Обнуляем на всякий случай UD2DEL чтобы в случае ошибки в rd не попало неверное значение
set "UD2DEL="
set "USBDIR="
for /f "delims=" %%D in ('cscript //nologo "%DLV%"') do (
    if not defined USBDIR (
        set "DL=%%D:"
        call :chkusb
    )
)
del "%DLV%"

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

rem Создаём один раз VBS-код для запроса DLM в отдельные переменные, способом не зависящим от локали
rem Формат выдачи VBS - ГГГГ-ММ-ДД_ЧЧММСС
set "DLMV=%temp%\%CMDN%-DLM.vbs"
>"%DLMV%"  echo(With CreateObject("Scripting.FileSystemObject")
>>"%DLMV%" echo(Set f=.GetFile(WScript.Arguments.Item(0)):dt=f.DateLastModified
>>"%DLMV%" echo(Y=Year(dt):M=Right("0"^&Month(dt),2):D=Right("0"^&Day(dt),2)
>>"%DLMV%" echo(H=Right("0"^&Hour(dt),2):N=Right("0"^&Minute(dt),2):S=Right("0"^&Second(dt),2)
>>"%DLMV%" echo(WScript.Echo Y^&"-"^&M^&"-"^&D^&"_"^&H^&""^&N^&""^&S:End With

for %%F in ("%USBDIR%\*%IN%") do (
    set "FN=%%~nF"
    set "FNX=%%~nxF"
    set "FNF=%%~fF"
    call :go
)

rem Удаляем VBS DLM
del "%DLMV%"

rem Удаляем папку PRIVATE с носителя, чтобы затем на фотокамере не было ошибок типа "файл поврежден"
rem из-за отсутствующих видеофайлов MTS. В стандарте BDMV индексные файлы: *.bdmv, *.clpi, *.cpi.
rd /s /q "%UD2DEL%"

rem Выводим сообщение
set "EV=%temp%\%CMDN%-MSG.vbs"
set "EMSG=Все файлы обработаны. Проверьте корректность конвертации и удалите файлы %IN%."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
pause
exit /b

:help
set "HF=%temp%\%CMDN%-hlp-%random%%random%.txt"
set "VB=%temp%\%CMDN%-hlp-%random%%random%.vbs"
>"%HF%"  echo(%VRS%
>>"%HF%" echo(
>>"%HF%" echo(Перенос видеофайлов .mts с фотокамер
>>"%HF%" echo(с файловой структурой стандарта BDMV-AVCHD,
>>"%HF%" echo(например Panasonic, Sony.
>>"%HF%" echo(Подготовка:
>>"%HF%" echo(1. Открыть скрипт в редакторе с поддержкой OEM866,
>>"%HF%" echo(   например Блокнот со шрифтом Terminal, Far Manager
>>"%HF%" echo(   Total Commander, Notepad++.
>>"%HF%" echo(2. Уточнить путь извлечения видеофайлов:
>>"%HF%" echo(   %DSTFLD%
>>"%HF%" echo(
>>"%HF%" echo(Что делает скрипт:
>>"%HF%" echo(1. Ищет съёмный носитель с папкой
>>"%HF%" echo(   %FLD%
>>"%HF%" echo(2. Переносит .mts в
>>"%HF%" echo(   %DSTFLD%
>>"%HF%" echo(3. Переименовывает файлы по маске ГГГГ-ММ-ДД_ЧЧММСС_имя.
>>"%HF%" echo(4. Ремуксит .mts в .mkv ^(без перекодировки^)
>>"%HF%" echo(   для совместимости с проигрывателями.
>>"%HF%" echo(5. Удаляет папку %FLD2DEL% с носителя,
>>"%HF%" echo(   чтобы на фотокамере при просмотре не было ошибок
>>"%HF%" echo(   "файл не найден" или "файл поврежден".
>"%VB%" echo(With CreateObject("ADODB.Stream"):.Type=2:.Charset="cp866"
>>"%VB%" echo(.Open:.LoadFromFile"%HF%":MsgBox .ReadText,,"%CMDN%":.Close:End With
cscript //nologo "%VB%"
del "%VB%" & del "%HF%"
exit /b
rem === Окончание основного кода ===


rem === Подпрограммы ===
:chkusb
if exist "%DL%\%FLD%" (
    set "USBDIR=%DL%\%FLD%"
    set "UD2DEL=%DL%\%FLD2DEL%"
)
exit /b

:go
rem Извлекаем дату последнего изменения файла (DateLastModified) способом не зависящим от локали ОС:
for /f "delims=" %%a in ('cscript //nologo "%DLMV%" "%FNF%"') do set "DLM=%%a"
echo(Конвертация: "%FNX%" -^> "%DLM%_%FN%%OUT%"...
if not exist "%DSTFLD%" md "%DSTFLD%"
move "%FNF%" "%DSTFLD%\%DLM%_%FNX%" >nul
"%EX%" -hide_banner -i "%DSTFLD%\%DLM%_%FNX%" -map 0 -c copy -metadata:s:s:0 language=rus "%DSTFLD%\%DLM%_%FN%%OUT%"
echo(
exit /b