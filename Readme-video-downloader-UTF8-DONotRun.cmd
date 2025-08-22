@echo off
set "DO=Video Downloader"
set "VRS=Froz %DO% v21.08.2025"

:: Список видеохостингов для Help и Title:
set "SERV=RuTube, VK Video, Dzen, OK, Boosty, YouTube (пока не работает)."
set "ERRC=Некорректный номер, вводим заново."
set "ERRL=Неверная ссылка, вводим заново."

:: Папка для скачивания:
set "OUTD=%USERPROFILE%\Downloads\Froz_%~n0"


:: Проверяем наличие утилит:
set "VDL=%~dp0bin\yt-dlp.exe"
set "VDLN=%~dp0bin\yt-dlp.exe.new"
if not exist "%VDL%" echo(Не найден %VDL%, выходим.& echo(& pause & exit /b
set "FFM=%~dp0bin\FFMpeg.exe"
if not exist "%FFM%" echo(Не найден %FFM%, выходим.& echo(& pause & exit /b

:: Intro:
title %DO%
echo(%VRS%
echo(
echo(Скачивание видео и аудиофайлов из
echo(%SERV%
echo(в %OUTD%\
echo(

:inp
:: Ввод ссылки:
echo(
set /p "LNKF=Вставьте https-ссылку, q - выход: "
for /f "tokens=1 delims=?" %%n in ("%LNKF%") do set "LNK=%%n"
if "%LNK%"=="" (
    echo(%ERRL%
    goto inp
)
if "%LNK%"=="q" echo(Выходим.& exit /b
if not "%LNK%"=="%LNK:https://=%" goto get
echo(%ERRL%
goto inp

:get
:: Проверяем обновления:
"%VDL%" -U
:waitclose
if exist "%VDLN%" (
  ping 127.0.0.1 -n 1>nul
  goto waitclose
)
:: Извлекаем название видеохостинга:
"%VDL%" -F "%LNKF%"|more
if not "%LNK%"=="%LNK:youtu=%" goto yu-in
if not "%LNK%"=="%LNK:rutu=%" goto ru-in
if not "%LNK%"=="%LNK:vkvideo=%" goto vk-in
if not "%LNK%"=="%LNK:vk.com=%" goto vk-in
if not "%LNK%"=="%LNK:dzen=%" goto dz-in
if not "%LNK%"=="%LNK:ok.ru=%" goto ok-in
if not "%LNK%"=="%LNK:boosty=%" goto bo-in
echo(Видеохостинг не определён, выходим.& pause & exit /b



:yu-in
set /p "VID=YouTube: введите номер видео, r - повтор списка, q - выход: "
if "%VID%"=="" (
    echo(%ERRC%
    goto yu-in
)
if "%VID%"=="q" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNKF%"|more
if /i %VID% LSS 100 set "FMT=%VID%" & goto dl
if /i %VID% GTR 100 goto yu-aud
echo(%ERRC%
goto yu-in

:yu-aud
set /p "AUD=Введите номер аудиодорожки: 1 - AAC 128k, 2 - OPUS 128k, q - выход: "
if "%AUD%"=="" (
    echo(%ERRC%
    goto yu-aud
)
if "%AUD%"=="q" echo(Выходим.& exit /b
if "%AUD%"=="1" set "FMT=%VID%+140"& goto dl
if "%AUD%"=="2" set "FMT=%VID%+251"& goto dl
echo(%ERRC%
goto yu-aud



:ru-in
echo(RuTube: введите номер видео XXX из default-XXX-0, r - повтор списка дорожек, q - выход.
set /p "VID=Ввод: "
if "%VID%"=="" (
    echo(%ERRC%
    goto ru-in
)
if "%VID%"=="q" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
set "FMT=default-%VID%-0"
goto dl



:vk-in
echo(VK Video: введите номер видео XXX из urlXXX, или 1-8 для dash_sep-X (если нужна отдельная аудиодорожка)
echo(r - повтор списка, q - выход.
set /p "VID=Ввод: "
if "%VID%"=="" (
    echo(%ERRC%
    goto vk-in
)
if "%VID%"=="q" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
if /i %VID% LSS 11 goto vk-aud
set "FMT=url%VID%"
goto dl

:vk-aud
set /p "AUD=Введите номер аудиодорожки XX из dash_sep-XX audio only, q - выход: "
if "%AUD%"=="" (
    echo(%ERRC%
    goto vk-aud
)
if "%AUD%"=="q" echo(Выходим.& exit /b
set "FMT=dash_sep-%VID%+dash_sep-%AUD%"
goto dl



:dz-in
echo(Dzen: введите номер видео XXX из XXX-0. Dash-варианты не имеют смысла т.к. аудио только одно, 
echo(r - повтор списка дорожек, q - выход.
set /p "VID=Ввод: "
if "%VID%"=="" (
    echo(%ERRC%
    goto dz-in
)
if "%VID%"=="q" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
set "FMT=%VID%-0"
goto dl


:ok-in
set /p "VID=OK.ru: Введите код видео, r - повтор списка, q - выход: "
if "%VID%"=="" (
    echo(%ERRC%
    goto ok-in
)
if "%VID%"=="q" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
set "FMT=%VID%"
goto dl



:bo-in
echo(Boosty: введите код видео из нижнего списка "tiny-ultra_hd", r - повтор списка дорожек, q - выход.
set /p "VID=Ввод: "
if "%VID%"=="" (
    echo(%ERRC%
    goto bo-in
)
if "%VID%"=="q" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
set "FMT=%VID%"
goto dl



:dl
echo(Скачиваем...
if not exist "%OUTD%" md "%OUTD%">nul
"%VDL%" %LNKF% -f %FMT% -o "%OUTD%\%%(upload_date>%%Y-%%m-%%d)s_%%(title)s_%%(id)s.%%(ext)s" --console-title -w -x -k --write-subs --sub-langs ru --convert-subtitles srt
start "" "%OUTD%"



:done
chcp 866 >nul
set "EV=%temp%\$%~n0$.vbs"
set "EMSG=Готово."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%~nx0"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"