@echo off
set "CMDN=%~n0"
:: ----------------------------------------------------
:: Папка для скачивания:
set "OUTD=%USERPROFILE%\Downloads\Froz-%CMDN%"
:: ----------------------------------------------------

set "DO=Video Downloader"
set "VRS=Froz %DO% v03.09.2025"
set "SERV=RuTube, VK Video, Dzen, OK, Boosty, YouTube"
set "ERRC=Некорректный номер, вводим заново."
set "ERRL=Неверная ссылка, вводим заново."
set "VDL=%~dp0bin\yt-dlp.exe"
if not exist "%VDL%" echo(Не найден %VDL%, выходим.& echo(& pause & exit /b
set "FFM=%~dp0bin\FFMpeg.exe"
if not exist "%FFM%" echo(Не найден %FFM%, выходим.& echo(& pause & exit /b
title %DO%
echo(%VRS%
echo(
echo(Скачивание видео и аудиофайлов из
echo(%SERV%
echo(в %OUTD%\
echo(
echo(Форматы контейнеров при выборе дорожек:
echo(AVC1+AAC = MP4+M4A, AVC1+OPUS = MKV+OPUS, AV01+AAC = MP4+M4A, AV01+OPUS = WEBM+OPUS
echo(

:inp
set "LNKF="
set /p "LNKF=Вставьте https-ссылку, Enter - выход: "
if "%LNKF%"=="" echo(Выходим.& exit /b
:: Обрезаем по &
for /f "delims=&" %%n in ("%LNKF%") do set "LNK=%%n"
:: Начинается ли с https://
set "LNKC=%LNK:~0,8%"
if /i not "%LNKC%"=="https://" echo(%ERRL%& goto inp

:get
:: Проверяем обновления
"%VDL%" -U
:waitloop
set "VDLN=%~dp0bin\yt-dlp.exe.new"
:: Ждём исчезновения файла .new - это сигнал, что yt-dlp обновился
if exist "%VDLN%" (
  ping 127.0.0.1 -n 1>nul
  goto waitloop
)
"%VDL%" -F "%LNK%"|more
:: Видеохостинг: если удаление подстроки вроде "youtu" меняет ссылку, значит она там была - переходим в нужный блок
if not "%LNK%"=="%LNK:youtu=%" goto yu-in
if not "%LNK%"=="%LNK:rutu=%" goto ru-in
if not "%LNK%"=="%LNK:vkvideo=%" goto vk-in
if not "%LNK%"=="%LNK:vk.com=%" goto vk-in
if not "%LNK%"=="%LNK:dzen=%" goto dz-in
if not "%LNK%"=="%LNK:ok.ru=%" goto ok-in
if not "%LNK%"=="%LNK:boosty=%" goto bo-in
echo(Видеохостинг не определён, выходим.& pause & exit /b


:yu-in
set "VID="
set /p "VID=YouTube: введите номер видео, r - повтор списка, Enter - выход: "
if "%VID%"=="" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
:: Проверка что введены только цифры
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& goto yu-in
if /i %VID% LSS 100 set "FMT=%VID%" & goto dl
if /i %VID% GTR 100 goto yu-aud

:yu-aud
set "AUD="
echo(Введите номер аудиодорожки: 1 - AAC 128k (совместимее), 2 - OPUS 128k (качественнее), Enter - выход: 
:yi
set /p "AUD=Ввод: "
if "%AUD%"=="" echo(Выходим.& exit /b
if "%AUD%"=="1" set "FMT=%VID%+140" & goto dl
if "%AUD%"=="2" set "FMT=%VID%+251" & goto dl
echo(%ERRC%& goto yi


:ru-in
set "VID="
echo(RuTube: введите номер видео XXX из default-XXX-0, r - повтор списка дорожек, Enter - выход.
set /p "VID=Ввод: "
if "%VID%"=="" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
:: Проверка что введены только цифры
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& echo(& goto ru-in
if /i %VID% GEQ 100 set "FMT=default-%VID%-0" & goto dl


:vk-in
set "VID="
echo(VK Video: введите номер видео XXX из urlXXX, или 1-8 из dash_sep-X если нужен отдельный аудиофайл, r - повтор списка, Enter - выход.
:vi
set /p "VID=Ввод: "
if "%VID%"=="" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& goto vi
if /i %VID% LSS 11 goto vk-aud
if /i %VID% GEQ 100 set "FMT=url%VID%" & goto dl

:vk-aud
set "AUD="
set /p "AUD=Введите номер аудиодорожки X из dash_sep-X audio only, q - выход: "
if "%AUD%"=="" echo(Выходим.& exit /b
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& goto vk-aud
if /i %VID% LSS 10 set "FMT=dash_sep-%VID%+dash_sep-%AUD%" & goto dl


:dz-in
set "VID="
echo(Dzen: введите номер видео XXX из XXX-0. Dash-варианты не имеют смысла т.к. аудио только одно, 
echo(r - повтор списка дорожек, Enter - выход.
:di
set /p "VID=Ввод: "
if "%VID%"=="" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& goto di
if /i %VID% GEQ 100 set "FMT=%VID%-0" & goto dl


:ok-in
set "VID="
set /p "VID=OK.ru: Введите код видео, r - повтор списка, Enter - выход: "
if "%VID%"=="" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
set "FMT=%VID%" & goto dl


:bo-in
set "VID="
echo(Boosty: введите код видео из нижнего списка "tiny-ultra_hd", r - повтор списка дорожек, Enter - выход.
set /p "VID=Ввод: "
if "%VID%"=="" echo(Выходим.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
set "FMT=%VID%" & goto dl


:dl
echo(Скачиваем...
if not exist "%OUTD%" md "%OUTD%">nul
:: Ключ -k убирать нельзя, так как при раздельном указании видео и аудиодорожек yt-dlp через ключ -x извлекает аудиодорожку в отдельный файл,
:: и кроме временных DASH-файлов он удаляет и сам видеофайл считая его тоже временным
"%VDL%" ^
    -f %FMT% --console-title -w -x -k --write-subs --sub-langs ru --convert-subtitles srt ^
    --windows-filenames -o "%OUTD%\%%(upload_date>%%Y-%%m-%%d)s_%%(title)s_%%(id)s.%%(ext)s" ^
    "%LNK%"
:: Удаляем DASH-фрагменты вручную: yt-dlp при -x удаляет и видео, поэтому используем -k и чистим сами
set "VATMP=%OUTD%\*.f*.*"
if exist "%VATMP%" del "%VATMP%"
start "" "%OUTD%"
chcp 866 >nul
set "EV=%temp%\%CMDN%-%random%%random%.vbs"
set "EMSG=Готово - см. %OUTD%"
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"